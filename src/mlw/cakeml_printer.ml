(********************************************************************)
(*                                                                  *)
(*  The Why3 Verification Platform   /   The Why3 Development Team  *)
(*  Copyright 2010-2018   --   Inria - CNRS - Paris-Sud University  *)
(*                                                                  *)
(*  This software is distributed under the terms of the GNU Lesser  *)
(*  General Public License version 2.1, with the special exception  *)
(*  on linking described in file LICENSE.                           *)
(*                                                                  *)
(********************************************************************)
open Compile
open Format
open Ident
open Pp
open Ity
open Term
open Expr
open Ty
open Theory
open Pmodule
open Pdecl
open Printer

type info = {
  info_syn          : syntax_map;
  info_convert      : syntax_map;
  info_literal      : syntax_map;
  info_current_th   : Theory.theory;
  info_current_mo   : Pmodule.pmodule option;
  info_th_known_map : Decl.known_map;
  info_mo_known_map : Pdecl.known_map;
  info_fname        : string option;
  info_flat         : bool;
  info_current_ph   : string list; (* current path *)
}

module Print = struct

  open Mltree

  (* extraction labels *)
  let sml_remove = create_label "sml:remove"

  let is_sml_remove ~labels =
    Ident.Slab.mem sml_remove labels

  let sml_keywords =
    ["abstype"; "and"; "andalso"; "as"; "case"; "datatype"; "do"; "else";
     "end"; "exception"; "fn"; "fun"; "handle"; "if"; "in"; "infix";
     "infixr"; "let"; "local"; "nonfix"; "of"; "op"; "open"; "orelse";
     "raise"; "rec"; "then"; "type"; "val"; "with"; "withtype"; "while";]

  (* iprinter: local names
     aprinter: type variables
     tprinter: toplevel definitions *)
  let iprinter, aprinter, tprinter =
    let isanitize = sanitizer char_to_alpha char_to_alnumus in
    let lsanitize = sanitizer char_to_lalpha char_to_alnumus in
    create_ident_printer sml_keywords ~sanitizer:isanitize,
    create_ident_printer sml_keywords ~sanitizer:lsanitize,
    create_ident_printer sml_keywords ~sanitizer:lsanitize

  let forget_id id = forget_id iprinter id
  let _forget_ids = List.iter forget_id
  let forget_var (id, _, _) = forget_id id
  let forget_vars = List.iter forget_var

  let forget_let_defn = function
    | Lvar (v,_) -> forget_id v.pv_vs.vs_name
    | Lsym (s,_,_,_) | Lany (s,_,_) -> forget_rs s
    | Lrec rdl -> List.iter (fun fd -> forget_rs fd.rec_sym) rdl

  let rec forget_pat = function
    | Pwild -> ()
    | Pvar {vs_name=id} -> forget_id id
    | Papp (_, pl) | Ptuple pl -> List.iter forget_pat pl
    | Por (p1, p2) -> forget_pat p1; forget_pat p2
    | Pas (p, _) -> forget_pat p

  let print_global_ident ~sanitizer fmt id =
    let s = id_unique ~sanitizer tprinter id in
    Ident.forget_id tprinter id;
    fprintf fmt "%s" s

  let print_path ~sanitizer fmt (q, id) =
    assert (List.length q >= 1);
    match Lists.chop_last q with
    | [], _ -> print_global_ident ~sanitizer fmt id
    | q, _  ->
        fprintf fmt "%a.%a"
          (print_list dot string) q (print_global_ident ~sanitizer) id

  let rec remove_prefix acc current_path = match acc, current_path with
    | [], _ | _, [] -> acc
    | p1 :: _, p2 :: _ when p1 <> p2 -> acc
    | _ :: r1, _ :: r2 -> remove_prefix r1 r2

  let is_local_id info id =
    Sid.mem id info.info_current_th.th_local ||
    Opt.fold (fun _ m -> Sid.mem id m.Pmodule.mod_local)
      false info.info_current_mo

  exception Local

  let print_qident ~sanitizer info fmt id =
    try
      if info.info_flat then raise Not_found;
      if is_local_id info id then raise Local;
      let p, t, q =
        try Pmodule.restore_path id with Not_found -> Theory.restore_path id in
      let fname = if p = [] then info.info_fname else None in
      let m = Strings.capitalize (module_name ?fname p t) in
      fprintf fmt "%s.%a" m (print_path ~sanitizer) (q, id)
    with
    | Not_found ->
        let s = id_unique ~sanitizer iprinter id in
        fprintf fmt "%s" s
    | Local ->
        let _, _, q = try Pmodule.restore_path id with Not_found ->
          Theory.restore_path id in
        let q = remove_prefix q (List.rev info.info_current_ph) in
        print_path ~sanitizer fmt (q, id)

  let print_lident = print_qident ~sanitizer:Strings.uncapitalize
  let print_uident = print_qident ~sanitizer:Strings.capitalize

  let print_tv fmt tv =
    fprintf fmt "'%s" (id_unique aprinter tv.tv_name)

  let protect_on b s =
    if b then "(" ^^ s ^^ ")" else s

  let star fmt () = fprintf fmt " *@ "

  let rec print_list2 sep sep_m print1 print2 fmt (l1, l2) =
    match l1, l2 with
    | [x1], [x2] ->
        print1 fmt x1; sep_m fmt (); print2 fmt x2
    | x1 :: r1, x2 :: r2 ->
        print1 fmt x1; sep_m fmt (); print2 fmt x2; sep fmt ();
        print_list2 sep sep_m print1 print2 fmt (r1, r2)
    | _ -> ()

  let print_rs info fmt rs =
    fprintf fmt "%a" (print_lident info) rs.rs_name

  (** Types *)

  let rec print_ty ?(paren=false) info fmt = function
    | Tvar tv ->
        print_tv fmt tv
    | Ttuple [] ->
        fprintf fmt "unit"
    | Ttuple [t] ->
        print_ty ~paren info fmt t
    | Ttuple tl ->
        fprintf fmt (protect_on paren "@[%a@]")
          (print_list star (print_ty ~paren:true info)) tl
    | Tapp (ts, tl) ->
        match query_syntax info.info_syn ts with
        | Some s ->
            fprintf fmt (protect_on paren "%a")
              (syntax_arguments s (print_ty ~paren:true info)) tl
        | None   ->
            match tl with
            | [] ->
                (print_lident info) fmt ts
            | [ty] ->
                fprintf fmt (protect_on paren "%a@ %a")
                  (print_ty ~paren:true info) ty (print_lident info) ts
            | tl ->
                fprintf fmt (protect_on paren "(%a)@ %a")
                  (print_list comma (print_ty ~paren:false info)) tl
                  (print_lident info) ts

  let print_vsty_opt info fmt id ty =
    fprintf fmt "?%s:(%a:@ %a)" id.id_string (print_lident info) id
      (print_ty ~paren:false info) ty

  let print_vsty_named info fmt id ty =
    fprintf fmt "~%s:(%a:@ %a)" id.id_string (print_lident info) id
      (print_ty ~paren:false info) ty

  let print_vsty info fmt (id, ty, _) =
    fprintf fmt "(%a:@ %a)" (print_lident info) id
      (print_ty ~paren:false info) ty

  let print_tv_arg = print_tv
  let print_tv_args fmt = function
    | []   -> ()
    | [tv] -> fprintf fmt "%a@ " print_tv_arg tv
    | tvl  -> fprintf fmt "(%a)@ " (print_list comma print_tv_arg) tvl

  let print_vs_arg info fmt vs =
    fprintf fmt "@[%a@]" (print_vsty info) vs

  let get_record info rs =
    match Mid.find_opt rs.rs_name info.info_mo_known_map with
    | Some {pd_node = PDtype itdl} ->
        let eq_rs {itd_constructors} =
          List.exists (rs_equal rs) itd_constructors in
        let itd = List.find eq_rs itdl in
        List.filter (fun e -> not (rs_ghost e)) itd.itd_fields
    | _ -> []

  let rec print_pat info fmt = function
    | Pwild ->
        fprintf fmt "_"
    | Pvar {vs_name=id} ->
        (print_lident info) fmt id
    | Pas (p, {vs_name=id}) ->
        fprintf fmt "%a as %a" (print_pat info) p (print_lident info) id
    | Por (p1, p2) ->
        fprintf fmt "%a | %a" (print_pat info) p1 (print_pat info) p2
    | Ptuple pl ->
        fprintf fmt "(%a)" (print_list comma (print_pat info)) pl
    | Papp (ls, pl) ->
        match query_syntax info.info_syn ls.ls_name, pl with
        | Some s, _ ->
            syntax_arguments s (print_pat info) fmt pl
        | None, pl ->
            let pjl = let rs = restore_rs ls in get_record info rs in
            match pjl with
            | []  -> print_papp info ls fmt pl
            | pjl -> fprintf fmt "@[<hov 2>{ %a }@]"
                (print_list2 semi equal (print_rs info) (print_pat info))
                (pjl, pl)

  and print_papp info ls fmt = function
    | []  -> fprintf fmt "%a"      (print_uident info) ls.ls_name
    | [p] -> fprintf fmt "%a %a"   (print_uident info) ls.ls_name
               (print_pat info) p
    | pl  -> fprintf fmt "%a %a" (print_uident info) ls.ls_name
               (print_list space (print_pat info)) pl

  (** Expressions *)

  let pv_name pv = pv.pv_vs.vs_name
  let print_pv info fmt pv = print_lident info fmt (pv_name pv)

  let ht_rs = Hrs.create 7 (* rec_rsym -> rec_sym *)

  (* FIXME put these in Compile*)
  let is_true e = match e.e_node with
    | Eapp (s, []) -> rs_equal s rs_true
    | _ -> false

  let is_false e = match e.e_node with
    | Eapp (s, []) -> rs_equal s rs_false
    | _ -> false

  let check_val_in_drv info ({rs_name = {id_loc = loc}} as rs) =
    (* here [rs] refers to a [val] declaration *)
    match query_syntax info.info_convert rs.rs_name,
          query_syntax info.info_syn     rs.rs_name with
    | None, None (* when info.info_flat *) ->
        Loc.errorm ?loc "Function %a cannot be extracted" Expr.print_rs rs
    | _ -> ()

  let is_mapped_to_int info ity =
    match ity.ity_node with
    | Ityapp ({ its_ts = ts }, _, _) ->
        query_syntax info.info_syn ts.ts_name = Some "int"
    | _ -> false

  let print_constant fmt e = begin match e.e_node with
    | Econst c ->
        let s = BigInt.to_string (Number.compute_int_constant c) in
        if c.Number.ic_negative then fprintf fmt "(%s)" s
        else fprintf fmt "%s" s
    | _ -> assert false end

  let print_for_direction fmt = function
    | To     -> fprintf fmt "to"
    | DownTo -> fprintf fmt "downto"

  let rec print_apply_args info fmt = function
    | expr :: exprl, _ :: pvl ->
        fprintf fmt "%a" (print_expr ~paren:true info) expr;
        if exprl <> [] then fprintf fmt "@ ";
        print_apply_args info fmt (exprl, pvl)
    | expr :: exprl, [] ->
        fprintf fmt "%a" (print_expr ~paren:true info) expr;
        print_apply_args info fmt (exprl, [])
    | [], _ -> ()

  and print_apply info rs fmt pvl =
    let isfield =
      match rs.rs_field with
      | None   -> false
      | Some _ -> true in
    let isconstructor () =
      match Mid.find_opt rs.rs_name info.info_mo_known_map with
      | Some {pd_node = PDtype its} ->
          let is_constructor its =
            List.exists (rs_equal rs) its.itd_constructors in
          List.exists is_constructor its
      | _ -> false in
    match query_syntax info.info_convert rs.rs_name,
          query_syntax info.info_syn rs.rs_name, pvl with
    | Some s, _, [{e_node = Econst _}] ->
        syntax_arguments s print_constant fmt pvl
    | _, Some s, _ (* when is_local_id info rs.rs_name  *)->
        syntax_arguments s (print_expr ~paren:true info) fmt pvl;
    | _, None, tl when is_rs_tuple rs ->
        fprintf fmt "@[(%a)@]"
          (print_list comma (print_expr info)) tl
    | _, None, [t1] when isfield ->
        fprintf fmt "%a.%a" (print_expr info) t1 (print_lident info) rs.rs_name
    | _, None, tl when isconstructor () -> let pjl = get_record info rs in
        begin match pjl, tl with
          | [], [] ->
              (print_uident info) fmt rs.rs_name
          | [], [t] ->
              fprintf fmt "@[<hov 2>%a %a@]" (print_uident info) rs.rs_name
                (print_expr ~paren:true info) t
          | [], tl ->
              fprintf fmt "@[<hov 2>%a %a@]" (print_uident info) rs.rs_name
                (print_list space (print_expr ~paren:true info)) tl
          | pjl, tl ->
              let equal fmt () = fprintf fmt " = " in
              fprintf fmt "@[<hov 2>{ @[%a@] }@]"
                (print_list2 semi equal (print_rs info) (print_expr info))
                (pjl, tl) end
    | _, None, [] ->
        (print_lident info) fmt rs.rs_name
    | _, _, tl ->
        fprintf fmt "@[<hov 2>%a %a@]"
          (print_lident info) rs.rs_name
          (print_apply_args info) (tl, rs.rs_cty.cty_args)
  (* (print_list space (print_expr ~paren:true info)) tl *)

  and print_svar fmt s =
    Stv.iter (fun tv -> fprintf fmt "%a " print_tv tv) s

  and print_fun_type_args info fmt (args, s, res, e) =
    if Stv.is_empty s then
      fprintf fmt "@[%a@] =@ %a"
        (print_list space (print_vs_arg info)) args
        (print_expr info) e
    else
      let ty_args = List.map (fun (_, ty, _) -> ty) args in
      let id_args = List.map (fun (id, _, _) -> id) args in
      let arrow fmt () = fprintf fmt " ->@ " in
      fprintf fmt ":@ @[<h>@[%a@]. @[%a ->@ %a@]@] =@ \
                   @[<hov 2>fun @[%a@]@ ->@ %a@]"
        print_svar s
        (print_list arrow (print_ty ~paren:true info)) ty_args
        (print_ty ~paren:true info) res
        (print_list space (print_lident info)) id_args
        (print_expr info) e

  and print_let_def info fmt = function
    | Lvar (pv, e) ->
        fprintf fmt "@[<hov 2>val %a =@ %a@]" (print_lident info) (pv_name pv)
          (print_expr info) e
    | Lsym (rs, _, [], ef) ->
        (* TODO? zero-arguments functions as Lvar in compile.Translate *)
        fprintf fmt "@[<hov 2>val %a =@ @[%a@]@]"
          (print_lident info) rs.rs_name (print_expr info) ef;
    | Lsym (rs, _, args, ef) ->
        fprintf fmt "@[<hov 2>fun %a @[%a@] =@ @[%a@]@]"
          (print_lident info) rs.rs_name
          (print_list space (print_vs_arg info)) args
          (print_expr info) ef;
        forget_vars args
    | Lrec rdef ->
        let print_one fst fmt = function
          | { rec_sym = rs1; rec_args = args; rec_exp = e;
              rec_res = res; rec_svar = s } ->
              fprintf fmt "@[<hov 2>%s %a %a@]"
                (if fst then "fun" else "and")
                (print_lident info) rs1.rs_name
                (print_fun_type_args info) (args, s, res, e);
              forget_vars args in
        List.iter (fun fd -> Hrs.replace ht_rs fd.rec_rsym fd.rec_sym) rdef;
        print_list_next newline print_one fmt rdef;
        List.iter (fun fd -> Hrs.remove ht_rs fd.rec_rsym) rdef
    | Lany (rs, _, _) ->
        check_val_in_drv info rs

  and print_expr ?(paren=false) info fmt e = match e.e_node with
    | Econst c ->
        let n = Number.compute_int_constant c in
        let n = BigInt.to_string n in
        let id = match e.e_ity with
          | I { ity_node = Ityapp ({its_ts = ts},_,_) } -> ts.ts_name
          | _ -> assert false in
        (match query_syntax info.info_literal id with
         | Some s -> syntax_arguments s print_constant fmt [e]
         | None   -> fprintf fmt (protect_on paren "%s") n)
    | Evar pvs ->
        (print_lident info) fmt (pv_name pvs)
    | Elet (let_def, e) ->
        fprintf fmt (protect_on paren "let@ @[%a@] in@ @[%a@]")
          (print_let_def info) let_def (print_expr info) e;
        forget_let_defn let_def
    | Eabsurd ->
        fprintf fmt (protect_on paren "assert false (* absurd *)")
    | Ehole -> ()
    | Eapp (rs, []) when rs_equal rs rs_true ->
        fprintf fmt "true"
    | Eapp (rs, []) when rs_equal rs rs_false ->
        fprintf fmt "false"
    | Eapp (rs, [])  -> (* avoids parenthesis around values *)
        fprintf fmt "%a" (print_apply info (Hrs.find_def ht_rs rs rs)) []
    | Eapp (rs, pvl) ->
        begin match query_syntax info.info_convert rs.rs_name, pvl with
          | Some s, [{e_node = Econst _}] ->
              syntax_arguments s print_constant fmt pvl
          | _ ->
              fprintf fmt (protect_on paren "%a")
                (print_apply info (Hrs.find_def ht_rs rs rs)) pvl end
    | Ematch (e1, [p, e2], []) ->
        fprintf fmt (protect_on paren "let %a =@ %a in@ %a")
          (print_pat info) p (print_expr info) e1 (print_expr info) e2
    | Ematch (e, [], xl) ->
        fprintf fmt "(@[%a@]@\n@[handle@;<1 0>@[<hov>%a@]@])"
          (print_expr ~paren:true info) e
          (print_list_next newline (print_xbranch false info)) xl
    | Ematch (e, pl, []) ->
        fprintf fmt
          (protect_on paren "(case @[%a@] of@\n@[<hov>%a@])")
          (print_expr info) e (print_list_next newline (print_branch info)) pl
    | Ematch (e, bl, xl) ->
        fprintf fmt
          (protect_on paren "(case @[%a@] of@\n@[<hov>%a@\n%a@])")
          (print_expr info) e (print_list_next newline (print_branch info)) bl
          (print_list_next newline (print_xbranch true info)) xl
    | Eassign al ->
        let assign fmt (rho, rs, pv) =
          fprintf fmt "@[<hov 2>%a.%a <-@ %a@]"
            (print_lident info) (pv_name rho) (print_lident info) rs.rs_name
            (print_lident info) (pv_name pv) in
        begin match al with
          | [] -> assert false | [a] -> assign fmt a
          | al -> fprintf fmt "@[(%a)]" (print_list semi assign) al end
    | Eif (e1, e2, {e_node = Eblock []}) ->
        fprintf fmt
          (protect_on paren
             "@[<hv>@[<hov 2>if@ %a@]@ then (@[%a@])@]")
          (print_expr info) e1 (print_expr info) e2
    | Eif (e1, e2, e3) when is_false e2 && is_true e3 ->
        fprintf fmt (protect_on paren "not %a") (print_expr info ~paren:true) e1
    | Eif (e1, e2, e3) when is_true e2 ->
        fprintf fmt (protect_on paren "@[<hv>%a orelse %a@]")
          (print_expr info ~paren:true) e1 (print_expr info ~paren:true) e3
    | Eif (e1, e2, e3) when is_false e3 ->
        fprintf fmt (protect_on paren "@[<hv>%a andalso %a@]")
          (print_expr info ~paren:true) e1 (print_expr info ~paren:true) e2
    | Eif (e1, e2, e3) ->
        fprintf fmt
          (protect_on paren
             "@[<hv>@[<hov 2>if@ %a@ then@ (@[%a@])@] @;<1 0>else (@[%a@])@]")
          (print_expr info) e1 (print_expr info) e2 (print_expr info) e3
    | Eblock [] ->
        fprintf fmt "()"
    | Eblock [e] ->
        print_expr info fmt e
    | Eblock el ->
        fprintf fmt "@[<hv>(@[%a@])@]" (print_list semi (print_expr info)) el
    | Efun (varl, e) ->
        fprintf fmt (protect_on paren "@[<hov 2>fn %a =>@ %a@]")
          (print_list space (print_vs_arg info)) varl (print_expr info) e
    | Ewhile (e1, e2) ->
        fprintf fmt "@[<hov 2>while %a do@\n%a@ done@]"
          (print_expr info) e1 (print_expr info) e2
    | Eraise (xs, e_opt) ->
        print_raise ~paren info xs fmt e_opt
    | Efor (pv1, pv2, dir, pv3, e) ->
        if is_mapped_to_int info pv1.pv_ity then
          fprintf fmt "@[<hov 2>for %a = %a %a %a do@ @[%a@]@ done@]"
            (print_lident info) (pv_name pv1) (print_lident info) (pv_name pv2)
            print_for_direction dir (print_lident info) (pv_name pv3)
            (print_expr info) e
        else
          let for_id  = id_register (id_fresh "for_loop_to") in
          let cmp, op = match dir with
            | To     -> "<=", "+ 1"
            | DownTo -> ">=", "- 1" in
          fprintf fmt (protect_on paren
                         "@[<hov 2>let rec %a %a =@ if %a %s %a then \
                          (%a; %a (%a %s)) in@ %a %a@]")
          (* let rec *) (print_lident info) for_id (print_pv info) pv1
          (* if      *)  (print_pv info) pv1 cmp (print_pv info) pv3
          (* then    *) (print_expr info) e (print_lident info) for_id
                        (print_pv info) pv1 op
          (* in      *) (print_lident info) for_id (print_pv info) pv2
    | Eexn (xs, None, e) ->
        fprintf fmt "@[<hv>let exception %a in@\n%a@]"
          (print_uident info) xs.xs_name (print_expr info) e
    | Eexn (xs, Some t, e) ->
        fprintf fmt "@[<hv>let exception %a of %a in@\n%a@]"
          (print_uident info) xs.xs_name (print_ty ~paren:true info) t
          (print_expr info) e
    | Eignore e -> fprintf fmt "ignore (%a)" (print_expr info) e

  and print_branch info fst fmt (p, e) =
    fprintf fmt "@[<hov 2>%s %a =>@ @[%a@]@]" (if fst then " " else "|")
      (print_pat info) p (print_expr info) e;
    forget_pat p

  and print_raise ~paren info xs fmt e_opt =
    match query_syntax info.info_syn xs.xs_name, e_opt with
    | Some s, None ->
        fprintf fmt "raise (%s)" s
    | Some s, Some e ->
        fprintf fmt (protect_on paren "raise (%a)")
          (syntax_arguments s (print_expr info)) [e]
    | None, None ->
        fprintf fmt (protect_on paren "raise %a")
          (print_uident info) xs.xs_name
    | None, Some e ->
        fprintf fmt (protect_on paren "raise (%a %a)")
          (print_uident info) xs.xs_name (print_expr ~paren:true info) e

  and print_xbranch case info fst fmt (xs, pvl, e) =
    let print_exn fmt () =
      if case then fprintf fmt "exception " else fprintf fmt "" in
    let print_var fmt pv = print_lident info fmt (pv_name pv) in
    match query_syntax info.info_syn xs.xs_name, pvl with
    | Some s, _ ->
        fprintf fmt "@[<hov 4>%s %a%a =>@ %a@]"
          (if fst then " " else "|")
          print_exn () (syntax_arguments s print_var) pvl
          (print_expr info ~paren:true) e
    | None, [] ->
        fprintf fmt "@[<hov 4>%s %a%a =>@ %a@]"
          (if fst then " " else "|") print_exn () (print_uident info) xs.xs_name
          (print_expr info) e
    | None, [pv] ->
        fprintf fmt "@[<hov 4>%s %a%a %a =>@ %a@]"
          (if fst then " " else "|") print_exn () (print_uident info) xs.xs_name
          print_var pv (print_expr info) e
    | None, pvl ->
        fprintf fmt "@[<hov 4>%s %a%a (%a) =>@ %a@]"
          (if fst then " " else "|") print_exn () (print_uident info) xs.xs_name
          (print_list comma print_var) pvl (print_expr info) e

  let print_type_decl info fmt its =
    let print_constr fst fmt (id, cs_args) =
      match cs_args with
      | [] ->
          fprintf fmt "@[<hov 4>%s %a@]" (if fst then " " else "|")
            (print_uident info) id
      | l ->
          fprintf fmt "@[<hov 4>%s %a of %a@]" (if fst then " " else "|")
            (print_uident info) id
            (print_list star (print_ty ~paren:false info)) l in
    let print_field fmt (is_mutable, id, ty) =
      fprintf fmt "%s%a: %a;" (if is_mutable then "mutable " else "")
        (print_lident info) id (print_ty ~paren:false info) ty in
    let print_def info name fmt = function
      | None ->
          () (* TODO: check if it is in driver *)
      | Some (Ddata csl) ->
          fprintf fmt "datatype %a =@\n%a"
            (print_lident info) name (print_list_next newline print_constr) csl
      | Some (Drecord fl) ->
          fprintf fmt " = %s{@\n%a@\n}"
            (if its.its_private then "private " else "")
            (print_list newline print_field) fl
      | Some (Dalias ty) ->
          fprintf fmt "type %a =@ %a" (print_lident info) name
            (print_ty ~paren:false info) ty
      | Some (Drange _) ->
          fprintf fmt " =@ int"
      | Some (Dfloat _) ->
          assert false (*TODO*) in
    let labels = its.its_name.id_label in
    if not (is_sml_remove ~labels) then
      fprintf fmt "@[<hov 2>@[%a@]@[%a@]@]" print_tv_args its.its_args
        (print_def info its.its_name) its.its_def

  (** Extract declarations defined inside scopes. As CakeML does not support
      nested modules, declarations from internal scopes will be lifted to
      the top-level module *)
  let extract_module_decl dl =
    let rec extract acc = function
      | Dmodule (_, dlx) ->
          List.fold_left extract acc dlx
      | dl -> dl::acc in
    List.rev (List.fold_left extract [] dl)

  let rec print_decl info fmt = function
    | Dlet ldef ->
        print_let_def info fmt ldef
    | Dtype dl ->
        print_list newline (print_type_decl info) fmt dl
    | Dexn (xs, None) ->
        fprintf fmt "exception %a" (print_uident info) xs.xs_name
    | Dexn (xs, Some t)->
        fprintf fmt "@[<hov 2>exception %a of %a@]"
          (print_uident info) xs.xs_name (print_ty ~paren:true info) t
    | Dmodule (s, dl) ->
        let dl = extract_module_decl dl in
        let info = { info with info_current_ph = s :: info.info_current_ph } in
        fprintf fmt "@[@[<hov 2>structure %s@ = struct@]@;<1 2>@[%a@]@ end@]"
          s (print_list newline2 (print_decl info)) dl

  let print_decl info fmt decl =
    (* avoids printing the same decl for mutually recursive decls *)
    let memo = Hashtbl.create 64 in
    let decl_name = get_decl_name decl in
    let decide_print id =
      if query_syntax info.info_syn id = None &&
         not (Hashtbl.mem memo decl) then begin
        Hashtbl.add memo decl (); print_decl info fmt decl;
        fprintf fmt "@\n@." end in
    List.iter decide_print decl_name

