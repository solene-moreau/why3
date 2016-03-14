(********************************************************************)
(*                                                                  *)
(*  The Why3 Verification Platform   /   The Why3 Development Team  *)
(*  Copyright 2010-2015   --   INRIA - CNRS - Paris-Sud University  *)
(*                                                                  *)
(*  This software is distributed under the terms of the GNU Lesser  *)
(*  General Public License version 2.1, with the special exception  *)
(*  on linking described in file LICENSE.                           *)
(*                                                                  *)
(********************************************************************)

open Ident
open Ty
open Term
open Decl

type split = {
  right_only : bool;
  byso_split : bool;
  side_split : bool;
  stop_split : bool;
  asym_split : bool;
  comp_match : known_map option;
}

let stop f = Slab.mem Term.stop_split f.t_label
let asym f = Slab.mem Term.asym_split f.t_label

let case_split = Ident.create_label "case_split"
let case f = Slab.mem case_split f.t_label

let compiled = Ident.create_label "split_goal: compiled match"

let unstop f =
  t_label ?loc:f.t_loc (Slab.remove stop_split f.t_label) f

(* Represent monoid of formula interpretation for conjonction and disjunction *)
module M = struct

  (* Multiplication tree *)
  type comb = Base of term | Op of comb * comb

  (* zero: false for /\, true for \/
     unit: true for /\, false for \/ *)
  type monoid = Zero of term | Unit | Comb of comb

  (* inject formula into monoid. *)
  let (!+) a = Comb (Base a)

  (* monoid law. *)
  let (++) a b =
    match a, b with
    | _, Unit | Zero _, _ -> a
    | Unit, _ | _, Zero _ -> b
    | Comb ca, Comb cb -> Comb (Op (ca, cb))

  (* (base -> base) morphism application. *)
  let rec cmap f = function
    | Base a -> Base (f a)
    | Op (a,b) -> Op (cmap f a, cmap f b)

  (* (base -> general) morphism application *)
  let rec cbind f = function
    | Base a -> f a
    | Op (a,b) -> Op (cbind f a, cbind f b)

  (* Apply morphism phi from monoid 1 to monoid 2
     (law may change)
     Implicit morphism phi must respect:
     phi(zero_1) = f0 (term representing the zero)
     phi(unit_1) = unit_2
     phi(x `law_1` y) = phi(x) `law_2` phi(y)
     phi(a) = f a (for base values, and f a is a base value)
     Intended: monotone context closure, negation *)
  let map f0 f = function
    | Zero t -> f0 t
    | Unit -> Unit
    | Comb c -> Comb (cmap f c)

  (* Apply bimorphism phi from monoids 1 and 2 to monoid 3
     Implicit bimorphism phi must respect:
     - partial applications of phi (phi(a,_) and phi(_,b)) are morphisms
     - phi(zero,b) = f0_ 'term for zero' b (for b a base value,
                                            f0_ _ b is a base value)
     - phi(a,zero) = f_0 'term for zero' a (for a a base value,
                                            f_0 a _ is a base value)
     - phi(zero,zero) = f00 'term for first zero' 'term for second zero'
     - phi(a,b) = f a b (for a,b base value, and f a b is a base value)
     Intended: mainly /\, \/ and ->
   *)
  let bimap f00 f0_ f_0 f a b = match a, b with
    | Unit, _ | _, Unit -> Unit
    | Zero t1, Zero t2 -> f00 t1 t2
    | Zero t1, Comb cb ->  Comb (cmap (f0_ t1) cb)
    | Comb ca, Zero t2 -> Comb (cmap (f_0 t2) ca)
    | Comb ca, Comb cb -> Comb (cbind (fun x -> cmap (f x) cb) ca)

  let rec to_list m acc = match m with
    | Base a -> a :: acc
    | Op (a,b) -> to_list a (to_list b acc)

  let to_list = function
    | Zero t -> [t]
    | Unit -> []
    | Comb c -> to_list c []

end

type split_ret = {
  pos : M.monoid;
  neg : M.monoid;
  bwd : term;
  fwd : term;
  side : M.monoid;
}

let rec drop_byso f = match f.t_node with
  | Tbinop (Timplies,{ t_node = Tbinop (Tor,_,{ t_node = Ttrue }) },f) ->
      drop_byso f
  | Tbinop (Tand,f,{ t_node = Tbinop (Tor,_,{ t_node = Ttrue }) }) ->
      drop_byso f
  | _ -> t_map drop_byso f


open M

