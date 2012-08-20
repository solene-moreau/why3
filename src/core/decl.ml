(**************************************************************************)
(*                                                                        *)
(*  Copyright (C) 2010-2012                                               *)
(*    François Bobot                                                      *)
(*    Jean-Christophe Filliâtre                                           *)
(*    Claude Marché                                                       *)
(*    Guillaume Melquiond                                                 *)
(*    Andrei Paskevich                                                    *)
(*                                                                        *)
(*  This software is free software; you can redistribute it and/or        *)
(*  modify it under the terms of the GNU Library General Public           *)
(*  License version 2.1, with the special exception on linking            *)
(*  described in file LICENSE.                                            *)
(*                                                                        *)
(*  This software is distributed in the hope that it will be useful,      *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                  *)
(*                                                                        *)
(**************************************************************************)

open Format
open Util
open Ident
open Ty
open Term

(** Type declaration *)

type constructor = lsymbol * lsymbol option list
(** constructor symbol with the list of projections *)

type data_decl = tysymbol * constructor list

(** Logic declaration *)

type ls_defn = lsymbol * term * int list

type logic_decl = lsymbol * ls_defn

exception UnboundVar of vsymbol

let check_fvs f =
  Mvs.iter (fun vs _ -> raise (UnboundVar vs)) f.t_vars;
  t_prop f

let check_vl ty v = ty_equal_check ty v.vs_ty
let check_tl ty t = ty_equal_check ty (t_type t)

let make_ls_defn ls vl t =
  (* check for duplicate arguments *)
  let add_v s v = Svs.add_new (DuplicateVar v) v s in
  ignore (List.fold_left add_v Svs.empty vl);
  (* build the definition axiom *)
  let hd = t_app ls (List.map t_var vl) t.t_ty in
  let bd = TermTF.t_selecti t_equ t_iff hd t in
  let fd = check_fvs (t_forall_close vl [] bd) in
  (* check for unbound type variables *)
  let htv = t_ty_freevars Stv.empty hd in
  let ttv = t_ty_freevars Stv.empty t in
  if not (Stv.subset ttv htv) then
    raise (UnboundTypeVar (Stv.choose (Stv.diff ttv htv)));
  (* check correspondence with the type signature of ls *)
  List.iter2 check_vl ls.ls_args vl;
  t_ty_check t ls.ls_value;
  (* return the definition *)
  ls, (ls, fd, [])

let open_ls_defn (_,f,_) =
  let vl,_,f = match f.t_node with
    | Tquant (Tforall,b) -> t_open_quant b
    | _ -> [],[],f in
  match f.t_node with
    | Tapp (_, [_; f])
    | Tbinop (_, _, f) -> vl,f
    | _ -> assert false

let open_ls_defn_cb ld =
  let ls,_,_ = ld in
  let vl,t = open_ls_defn ld in
  let close ls' vl' t' =
    if t_equal t t' && list_all2 vs_equal vl vl' && ls_equal ls ls'
    then ls,ld else make_ls_defn ls' vl' t'
  in
  vl,t,close

let ls_defn_decrease (_,_,l) = l

let ls_defn_axiom (_,f,_) = f

let ls_defn_of_axiom f =
  let _,_,f = match f.t_node with
    | Tquant (Tforall,b) -> t_open_quant b
    | _ -> [],[],f in
  let hd,e = match f.t_node with
    | Tapp (ls, [hd; t]) when ls_equal ls ps_equ -> hd,t
    | Tbinop (Tiff, hd, f) -> hd,f
    | _ -> raise Exit in
  let ls,tl = match hd.t_node with
    | Tapp (ls,tl) -> ls,tl
    | _ -> raise Exit in
  let vs_of_t t = match t.t_node with
    | Tvar v -> v
    | _ -> raise Exit in
  let vl = List.map vs_of_t tl in
  make_ls_defn ls vl e

let ls_defn_of_axiom f =
  try Some (ls_defn_of_axiom f) with
    | Exit | UnboundVar _ | UnboundTypeVar _
    | DuplicateVar _ | TypeMismatch _ -> None

(** Termination checking for mutually recursive logic declarations *)