end

let print_decl =
  let memo = Hashtbl.create 16 in
  fun pargs ?old ?fname ~flat ({mod_theory = th} as m) fmt d ->
    ignore (old);
    let info = {
      info_syn          = pargs.Pdriver.syntax;
      info_convert      = pargs.Pdriver.converter;
      info_literal      = pargs.Pdriver.literal;
      info_current_th   = th;
      info_current_mo   = Some m;
      info_th_known_map = th.th_known;
      info_mo_known_map = m.mod_known;
      info_fname        = Opt.map Compile.clean_name fname;
      info_flat         = flat;
      info_current_ph   = [];
    } in
    if not (Hashtbl.mem memo d) then begin Hashtbl.add memo d ();
      Print.print_decl info fmt d end

let fg_cml ?fname m =
  let mod_name = m.mod_theory.th_name.id_string in
  let path     = m.mod_theory.th_path in
  (module_name ?fname path mod_name) ^ ".cml"

let () = Pdriver.register_printer "cakeml"
    ~desc:"printer for CakeML code" fg_cml print_decl

let fg_sml ?fname m =
  let mod_name = m.mod_theory.th_name.id_string in
  let path     = m.mod_theory.th_path in
  (module_name ?fname path mod_name) ^ ".sml"

let () = Pdriver.register_printer "sml"
    ~desc:"printer for SML code" fg_sml print_decl