let pat_condition kn tv cseen p =
  match p.pat_node with
  | Pwild ->
      let csl,sbs = match p.pat_ty.ty_node with
        | Tyapp (ts,_) ->
            Decl.find_constructors kn ts,
            let ty = ty_app ts (List.map ty_var ts.ts_args) in
            ty_match Mtv.empty ty p.pat_ty
        | _ -> assert false in
      let csall = Sls.of_list (List.rev_map fst csl) in
      let csnew = Sls.diff csall cseen in
      assert (not (Sls.is_empty csnew));
      let add_cs cs g =
        let mk_v ty = create_vsymbol (id_fresh "w") (ty_inst sbs ty) in
        let vl = List.map mk_v cs.ls_args in
        let f = t_equ tv (fs_app cs (List.map t_var vl) p.pat_ty) in
        g ++ !+ (t_exists_close_simp vl [] f) in
      let g = Sls.fold add_cs csnew Unit in
      csall, [], g
  | Papp (cs, pl) ->
      let vl = List.map (function
        | {pat_node = Pvar v} -> v | _ -> assert false) pl in
      let g = t_equ tv (fs_app cs (List.map t_var vl) p.pat_ty) in
      Sls.add cs cseen, vl, !+g
  | _ -> assert false

let rec fold_cond = function
  | Base a -> a
  | Op (a,b) -> t_or (fold_cond a) (fold_cond b)

let fold_cond = function
  | Comb c -> !+ (fold_cond c)
  | x -> x