type descent =
  | Less of int
  | Equal of int
  | Unknown

let rec match_var link acc p = match p.pat_node with
  | Pwild -> acc
  | Pvar u -> List.rev_map (Mvs.add u link) acc
  | Pas (p,u) -> List.rev_map (Mvs.add u link) (match_var link acc p)
  | Por (p1,p2) ->
      let acc1 = match_var link acc p1 in
      let acc2 = match_var link acc p2 in
      List.rev_append acc1 acc2
  | Papp _ ->
      let link = match link with
        | Unknown -> Unknown
        | Equal i -> Less i
        | Less i  -> Less i
      in
      let join u = Mvs.add u link in
      List.rev_map (Svs.fold join p.pat_vars) acc

let rec match_term vm t acc p = match t.t_node, p.pat_node with
  | _, Pwild -> acc
  | Tvar v, _ when not (Mvs.mem v vm) -> acc
  | Tvar v, _ -> match_var (Mvs.find v vm) acc p
  | Tapp _, Pvar _ -> acc
  | Tapp _, Pas (p,_) -> match_term vm t acc p
  | Tapp _, Por (p1,p2) ->
      let acc1 = match_term vm t acc p1 in
      let acc2 = match_term vm t acc p2 in
      List.rev_append acc1 acc2
  | Tapp (c1,tl), Papp (c2,pl) when ls_equal c1 c2 ->
      let down l t p = match_term vm t l p in
      List.fold_left2 down acc tl pl
  | _,_ -> acc

let build_call_graph cgr syms ls =
  let call vm s tl =
    let desc t = match t.t_node with
      | Tvar v -> Mvs.find_def Unknown v vm
      | _ -> Unknown
    in
    Hls.add cgr s (ls, Array.of_list (List.map desc tl))
  in
  let rec term vm () t = match t.t_node with
    | Tapp (s,tl) when Mls.mem s syms ->
        t_fold (term vm) () t; call vm s tl
    | Tlet ({t_node = Tvar v}, b) when Mvs.mem v vm ->
        let u,e = t_open_bound b in
        term (Mvs.add u (Mvs.find v vm) vm) () e
    | Tcase (e,bl) ->
        term vm () e; List.iter (fun b ->
          let p,t = t_open_branch b in
          let vml = match_term vm e [vm] p in
          List.iter (fun vm -> term vm () t) vml) bl
    | Tquant (_,b) ->
        let _,_,f = t_open_quant b in term vm () f
    | _ -> t_fold (term vm) () t
  in
  fun (vl,e) ->
    let i = ref (-1) in
    let add vm v = incr i; Mvs.add v (Equal !i) vm in
    let vm = List.fold_left add Mvs.empty vl in
    term vm () e

let build_call_list cgr ls =
  let htb = Hls.create 5 in
  let local v = Array.mapi (fun i -> function
    | (Less j) as d when i = j -> d
    | (Equal j) as d when i = j -> d
    | _ -> Unknown) v
  in
  let subsumes v1 v2 =
    let sbs d1 d2 = match d1,d2 with
      | _, Unknown -> ()
      | Equal u1, Equal u2 when u1 = u2 -> ()
      | Less  u1, Equal u2 when u1 = u2 -> ()
      | Less  u1, Less  u2 when u1 = u2 -> ()
      | _,_ -> raise Not_found
    in
    let test i d1 = sbs d1 (Array.get v2 i) in
    try Array.iteri test v1; true with Not_found -> false
  in
  let subsumed s c =
    List.exists (subsumes c) (Hls.find_all htb s)
  in
  let multiply v1 v2 =
    let to_less = function
      | Unknown -> Unknown
      | Equal i -> Less i
      | Less i  -> Less i
    in
    Array.map (function
      | Unknown -> Unknown
      | Equal i -> Array.get v2 i
      | Less i -> to_less (Array.get v2 i)) v1
  in
  let resolve s c =
    Hls.add htb s c;
    let mult (s,v) = (s, multiply c v) in
    List.rev_map mult (Hls.find_all cgr s)
  in
  let rec add_call lc = function
    | [] -> lc
    | (s,c)::r when ls_equal ls s -> add_call (local c :: lc) r
    | (s,c)::r when subsumed s c -> add_call lc r
    | (s,c)::r -> add_call lc (List.rev_append (resolve s c) r)
  in
  add_call [] (Hls.find_all cgr ls)