let rec split_core sp f =
  let rc = split_core sp in
  let (~-) = t_label_copy f in
  let ro = sp.right_only in
  let alias fo1 unop f1 = if fo1 == f1 then f else - unop f1 in
  let alias2 fo1 fo2 binop f1 f2 =
    if fo1 == f1 && fo2 == f2 then f else - binop f1 f2 in
  let case f1 fm1 sp1 = if not ro || case f1 then sp1 else !+fm1 in
  let ngt _ a = t_not a and cpy _ a = a in
  let bimap = bimap (fun _ t -> Zero t) cpy in
  let iclose = bimap ngt t_implies in
  let aclose = bimap cpy t_and in
  let nclose ps = map (fun t -> Zero (t_label_copy t t_true)) t_not ps in
  let ret pos neg bwd fwd side = { pos; neg; bwd; fwd; side } in
  let r = match f.t_node with
  | _ when sp.stop_split && stop f ->
      let df = drop_byso f in
      ret !+(unstop f) !+(unstop df) f df Unit
  | Ttrue -> ret Unit (Zero f) f f Unit
  | Tfalse -> ret (Zero f) Unit f f Unit
  | Tapp _ -> let uf = !+f in ret uf uf f f Unit
    (* f1 so f2 *)
  | Tbinop (Tand,f1,{ t_node = Tbinop (Tor,f2,{ t_node = Ttrue }) }) ->
      if not (sp.byso_split && asym f2) then rc f1 else
      let (&&&) f1 f2 = - t_and f1 f2 in
      let sf1 = rc f1 and sf2 = rc f2 in
      let fwd = sf1.fwd &&& sf2.fwd in
      let cf1 = case f1 sf1.fwd sf1.neg and cf2 = case f2 sf2.fwd sf2.neg in
      let neg = bimap cpy (&&&) cf1 cf2 in
      let close = iclose cf1 in
      let lside = if sp.side_split then close sf2.pos else
        !+(t_implies sf1.fwd sf2.bwd) in
      ret sf1.pos neg sf1.bwd fwd (sf1.side ++ lside ++ close sf2.side)
  | Tbinop (Tand,f1,f2) ->
      let (&&&) = alias2 f1 f2 t_and in
      let sf1 = rc f1 and sf2 = rc f2 in
      let fwd = sf1.fwd &&& sf2.fwd and bwd = sf1.bwd &&& sf2.bwd in
      let cf1 = case f1 sf1.fwd sf1.neg and cf2 = case f2 sf2.fwd sf2.neg in
      let neg = bimap cpy (&&&) cf1 cf2 in
      let close = if sp.asym_split && asym f1 then iclose cf1 else fun x -> x in
      ret (sf1.pos ++ close sf2.pos) neg bwd fwd (sf1.side ++ close sf2.side)
  (* f1 by f2 *)
  | Tbinop (Timplies,{ t_node = Tbinop (Tor,f2,{ t_node = Ttrue }) },f1) ->
      if not (sp.byso_split && asym f2) then rc f1 else
      let sf1 = rc f1 and sf2 = rc f2 in
      let close = iclose (case f2 sf2.fwd sf2.neg) in
      let lside = if sp.side_split then close sf1.pos else
        !+(t_implies sf2.fwd sf1.bwd) in
      ret sf2.pos sf1.neg sf2.bwd sf1.fwd (sf2.side ++ lside ++ close sf1.side)
  | Tbinop (Timplies,f1,f2) ->
      let (>->) = alias2 f1 f2 t_implies in
      let sf1 = rc f1 and sf2 = rc f2 in
      let fwd = sf1.bwd >-> sf2.fwd and bwd = sf1.fwd >-> sf2.bwd in
      let cf1 = case f1 sf1.fwd sf1.neg in
      let close = bimap (fun _ a -> - t_not a) (>->) cf1 in
      let neg1 = nclose sf1.pos in
      let neg2 = if not (sp.asym_split && asym f1) then sf2.neg else
        aclose cf1 sf2.neg in
      let neg = neg1 ++ neg2 in
      ret (close sf2.pos) neg bwd fwd (sf1.side ++ iclose cf1 sf2.side)
  | Tbinop (Tor,f1,f2) ->
      let (|||) = alias2 f1 f2 t_or in
      let sf1 = rc f1 and sf2 = rc f2 in
      let fwd = sf1.fwd ||| sf2.fwd and bwd = sf1.bwd ||| sf2.bwd in
      let cb1 = case f1 sf1.bwd sf1.pos and cb2 = case f2 sf2.bwd sf2.pos in
      let pos = bimap cpy (|||) cb1 cb2 in
      let side2, neg2 =
        if sp.asym_split && asym f1
        then bimap cpy (|||) cb1 sf2.side, aclose (nclose cb1) sf2.neg
        else sf2.side, sf2.neg
      in
      ret pos (sf1.neg ++ neg2) bwd fwd (sf1.side ++ side2)
  | Tbinop (Tiff,f1,f2) ->
      let sf1 = rc f1 and sf2 = rc f2 in
      let df = if sf1.fwd == sf1.bwd && sf2.fwd == sf2.bwd
        then alias2 f1 f2 t_iff sf1.fwd sf2.fwd else drop_byso f in
      let cf1 = case f1 sf1.fwd sf1.neg and cf2 = case f2 sf2.fwd sf2.neg in
      let cb1 = case f1 sf1.bwd sf1.pos and cb2 = case f2 sf2.bwd sf2.pos in
      let pos = iclose cf1 sf2.pos ++ iclose cf2 sf1.pos in
      let neg_top = aclose cf1 cf2 in
      let neg_bot = aclose (nclose cb1) (nclose cb2) in
      ret pos (neg_top ++ neg_bot) df df (sf1.side ++ sf2.side)
  | Tif (fif,fthen,felse) ->
      let sfi = rc fif and sft = rc fthen and sfe = rc felse in
      let dfi = if sfi.fwd == sfi.bwd then sfi.fwd else drop_byso fif in
      let rebuild fif2 fthen2 felse2 =
        if fif == fif2 && fthen == fthen2 && felse == felse2 then f else
        t_if fif2 fthen2 felse2
      in
      let fwd = rebuild dfi sft.fwd sfe.fwd in
      let bwd = rebuild dfi sft.bwd sfe.bwd in
      let cfi = case fif sfi.fwd sfi.neg in
      let cbi = case fif sfi.bwd sfi.pos in
      let ncbi = nclose cbi in
      let pos = iclose cfi sft.pos ++ iclose ncbi sfe.pos in
      let neg = aclose cfi sft.neg ++ aclose ncbi sfe.neg in
      let side = sfi.side ++ iclose cfi sft.side ++ iclose ncbi sfe.side in
      ret pos neg bwd fwd side
  | Tnot f1 ->
      let sf = rc f1 in
      let (!) = alias f1 t_not in
      let (|>) zero = map (fun t -> !+(t_label_copy t zero)) (!) in
      ret (t_false |> sf.neg) (t_true |> sf.pos) !(sf.fwd) !(sf.bwd) sf.side
  | Tlet (t,fb) ->
      let vs, f1 = t_open_bound fb in
      let (!) = alias f1 (t_let_close vs t) in
      let sf = rc f1 in
      let (!!) = map (fun t -> Zero t) (!) in
      ret !!(sf.pos) !!(sf.neg) !(sf.bwd) !(sf.fwd) !!(sf.side)
  | Tcase (t,bl) ->
      let k join =
        let case_close bl2 =
          if Lists.equal (==) bl bl2 then f else t_case t bl2 in
        let sbl = List.map (fun b ->
          let p, f, close = t_open_branch_cb b in
          p, close, split_core sp f) bl in
        let blfwd = List.map (fun (p, close, sf) -> close p sf.fwd) sbl in
        let fwd = case_close blfwd in
        let blbwd = List.map (fun (p, close, sf) -> close p sf.bwd) sbl in
        let bwd = case_close blbwd in
        let pos, neg, side = join sbl in
        ret pos neg bwd fwd side
      in
      begin match sp.comp_match with
      | None ->
          let join sbl =
            let rec zip_all bf_top bf_bot = function
              | [] -> Unit, Unit, Unit, [], []
              | (p, close, sf) :: q ->
                let c_top = close p t_true and c_bot = close p t_false in
                let dp_top = c_top :: bf_top and dp_bot = c_bot :: bf_bot in
                let pos, neg, side, af_top, af_bot = zip_all dp_top dp_bot q in
                let fzip bf af mid =
                  t_case t (List.rev_append bf (close p mid::af)) in
                let zip bf mid af =
                  map (fun t -> !+(fzip bf af t)) (fzip bf af) mid in
                zip bf_top sf.pos af_top ++ pos,
                zip bf_bot sf.neg af_bot ++ neg,
                zip bf_top sf.side af_top ++ side,
                c_top :: af_top,
                c_bot :: af_bot
            in
            let pos, neg, side, _, _ = zip_all [] [] sbl in
            pos, neg, side
          in
          k join
      | Some kn ->
          if Slab.mem compiled f.t_label
          then
            let lab = Slab.remove compiled f.t_label in
            let join sbl =
              let vs = create_vsymbol (id_fresh "q") (t_type t) in
              let tv = t_var vs in
              let (~-) fb =
                t_label ?loc:f.t_loc lab (t_let_close_simp vs t fb) in
              let _, pos, neg, side =
                List.fold_left (fun (cseen, pos, neg, side) (p, _, sf) ->
                  let cseen, vl, cond = pat_condition kn tv cseen p in
                  let cond = if ro then fold_cond cond else cond in
                  let fcl t = - t_forall_close_simp vl [] t in
                  let ecl t = - t_exists_close_simp vl [] t in
                  let ps cond f = fcl (t_implies cond f) in
                  let ng cond f = ecl (t_and cond f) in
                  let ngt _ a = fcl (t_not a) and tag _ a = ecl a in
                  let pos  = pos  ++ bimap ngt ps cond sf.pos  in
                  let neg  = neg  ++ bimap tag ng cond sf.neg  in
                  let side = side ++ bimap ngt ps cond sf.side in
                  cseen, pos, neg, side
                ) (Sls.empty, Unit, Unit, Unit) sbl
              in
              pos, neg, side
            in
            k join
          else
            let mk_let = t_let_close_simp in
            let mk_case t bl = t_label_add compiled (t_case_close t bl) in
            let mk_b b = let p, f = t_open_branch b in [p], f in
            let bl = List.map mk_b bl in
            let f = Pattern.compile_bare ~mk_case ~mk_let [t] bl in
            split_core sp f
      end
  | Tquant (qn,fq) ->
      let vsl, trl, f1 = t_open_quant fq in
      let close = alias f1 (t_quant_close qn vsl trl) in
      let sf = rc f1 in
      let bwd = close sf.bwd and fwd = close sf.fwd in
      let pos, neg = match qn with
        | Tforall -> map (fun t -> Zero t) close sf.pos, !+fwd
        | Texists -> !+bwd, map (fun t -> Zero t) close sf.neg
      in
      let side = map (fun t -> Zero t) (t_forall_close vsl trl) sf.side in
      ret pos neg bwd fwd side
  | Tvar _ | Tconst _ | Teps _ -> raise (FmlaExpected f)
  in
  match r with
  | { side = M.Zero _ as side } ->
      { pos = Unit; neg = Unit; fwd = t_false; bwd = t_true; side }
  | _ -> r