exception NoTerminationProof of lsymbol

let check_call_list ls cl =
  let add d1 d2 = match d1, d2 with
    | Unknown, _ -> d1
    | _, Unknown -> d2
    | Less _, _  -> d1
    | _, Less _  -> d2
    | _, _ -> d1
  in
  let add v1 v2 =
    Array.mapi (fun i d1 -> add d1 (Array.get v2 i)) v1
  in
  let rec check acc mx = match mx with
    | [] -> List.rev acc
    | a :: r ->
        (* calculate the bitwise minimum of all call vectors *)
        let p = List.fold_left add a r in
        (* find the decreasing argument positions *)
        let find l = function Less i -> i :: l | _ -> l in
        let res = Array.fold_left find [] p in
        (* eliminate the decreasing calls *)
        if res = [] then raise (NoTerminationProof ls);
        let test a =
          List.for_all (fun i -> Array.get a i <> Less i) res
        in
        check (List.rev_append res acc) (List.filter test mx)
  in
  check [] cl

let check_termination ldl =
  let cgr = Hls.create 5 in
  let add acc (ls,ld) = Mls.add ls (open_ls_defn ld) acc in
  let syms = List.fold_left add Mls.empty ldl in
  Mls.iter (build_call_graph cgr syms) syms;
  let check ls _ =
    let cl = build_call_list cgr ls in
    check_call_list ls cl
  in
  let res = Mls.mapi check syms in
  List.map (fun (ls,(_,f,_)) -> (ls,(ls,f,Mls.find ls res))) ldl

(** Inductive predicate declaration *)

type prsymbol = {
  pr_name : ident;
}

module Prop = WeakStructMake (struct
  type t = prsymbol
  let tag pr = pr.pr_name.id_tag
end)

module Spr = Prop.S
module Mpr = Prop.M
module Hpr = Prop.H
module Wpr = Prop.W

let pr_equal : prsymbol -> prsymbol -> bool = (==)

let pr_hash pr = id_hash pr.pr_name

let create_prsymbol n = { pr_name = id_register n }

type ind_decl = lsymbol * (prsymbol * term) list

type ind_sign = Ind | Coind

type ind_list = ind_sign * ind_decl list

(** Proposition declaration *)

type prop_kind =
  | Plemma    (* prove, use as a premise *)
  | Paxiom    (* do not prove, use as a premise *)
  | Pgoal     (* prove, do not use as a premise *)
  | Pskip     (* do not prove, do not use as a premise *)

type prop_decl = prop_kind * prsymbol * term

(** Declaration type *)

type decl = {
  d_node : decl_node;
  d_syms : Sid.t;         (* idents used in declaration *)
  d_news : Sid.t;         (* idents introduced in declaration *)
  d_tag  : Hashweak.tag;  (* unique magical tag *)
}

and decl_node =
  | Dtype  of tysymbol          (* abstract types and aliases *)
  | Ddata  of data_decl list    (* recursive algebraic types *)
  | Dparam of lsymbol           (* abstract functions and predicates *)
  | Dlogic of logic_decl list   (* recursive functions and predicates *)
  | Dind   of ind_list          (* (co)inductive predicates *)
  | Dprop  of prop_decl         (* axiom / lemma / goal *)

(** Declarations *)