let full_split kn = {
  right_only = false;
  byso_split = false;
  side_split = true;
  stop_split = false;
  asym_split = true;
  comp_match = kn;
}

let right_split kn = { (full_split kn) with right_only = true }
let full_proof  kn = { (full_split kn) with stop_split = true;
                                            byso_split = true }
let right_proof kn = { (full_proof kn) with right_only = true }
let full_intro  kn = { (full_split kn) with asym_split = false;
                                            stop_split = true }
let right_intro kn = { (full_intro kn) with right_only = true }

let split_pos sp f =
  let core = split_core sp f in
  assert (core.side = Unit);
  to_list core.pos

let split_neg sp f =
  let core = split_core sp f in
  assert (core.side = Unit);
  to_list core.neg

let split_proof sp f =
  let core = split_core sp f in
  to_list (core.pos ++ core.side)

let split_pos_full  ?known_map f = split_pos (full_split known_map)  f
let split_pos_right ?known_map f = split_pos (right_split known_map) f

let split_neg_full  ?known_map f = split_neg (full_split known_map)  f
let split_neg_right ?known_map f = split_neg (right_split known_map) f

let split_proof_full  ?known_map f = split_proof (full_proof known_map)  f
let split_proof_right ?known_map f = split_proof (right_proof known_map) f