module Hsdecl = Hashcons.Make (struct

  type t = decl

  let cs_equal (cs1,pl1) (cs2,pl2) =
    ls_equal cs1 cs2 && list_all2 (option_eq ls_equal) pl1 pl2

  let eq_td (ts1,td1) (ts2,td2) =
    ts_equal ts1 ts2 && list_all2 cs_equal td1 td2

  let eq_ld (ls1,(_,f1,_)) (ls2,(_,f2,_)) =
    ls_equal ls1 ls2 && t_equal f1 f2

  let eq_iax (pr1,fr1) (pr2,fr2) =
    pr_equal pr1 pr2 && t_equal fr1 fr2

  let eq_ind (ps1,al1) (ps2,al2) =
    ls_equal ps1 ps2 && list_all2 eq_iax al1 al2

  let equal d1 d2 = match d1.d_node, d2.d_node with
    | Dtype  s1, Dtype  s2 -> ts_equal s1 s2
    | Ddata  l1, Ddata  l2 -> list_all2 eq_td l1 l2
    | Dparam s1, Dparam s2 -> ls_equal s1 s2
    | Dlogic l1, Dlogic l2 -> list_all2 eq_ld l1 l2
    | Dind   (s1,l1), Dind (s2,l2) -> s1 = s2 && list_all2 eq_ind l1 l2
    | Dprop (k1,pr1,f1), Dprop (k2,pr2,f2) ->
        k1 = k2 && pr_equal pr1 pr2 && t_equal f1 f2
    | _,_ -> false

  let cs_hash (cs,pl) =
    Hashcons.combine_list (Hashcons.combine_option ls_hash) (ls_hash cs) pl

  let hs_td (ts,td) = Hashcons.combine_list cs_hash (ts_hash ts) td

  let hs_ld (ls,(_,f,_)) = Hashcons.combine (ls_hash ls) (t_hash f)

  let hs_prop (pr,f) = Hashcons.combine (pr_hash pr) (t_hash f)

  let hs_ind (ps,al) = Hashcons.combine_list hs_prop (ls_hash ps) al

  let hs_kind = function
    | Plemma -> 11 | Paxiom -> 13 | Pgoal  -> 17 | Pskip  -> 19

  let hash d = match d.d_node with
    | Dtype  s -> ts_hash s
    | Ddata  l -> Hashcons.combine_list hs_td 3 l
    | Dparam s -> ls_hash s
    | Dlogic l -> Hashcons.combine_list hs_ld 5 l
    | Dind (_,l) -> Hashcons.combine_list hs_ind 7 l
    | Dprop (k,pr,f) -> Hashcons.combine (hs_kind k) (hs_prop (pr,f))

  let tag n d = { d with d_tag = Hashweak.create_tag n }

end)

module Decl = WeakStructMake (struct
  type t = decl
  let tag d = d.d_tag
end)

module Sdecl = Decl.S
module Mdecl = Decl.M
module Wdecl = Decl.W
module Hdecl = Decl.H

let d_equal : decl -> decl -> bool = (==)

let d_hash d = Hashweak.tag_hash d.d_tag

(** Declaration constructors *)

let mk_decl node syms news = Hsdecl.hashcons {
  d_node = node;
  d_syms = syms;
  d_news = news;
  d_tag  = Hashweak.dummy_tag;
}

exception IllegalTypeAlias of tysymbol
exception ClashIdent of ident
exception BadLogicDecl of lsymbol * lsymbol
exception BadConstructor of lsymbol

exception BadRecordField of lsymbol
exception RecordFieldMissing of lsymbol * lsymbol
exception DuplicateRecordField of lsymbol * lsymbol

exception EmptyDecl
exception EmptyAlgDecl of tysymbol
exception EmptyIndDecl of lsymbol

exception NonPositiveTypeDecl of tysymbol * lsymbol * ty

let news_id s id = Sid.add_new (ClashIdent id) id s

let syms_ts s ts = Sid.add ts.ts_name s
let syms_ls s ls = Sid.add ls.ls_name s

let syms_ty s ty = ty_s_fold syms_ts s ty
let syms_term s t = t_s_fold syms_ty syms_ls s t

let create_ty_decl ts =
  let syms = Util.option_fold syms_ty Sid.empty ts.ts_def in
  let news = Sid.singleton ts.ts_name in
  mk_decl (Dtype ts) syms news