let split_intro_full  ?known_map f = split_pos (full_intro known_map)  f
let split_intro_right ?known_map f = split_pos (right_intro known_map) f

let split_goal sp pr f =
  let make_prop f = [create_prop_decl Pgoal pr f] in
  List.map make_prop (split_proof sp f)

let split_axiom sp pr f =
  let make_prop f =
    let pr = create_prsymbol (id_clone pr.pr_name) in
    create_prop_decl Paxiom pr f in
  let sp = { sp with asym_split = false; byso_split = false } in
  match split_pos sp f with
    | [f] -> [create_prop_decl Paxiom pr f]
    | fl  -> List.map make_prop fl

let split_all sp d = match d.d_node with
  | Dprop (Pgoal, pr,f) ->  split_goal  sp pr f
  | Dprop (Paxiom,pr,f) -> [split_axiom sp pr f]
  | _ -> [[d]]

let split_premise sp d = match d.d_node with
  | Dprop (Paxiom,pr,f) ->  split_axiom sp pr f
  | _ -> [d]

let prep_goal split = Trans.store (fun t ->
  let split = split (Some (Task.task_known t)) in
  let trans = Trans.goal_l (split_goal split) in
  Trans.apply trans t)

let prep_all split = Trans.store (fun t ->
  let split = split (Some (Task.task_known t)) in
  let trans = Trans.decl_l (split_all split) None in
  Trans.apply trans t)

let prep_premise split = Trans.store (fun t ->
  let split = split (Some (Task.task_known t)) in
  let trans = Trans.decl (split_premise split) None in
  Trans.apply trans t)

let split_goal_full  = prep_goal full_proof
let split_goal_right = prep_goal right_proof
let split_goal_wp    = split_goal_right

let split_all_full  = prep_all full_proof
let split_all_right = prep_all right_proof
let split_all_wp    = split_all_right

let split_premise_full  = prep_premise full_proof
let split_premise_right = prep_premise right_proof
let split_premise_wp    = split_premise_right

let () = Trans.register_transform_l "split_goal_full" split_goal_full
  ~desc:"Put@ the@ goal@ in@ a@ conjunctive@ form,@ \
  returns@ the@ corresponding@ set@ of@ subgoals.@ The@ number@ of@ subgoals@ \
  generated@ may@ be@ exponential@ in@ the@ size@ of@ the@ initial@ goal."
let () = Trans.register_transform_l "split_all_full" split_all_full
  ~desc:"Same@ as@ split_goal_full,@ but@ also@ split@ premises."
let () = Trans.register_transform "split_premise_full" split_premise_full
  ~desc:"Same@ as@ split_all_full,@ but@ split@ only@ premises."

let () = Trans.register_transform_l "split_goal_right" split_goal_right
  ~desc:"@[<hov 2>Same@ as@ split_goal_full,@ but@ don't@ split:@,\
      - @[conjunctions under disjunctions@]@\n\
      - @[conjunctions on the left of implications.@]@]"
let () = Trans.register_transform_l "split_all_right" split_all_right
  ~desc:"Same@ as@ split_goal_right,@ but@ also@ split@ premises."
let () = Trans.register_transform "split_premise_right" split_premise_right
  ~desc:"Same@ as@ split_all_right,@ but@ split@ only@ premises."

let () = Trans.register_transform_l "split_goal_wp" split_goal_wp
  ~desc:"Same@ as@ split_goal_right."
let () = Trans.register_transform_l "split_all_wp" split_all_wp
  ~desc:"Same@ as@ split_goal_wp,@ but@ also@ split@ premises."
let () = Trans.register_transform "split_premise_wp" split_premise_wp
  ~desc:"Same@ as@ split_all_wp,@ but@ split@ only@ premises."