let create_data_decl tdl =
  if tdl = [] then raise EmptyDecl;
  let add s (ts,_) = Sts.add ts s in
  let tss = List.fold_left add Sts.empty tdl in
  let check_proj cs tyv s tya ls = match ls with
    | None -> s
    | Some ({ ls_args = [ptyv]; ls_value = Some ptya } as ls) ->
        ty_equal_check tyv ptyv;
        ty_equal_check tya ptya;
        Sls.add_new (DuplicateRecordField (cs,ls)) ls s
    | Some ls -> raise (BadRecordField ls)
  in
  let check_constr tys ty pjs (syms,news) (fs,pl) =
    ty_equal_check ty (exn_option (BadConstructor fs) fs.ls_value);
    let fs_pjs =
      try List.fold_left2 (check_proj fs ty) Sls.empty fs.ls_args pl
      with Invalid_argument _ -> raise (BadConstructor fs) in
    if not (Sls.equal pjs fs_pjs) then
      raise (RecordFieldMissing (fs, Sls.choose (Sls.diff pjs fs_pjs)));
    let vs = ty_freevars Stv.empty ty in
    let rec check seen ty = match ty.ty_node with
      | Tyvar v when Stv.mem v vs -> ()
      | Tyvar v -> raise (UnboundTypeVar v)
      | Tyapp (ts,tl) ->
          let now = Sts.mem ts tss in
          if seen && now
            then raise (NonPositiveTypeDecl (tys,fs,ty))
            else List.iter (check (seen || now)) tl
    in
    List.iter (check false) fs.ls_args;
    let syms = List.fold_left syms_ty syms fs.ls_args in
    syms, news_id news fs.ls_name
  in
  let check_decl (syms,news) (ts,cl) =
    if cl = [] then raise (EmptyAlgDecl ts);
    if ts.ts_def <> None then raise (IllegalTypeAlias ts);
    let news = news_id news ts.ts_name in
    let pjs = List.fold_left (fun s (_,pl) -> List.fold_left
      (option_fold (fun s ls -> Sls.add ls s)) s pl) Sls.empty cl in
    let news = Sls.fold (fun pj s -> news_id s pj.ls_name) pjs news in
    let ty = ty_app ts (List.map ty_var ts.ts_args) in
    List.fold_left (check_constr ts ty pjs) (syms,news) cl
  in
  let (syms,news) = List.fold_left check_decl (Sid.empty,Sid.empty) tdl in
  mk_decl (Ddata tdl) syms news

let create_param_decl ls =
  let syms = Util.option_fold syms_ty Sid.empty ls.ls_value in
  let syms = List.fold_left syms_ty syms ls.ls_args in
  let news = Sid.singleton ls.ls_name in
  mk_decl (Dparam ls) syms news

let create_logic_decl ldl =
  if ldl = [] then raise EmptyDecl;
  let check_decl (syms,news) (ls,((s,_,_) as ld)) =
    if not (ls_equal s ls) then raise (BadLogicDecl (ls, s));
    let _, e = open_ls_defn ld in
    let syms = List.fold_left syms_ty syms ls.ls_args in
    syms_term syms e, news_id news ls.ls_name
  in
  let (syms,news) = List.fold_left check_decl (Sid.empty,Sid.empty) ldl in
  let ldl = check_termination ldl in
  mk_decl (Dlogic ldl) syms news

exception InvalidIndDecl of lsymbol * prsymbol
exception NonPositiveIndDecl of lsymbol * prsymbol * lsymbol

exception Found of lsymbol
let ls_mem s sps = if Sls.mem s sps then raise (Found s) else false
let t_pos_ps sps = t_s_all (fun _ -> true) (fun s -> not (ls_mem s sps))

let rec f_pos_ps sps pol f = match f.t_node, pol with
  | Tapp (s, _), Some false when ls_mem s sps -> false
  | Tapp (s, _), None when ls_mem s sps -> false
  | Tbinop (Tiff, f, g), _ ->
      f_pos_ps sps None f && f_pos_ps sps None g
  | Tbinop (Timplies, f, g), _ ->
      f_pos_ps sps (option_map not pol) f && f_pos_ps sps pol g
  | Tnot f, _ ->
      f_pos_ps sps (option_map not pol) f
  | Tif (f,g,h), _ ->
      f_pos_ps sps None f && f_pos_ps sps pol g && f_pos_ps sps pol h
  | _ -> TermTF.t_all (t_pos_ps sps) (f_pos_ps sps pol) f

let create_ind_decl s idl =
  if idl = [] then raise EmptyDecl;
  let add acc (ps,_) = Sls.add ps acc in
  let sps = List.fold_left add Sls.empty idl in
  let check_ax ps (syms,news) (pr,f) =
    let rec clause acc f = match f.t_node with
      | Tquant (Tforall, f) ->
          let _,_,f = t_open_quant f in clause acc f
      | Tbinop (Timplies, g, f) -> clause (g::acc) f
      | _ -> (acc, f)
    in
    let cls, g = clause [] (check_fvs f) in
    match g.t_node with
      | Tapp (s, tl) when ls_equal s ps ->
          List.iter2 check_tl ps.ls_args tl;
          (try ignore (List.for_all (f_pos_ps sps (Some true)) cls)
          with Found ls -> raise (NonPositiveIndDecl (ps, pr, ls)));
          (* check for unbound type variables *)
          let gtv = t_ty_freevars Stv.empty g in
          let ftv = t_ty_freevars Stv.empty f in
          if not (Stv.subset ftv gtv) then
            raise (UnboundTypeVar (Stv.choose (Stv.diff ftv gtv)));
          syms_term syms f, news_id news pr.pr_name
      | _ -> raise (InvalidIndDecl (ps, pr))
  in
  let check_decl (syms,news) (ps,al) =
    if al = [] then raise (EmptyIndDecl ps);
    let news = news_id news ps.ls_name in
    List.fold_left (check_ax ps) (syms,news) al
  in
  let (syms,news) = List.fold_left check_decl (Sid.empty,Sid.empty) idl in
  mk_decl (Dind (s, idl)) syms news

let create_prop_decl k p f =
  let syms = syms_term Sid.empty f in
  let news = news_id Sid.empty p.pr_name in
  mk_decl (Dprop (k,p,check_fvs f)) syms news

(** Utilities *)

let decl_map fn d = match d.d_node with
  | Dtype _ | Ddata _ | Dparam _ -> d
  | Dlogic l ->
      let fn (ls,ld) =
        let vl,e,close = open_ls_defn_cb ld in
        close ls vl (fn e)
      in
      create_logic_decl (List.map fn l)
  | Dind (s, l) ->
      let fn (pr,f) = pr, fn f in
      let fn (ps,l) = ps, List.map fn l in
      create_ind_decl s (List.map fn l)
  | Dprop (k,pr,f) ->
      create_prop_decl k pr (fn f)

let decl_fold fn acc d = match d.d_node with
  | Dtype _ | Ddata _ | Dparam _ -> acc
  | Dlogic l ->
      let fn acc (_,ld) =
        let _,e = open_ls_defn ld in
        fn acc e
      in
      List.fold_left fn acc l
  | Dind (_, l) ->
      let fn acc (_,f) = fn acc f in
      let fn acc (_,l) = List.fold_left fn acc l in
      List.fold_left fn acc l
  | Dprop (_,_,f) ->
      fn acc f

let list_rpair_map_fold fn =
  let fn acc (x1,x2) =
    let acc,x2 = fn acc x2 in acc,(x1,x2) in
  Util.map_fold_left fn

let decl_map_fold fn acc d = match d.d_node with
  | Dtype _ | Ddata _ | Dparam _ -> acc, d
  | Dlogic l ->
      let fn acc (ls,ld) =
        let vl,e,close = open_ls_defn_cb ld in
        let acc,e = fn acc e in
        acc, close ls vl e
      in
      let acc,l = Util.map_fold_left fn acc l in
      acc, create_logic_decl l
  | Dind (s, l) ->
      let acc, l = list_rpair_map_fold (list_rpair_map_fold fn) acc l in
      acc, create_ind_decl s l
  | Dprop (k,pr,f) ->
      let acc, f = fn acc f in
      acc, create_prop_decl k pr f

module DeclTF = struct
  let decl_map fnT fnF = decl_map (TermTF.t_select fnT fnF)
  let decl_fold fnT fnF = decl_fold (TermTF.t_selecti fnT fnF)
  let decl_map_fold fnT fnF = decl_map_fold (TermTF.t_selecti fnT fnF)
end

(** Known identifiers *)

exception KnownIdent of ident
exception UnknownIdent of ident
exception RedeclaredIdent of ident

type known_map = decl Mid.t

let known_id kn id =
  if not (Mid.mem id kn) then raise (UnknownIdent id)

let merge_known kn1 kn2 =
  let check_known id decl1 decl2 =
    if d_equal decl1 decl2 then Some decl1
    else raise (RedeclaredIdent id)
  in
  Mid.union check_known kn1 kn2

let known_add_decl kn0 decl =
  let kn = Mid.map (const decl) decl.d_news in
  let check id decl0 _ =
    if d_equal decl0 decl
    then raise (KnownIdent id)
    else raise (RedeclaredIdent id)
  in
  let kn = Mid.union check kn0 kn in
  let unk = Mid.set_diff decl.d_syms kn in
  if Sid.is_empty unk then kn
  else raise (UnknownIdent (Sid.choose unk))

let find_constructors kn ts =
  match (Mid.find ts.ts_name kn).d_node with
  | Dtype _ -> []
  | Ddata dl -> List.assq ts dl
  | Dparam _ | Dlogic _ | Dind _ | Dprop _ -> assert false

let find_inductive_cases kn ps =
  match (Mid.find ps.ls_name kn).d_node with
  | Dind (_, dl) -> List.assq ps dl
  | Dlogic _ | Ddata _ -> []
  | Dtype _ | Dparam _ | Dprop _ -> assert false

let find_logic_definition kn ls =
  match (Mid.find ls.ls_name kn).d_node with
  | Dlogic dl -> Some (List.assq ls dl)
  | Dparam _ | Dind _ | Ddata _ -> None
  | Dtype _ | Dprop _ -> assert false

let find_prop kn pr =
  match (Mid.find pr.pr_name kn).d_node with
  | Dind (_, dl) ->
      let test (_,l) = List.mem_assq pr l in
      List.assq pr (snd (List.find test dl))
  | Dprop (_,_,f) -> f
  | Dtype _ | Ddata _ | Dparam _ | Dlogic _ -> assert false

let find_prop_decl kn pr =
  match (Mid.find pr.pr_name kn).d_node with
  | Dind (_, dl) ->
      let test (_,l) = List.mem_assq pr l in
      Paxiom, List.assq pr (snd (List.find test dl))
  | Dprop (k,_,f) -> k,f
  | Dtype _ | Ddata _ | Dparam _ | Dlogic _ -> assert false

exception NonExhaustiveCase of pattern list * term

let rec check_matchT kn () t = match t.t_node with
  | Tcase (t1,bl) ->
      let bl = List.map (fun b -> let p,t = t_open_branch b in [p],t) bl in
      let find_constructors kn ts = List.map fst (find_constructors kn ts) in
      ignore (try Pattern.CompileTerm.compile (find_constructors kn) [t1] bl
      with Pattern.NonExhaustive p -> raise (NonExhaustiveCase (p,t)));
      t_fold (check_matchT kn) () t
  | _ -> t_fold (check_matchT kn) () t

let check_match kn d = decl_fold (check_matchT kn) () d

exception NonFoundedTypeDecl of tysymbol

let check_foundness kn d =
  let rec check_ts tss tvs ts =
    (* recursive data type, abandon *)
    if Sts.mem ts tss then false else
    let cl = find_constructors kn ts in
    (* an abstract type is inhabited iff
       all its type arguments are inhabited *)
    if cl == [] then Stv.is_empty tvs else
    (* an algebraic type is inhabited iff
       we can build a value of this type *)
    let tss = Sts.add ts tss in
    List.exists (check_constr tss tvs) cl
  and check_constr tss tvs (ls,_) =
    (* we can construct a value iff every
       argument is of an inhabited type *)
    List.for_all (check_type tss tvs) ls.ls_args
  and check_type tss tvs ty = match ty.ty_node with
    | Tyvar tv ->
        not (Stv.mem tv tvs)
    | Tyapp (ts,tl) ->
        let check acc tv ty =
          if check_type tss tvs ty then acc else Stv.add tv acc in
        let tvs = List.fold_left2 check Stv.empty ts.ts_args tl in
        check_ts tss tvs ts
  in
  match d.d_node with
  | Ddata tdl ->
      let check () (ts,_) =
        if check_ts Sts.empty Stv.empty ts
        then () else raise (NonFoundedTypeDecl ts)
      in
      List.fold_left check () tdl
  | _ -> ()

let rec ts_extract_pos kn sts ts =
  assert (ts.ts_def = None);
  if ts_equal ts ts_func then [false;true] else
  if ts_equal ts ts_pred then [false] else
  if Sts.mem ts sts then List.map Util.ttrue ts.ts_args else
  match find_constructors kn ts with
    | [] ->
        List.map Util.ffalse ts.ts_args
    | csl ->
        let sts = Sts.add ts sts in
        let rec get_ty stv ty = match ty.ty_node with
          | Tyvar _ -> stv
          | Tyapp (ts,tl) ->
              let get acc pos =
                if pos then get_ty acc else ty_freevars acc in
              List.fold_left2 get stv (ts_extract_pos kn sts ts) tl
        in
        let get_cs acc (ls,_) = List.fold_left get_ty acc ls.ls_args in
        let negs = List.fold_left get_cs Stv.empty csl in
        List.map (fun v -> not (Stv.mem v negs)) ts.ts_args

let check_positivity kn d = match d.d_node with
  | Ddata tdl ->
      let add s (ts,_) = Sts.add ts s in
      let tss = List.fold_left add Sts.empty tdl in
      let check_constr tys (cs,_) =
        let rec check_ty ty = match ty.ty_node with
          | Tyvar _ -> ()
          | Tyapp (ts,tl) ->
              let check pos ty =
                if pos then check_ty ty else
                if ty_s_any (fun ts -> Sts.mem ts tss) ty
                then raise (NonPositiveTypeDecl (tys,cs,ty))
              in
              List.iter2 check (ts_extract_pos kn Sts.empty ts) tl
        in
        List.iter check_ty cs.ls_args
      in
      let check_decl (ts,cl) = List.iter (check_constr ts) cl in
      List.iter check_decl tdl
  | _ -> ()

let known_add_decl kn d =
  let kn = known_add_decl kn d in
  check_positivity kn d;
  check_foundness kn d;
  check_match kn d;
  kn

(** Records *)

exception EmptyRecord

let parse_record kn fll =
  let fs = match fll with
    | [] -> raise EmptyRecord
    | (fs,_)::_ -> fs in
  let ts = match fs.ls_args with
    | [{ ty_node = Tyapp (ts,_) }] -> ts
    | _ -> raise (BadRecordField fs) in
  let cs, pjl = match find_constructors kn ts with
    | [cs,pjl] -> cs, List.map (exn_option (BadRecordField fs)) pjl
    | _ -> raise (BadRecordField fs) in
  let pjs = List.fold_left (fun s pj -> Sls.add pj s) Sls.empty pjl in
  let flm = List.fold_left (fun m (pj,v) ->
    if not (Sls.mem pj pjs) then raise (BadRecordField pj) else
    Mls.add_new (DuplicateRecordField (cs,pj)) pj v m) Mls.empty fll in
  cs,pjl,flm

let make_record kn fll ty =
  let cs,pjl,flm = parse_record kn fll in
  let get_arg pj = Mls.find_exn (RecordFieldMissing (cs,pj)) pj flm in
  fs_app cs (List.map get_arg pjl) ty

let make_record_update kn t fll ty =
  let cs,pjl,flm = parse_record kn fll in
  let get_arg pj = match Mls.find_opt pj flm with
    | Some v -> v
    | None -> t_app_infer pj [t] in
  fs_app cs (List.map get_arg pjl) ty

let make_record_pattern kn fll ty =
  let cs,pjl,flm = parse_record kn fll in
  let s = ty_match Mtv.empty (of_option cs.ls_value) ty in
  let get_arg pj = match Mls.find_opt pj flm with
    | Some v -> v
    | None -> pat_wild (ty_inst s (of_option pj.ls_value))
  in
  pat_app cs (List.map get_arg pjl) ty

