(********************************************************************)
(*                                                                  *)
(*  The Why3 Verification Platform   /   The Why3 Development Team  *)
(*  Copyright 2010-2020   --   Inria - CNRS - Paris-Sud University  *)
(*                                                                  *)
(*  This software is distributed under the terms of the GNU Lesser  *)
(*  General Public License version 2.1, with the special exception  *)
(*  on linking described in file LICENSE.                           *)
(*                                                                  *)
(********************************************************************)

open Why3
open Pmodule
open Cfg_ast
open Ptree

let debug = Debug.register_flag "cfg"
  ~desc:"CFG plugin debug flag"

let mk_id ~loc name =
  { id_str = name; id_ats = []; id_loc = loc }

(*
let infix  ~loc s = Qident (mk_id ~loc (Ident.op_infix s))
let prefix ~loc s = Qident (mk_id ~loc (Ident.op_prefix s))
let get_op ~loc   = Qident (mk_id ~loc (Ident.op_get ""))
let set_op ~loc   = Qident (mk_id ~loc (Ident.op_set ""))
 *)

let mk_expr ~loc d =
  { expr_desc = d; expr_loc = loc }

let mk_pat ~loc d =
  { pat_desc = d; pat_loc = loc }

let pat_wild ~loc = mk_pat ~loc Pwild

(*
let mk_term ~loc d =
  { term_desc = d; term_loc = loc }
let mk_unit ~loc =
  mk_expr ~loc (Etuple [])
let mk_var ~loc id =
  mk_expr ~loc (Eident (Qident id))
let mk_tvar ~loc id =
  mk_term ~loc (Tident (Qident id))
let mk_ref ~loc e =
  mk_expr ~loc (Eidapp (Qident (mk_id ~loc "ref"), [e]))
let array_set ~loc a i v =
  mk_expr ~loc (Eidapp (set_op ~loc, [a; i; v]))
let constant ~loc i =
  mk_expr ~loc (Econst (Constant.int_const_of_int i))
let constant_s ~loc s =
  let int_lit = Number.(int_literal ILitDec ~neg:false s) in
  mk_expr ~loc (Econst (Constant.ConstInt int_lit))
let break ~loc =
  Qident (mk_id ~loc "Break")
let break_handler ~loc =
  [break ~loc, None, mk_unit ~loc]
let return ~loc =
  Qident (mk_id ~loc "Return")
let return_handler ~loc =
  let x = mk_id ~loc "x" in
  [return ~loc, Some (mk_pat ~loc (Pvar x)), mk_var ~loc x]
let array_id ~loc id = Qdot (Qident (mk_id ~loc "Array"), id)
let array_make ~loc n v =
  mk_expr ~loc (Eidapp (array_id ~loc (mk_id ~loc "make"),
                        [n; v]))
let set_ref id =
  { id with id_ats = ATstr Pmodule.ref_attr :: id.id_ats }

 *)

let empty_spec = {
  sp_pre     = [];
  sp_post    = [];
  sp_xpost   = [];
  sp_reads   = [];
  sp_writes  = [];
  sp_alias   = [];
  sp_variant = [];
  sp_checkrw = false;
  sp_diverge = false;
  sp_partial = false;
}

               (*
type env = {
  vars: ident Mstr.t;
  for_index: int;
}

let empty_env =
  { vars = Mstr.empty;
    for_index = 0; }

let add_var env (_, id) =
  { env with vars = Mstr.add id.id_str id env.vars }

let for_vars ~loc env =
  let i = env.for_index in
  let env = { env with for_index = i + 1 } in
  let i = string_of_int env.for_index in
  mk_id ~loc ("for index " ^ i ), mk_id ~loc ("for list " ^ i), env

let rec has_stmt p s =
  p s || begin match s.stmt_desc with
    | Sskip | Sbreak  | Sreturn _ | Svar _ | Sassign _ | Slabel _
    | Seval _ | Sset _ | Sassert _ -> false
    | Sif (_, s1, s2) -> has_stmt p s1 || has_stmt p s2
    | Swhile (_, _, s) -> has_stmt p s
    | Sblock sl -> has_stmtl p sl end
and has_stmtl p bl = List.exists (has_stmt p) bl

let has_break = has_stmt (fun s -> s.stmt_desc = Sbreak)
let has_return = has_stmt (function { stmt_desc = Sreturn _ } -> true | _ -> false)

let rec expr_has_call id e = match e.Mc_ast.expr_desc with
  | Eunit | Eint _ | Estring _ | Eaddr _ | Mc_ast.Eident _ -> false
  | Eget (e1, e2) | Ebinop (_, e1, e2) ->
    expr_has_call id e1 || expr_has_call id e2
  | Eunop (_, e1) -> expr_has_call id e1
  | Ecall (f, el) -> id.id_str = f.id_str || List.exists (expr_has_call id) el

let rec stmt_has_call id s = match s.stmt_desc with
  | Sskip | Sbreak | Slabel _ | Sassert _ -> false
  | Sreturn e | Svar (_, _, e) | Sassign (_, e) | Seval e -> expr_has_call id e
  | Sset (e1, e2, e3) ->
    expr_has_call id e1 || expr_has_call id e2 || expr_has_call id e3
  | Sif (e, s1, s2) -> expr_has_call id e || stmt_has_call id s1 || stmt_has_call id s2
  | Swhile (e, _, s) -> expr_has_call id e || stmt_has_call id s
  | Sblock bl -> block_has_call id bl
and block_has_call id = has_stmtl (stmt_has_call id)

let rec expr env ({Mc_ast.expr_loc = loc; Mc_ast.expr_desc = d } as e) =
  match d with
  | Mc_ast.Eunit ->
    mk_unit ~loc
  | Mc_ast.Eint s ->
    constant_s ~loc s
  | Mc_ast.Estring _s ->
    mk_unit ~loc (*FIXME*)
  | Mc_ast.Eaddr id | Mc_ast.Eident id
    when not (Mstr.mem id.id_str env.vars) ->
     Loc.errorm ~loc "unbound variable %s" id.id_str
  | Mc_ast.Eaddr id ->
     mk_expr ~loc (Eident (Qident id))
  | Mc_ast.Eident id ->
    if not (Mstr.mem id.id_str env.vars) then
      Loc.errorm ~loc "unbound variable %s" id.id_str;
    mk_expr ~loc (Eident (Qident id))
  | Mc_ast.Ebinop (Mc_ast.Badd | Mc_ast.Bsub | Mc_ast.Bmul |
                   Mc_ast.Bdiv | Mc_ast.Bmod as op, e1, e2) ->
    let e1 = expr env e1 in
    let e2 = expr env e2 in
    mk_expr ~loc (match op with
      | Mc_ast.Badd -> Eidapp (infix ~loc "+", [e1; e2])
      | Mc_ast.Bsub -> Eidapp (infix ~loc "-", [e1; e2])
      | Mc_ast.Bmul -> Eidapp (infix ~loc "*", [e1; e2])
      | Mc_ast.Bdiv -> Eidapp (infix ~loc "/", [e1; e2])
      | Mc_ast.Bmod -> Eidapp (infix ~loc "%", [e1; e2])
      | _ -> assert false)
  | Mc_ast.Ebinop _ | Mc_ast.Eunop (Mc_ast.Unot, _) ->
     mk_expr ~loc (Eif (bool env e, constant ~loc 1, constant ~loc 0))
  | Mc_ast.Eunop (Mc_ast.Uneg, e) ->
    mk_expr ~loc (Eidapp (prefix ~loc "-", [expr env e]))
  | Mc_ast.Ecall ({id_str = "printf"}, el) ->
     let el = match el with
       | {Mc_ast.expr_desc=Estring _} :: el -> el
       | _ :: _ -> Loc.errorm ~loc "first argument of printf must be a string"
       | [] -> Loc.errorm ~loc "two few arguments to function printf" in
    let eval res e =
      mk_expr ~loc
        (Elet (mk_id ~loc "_", false, Expr.RKnone, expr env e, res)) in
    List.fold_left eval (mk_unit ~loc) el
  | Mc_ast.Ecall (id, el) ->
     let el = if el = [] then [mk_unit ~loc] else List.map (expr env) el in
     mk_expr ~loc (Eidapp (Qident id, el))
  | Mc_ast.Eget (e1, e2) ->
    mk_expr ~loc (Eidapp (get_op ~loc, [expr env e1; expr env e2]))

and bool env ({Mc_ast.expr_loc = loc; Mc_ast.expr_desc = d } as e) =
  match d with
  | Mc_ast.Ebinop (Mc_ast.Band | Mc_ast.Bor as op, e1, e2) ->
    let e1 = bool env e1 in
    let e2 = bool env e2 in
    mk_expr ~loc (match op with
      | Mc_ast.Band -> Eand (e1, e2)
      | Mc_ast.Bor  -> Eor  (e1, e2)
      | _ -> assert false)
  | Mc_ast.Ebinop (Mc_ast.Beq | Mc_ast.Bneq | Mc_ast.Blt |
                   Mc_ast.Ble | Mc_ast.Bgt | Mc_ast.Bge as op, e1, e2) ->
    let e1 = expr env e1 in
    let e2 = expr env e2 in
    mk_expr ~loc (match op with
      | Mc_ast.Beq  -> Eidapp (infix ~loc "=", [e1; e2])
      | Mc_ast.Bneq ->
         Enot (mk_expr ~loc (Eidapp (infix ~loc "=", [e1; e2])))
      | Mc_ast.Blt  -> Eidapp (infix ~loc "<", [e1; e2])
      | Mc_ast.Ble  -> Eidapp (infix ~loc "<=", [e1; e2])
      | Mc_ast.Bgt  -> Eidapp (infix ~loc ">", [e1; e2])
      | Mc_ast.Bge  -> Eidapp (infix ~loc ">=", [e1; e2])
      | _ -> assert false)
  | Mc_ast.Eunop (Mc_ast.Unot, e) ->
    mk_expr ~loc (Eidapp (Qident (mk_id ~loc "not"), [bool env e]))
  | _ ->
     let e = Eidapp (infix ~loc "=", [expr env e; constant ~loc 0]) in
     mk_expr ~loc (Enot (mk_expr ~loc e))

let no_params ~loc = [loc, None, false, Some (PTtuple [])]

let rec stmt env ({Mc_ast.stmt_loc = loc; Mc_ast.stmt_desc = d } as s) =
  match d with
  | Mc_ast.Sskip ->
    mk_unit ~loc
  | Mc_ast.Seval e ->
     let dummy = mk_id ~loc "_" in
     mk_expr ~loc (Elet (dummy, false, Expr.RKnone, expr env e, mk_unit ~loc))
  | Mc_ast.Sif (e, s1, s2) ->
    mk_expr ~loc (Eif (bool env e, stmt env s1, stmt env s2))
  | Mc_ast.Sreturn e ->
    mk_expr ~loc (Eraise (return ~loc, Some (expr env e)))
  | Mc_ast.Svar _ ->
     assert false
  | Mc_ast.Sassign (id, e) ->
    let e = expr env e in
    if Mstr.mem id.id_str env.vars then
      let x = let loc = id.id_loc in mk_expr ~loc (Eident (Qident id)) in
      mk_expr ~loc (Einfix (x, mk_id ~loc (Ident.op_infix ":="), e))
    else
      block env ~loc [s]
  | Mc_ast.Sset (e1, e2, e3) ->
    array_set ~loc (expr env e1) (expr env e2) (expr env e3)
  | Mc_ast.Sassert (k, t) ->
    mk_expr ~loc (Eassert (k, t))
  | Mc_ast.Swhile (e, (inv, var), s) ->
    let loop = mk_expr ~loc
      (Ewhile (bool env e, inv, var, stmt env s)) in
    if has_break s then mk_expr ~loc (Ematch (loop, [], break_handler ~loc))
    else loop
  | Mc_ast.Sbreak ->
    mk_expr ~loc (Eraise (break ~loc, None))
  | Mc_ast.Slabel _ ->
    mk_unit ~loc (* ignore lonely marks *)
  | Mc_ast.Sblock bl ->
     block env ~loc bl

and block env ~loc = function
  | [] ->
    mk_unit ~loc
  | { stmt_loc = loc; stmt_desc = Slabel id } :: sl ->
    mk_expr ~loc (Elabel (id, block env ~loc sl))
  | { Mc_ast.stmt_loc = loc; stmt_desc = Mc_ast.Svar (ty, id, e) } :: sl ->
    let e = expr env e in (* check e *before* adding id to environment *)
    let env = add_var env (ty, id) in
    let ee = mk_ref ~loc e in
    mk_expr ~loc (Elet (set_ref id, false, Expr.RKnone, ee, block env ~loc sl))
  | ({ Mc_ast.stmt_loc = loc } as s) :: sl ->
    let s = stmt env s in
    if sl = [] then s else mk_expr ~loc (Esequence (s, block env ~loc sl))

let fresh_type_var =
  let r = ref 0 in
  fun loc -> incr r;
  PTtyvar { id_str = "a" ^ string_of_int !r; id_loc = loc; id_ats = [] }
                *)

let type_unit loc = PTtyapp (Qident (mk_id ~loc "unit"), [])
let type_int loc = PTtyapp (Qident (mk_id ~loc "int"), [])

let ref_module ~loc id = Qdot (Qident (mk_id ~loc "Ref"), id)
let ref_type ~loc ty = PTtyapp (ref_module ~loc (mk_id ~loc "ref"), [ty])
(*
let type_array loc ty = PTtyapp (array_id ~loc (mk_id ~loc "array"), [ty])
 *)

(*
let type_ loc = function
  | Tvoid -> type_unit loc
  | Tint -> type_int loc
  | Tarray -> type_array loc (type_int loc)

let logic_param (ty, id) =
  id.id_loc, Some id, false, type_ id.id_loc ty

let decl = function
  | Mc_ast.Dinclude _ ->
     ()
  | Mc_ast.Dfun (ty, id, idl, sp, bl) ->
    (* f(x1,...,xn): body ==>
      let f x1 ... xn =
        let x1 = ref x1 in ... let xn = ref xn in
        try body with Return x -> x *)
    let loc = id.id_loc in
    let rty = type_ loc ty in
    let env' = List.fold_left add_var empty_env idl in
    let body = stmt env' bl in
    let body =
      if not (has_return bl) then begin
        if ty <> Tvoid then Loc.errorm ~loc "missing return";
        body end else
      mk_expr ~loc (Ematch (body, [], return_handler ~loc)) in
    let local bl = function
      | Tint, id ->
        let loc = id.id_loc in
        let ref = mk_ref ~loc (mk_var ~loc id) in
        mk_expr ~loc (Elet (set_ref id, false, Expr.RKnone, ref, bl))
      | Tarray, _ -> bl
      | Tvoid, _ -> assert false in
    let body = List.fold_left local body idl in
    let param (ty, id) =
      id.id_loc, Some id, false, Some (type_ id.id_loc ty) in
    let params = if idl = [] then no_params ~loc else List.map param idl in
    let p = mk_pat ~loc Pwild in
    let d = if stmt_has_call id bl then
      Drec ([id, false, Expr.RKnone, params, Some rty,
             p, Ity.MaskVisible, sp, body])
    else
      let e = Efun (params, Some rty, p, Ity.MaskVisible, sp, body) in
      Dlet (id, false, Expr.RKnone, mk_expr ~loc e) in
    Typing.add_decl loc d
  | Mc_ast.Dlogic (ty, id, idl, def) ->
    let d = { ld_loc = id.id_loc;
              ld_ident = id;
              ld_params = List.map logic_param idl;
              ld_type = Opt.map (type_ id.id_loc) ty;
              ld_def = def } in
    Typing.add_decl id.id_loc (Dlogic [d])
  | Mc_ast.Dprop (pk, id, t) ->
     Typing.add_decl id.id_loc (Dprop (pk, id, t))
 *)


let pp_id fmt id =
  Format.fprintf fmt "%s" id.id_str

let rec pp_qid fmt qid =
  match qid with
  | Qident id -> pp_id fmt id
  | Qdot(q,id) -> Format.fprintf fmt "%a.%a" pp_qid q pp_id id

let rec pp_pty fmt t =
  match t with
  | PTtyapp(qid,l) ->
     Format.fprintf fmt "@[%a %a@]"
       pp_qid qid
       (Pp.print_list Pp.semi pp_pty) l
  | _ ->
     Format.fprintf fmt "@[<pp_pty>@]"

(*
let translate_expr e =
  let loc = e.cfg_expr_loc in
  match e.cfg_expr_desc with
  | CFGtrue -> mk_expr loc Etrue
  | CFGfalse -> mk_expr loc Efalse
  | CFGconst c -> mk_expr loc (Econst c)
 *)

let translate_instr e =
  let loc = e.cfg_instr_loc in
  match e.cfg_instr_desc with
(*
  | CFGassert(k,t) -> mk_expr loc (Eassert(k,t))
  | CFGassign(id,e) ->  mk_expr loc (Etuple [])
 *)
  | CFGgoto _id -> mk_expr ~loc (Etuple [])
  | CFGswitch _ -> mk_expr ~loc (Etuple [])
  | CFGinvariant (id,t) ->
     let attr = ATstr (Ident.create_attribute ("hyp_name:" ^ id.id_str)) in
     let t = { t with term_desc = Tattr(attr,t) } in
     mk_expr ~loc (Eassert(Expr.Assert,t))
  | CFGexpr e -> e

let translate_cfg preconds block blocks =
  let blocks =
    List.fold_left
      (fun acc (l,b) -> Wstdlib.Mstr.add l.id_str b acc)
      Wstdlib.Mstr.empty
      blocks
  in
  let visited = ref [] in
  let rec traverse startlabel preconds bl acc (funs,ret_funs) =
    match bl with
    | [] -> assert false
    | i :: rem ->
       match i.cfg_instr_desc with
       | CFGgoto l ->
          let bl =
            try
              Wstdlib.Mstr.find l.id_str blocks
            with Not_found -> Format.eprintf "Label %a not found for goto@." pp_id l; exit 1
          in
          traverse startlabel preconds bl acc (funs,ret_funs)
       | CFGinvariant(id,t) ->
          let funs = (startlabel, preconds, id, t, acc) :: funs in
          traverse id.id_str [t] rem [] (funs,ret_funs)
       | CFGswitch _ ->
          failwith "switch not suported yet"
       | CFGexpr e when rem=[] ->
          let ret_funs = (startlabel, e, acc) :: ret_funs in
          (funs, ret_funs)
       | CFGexpr e ->
          traverse startlabel preconds rem (e::acc) (funs,ret_funs)
  in
  traverse "start" preconds block [] ([],[])

let e_ref = mk_expr ~loc:Loc.dummy_position Eref

let declare_local (loc,idopt,ghost,tyopt) body =
  match idopt, tyopt with
  | Some id, Some ty ->
     Debug.dprintf debug "declaring local variable %a of type %a@." pp_id id pp_pty ty ;
     let e = Eany([],Expr.RKnone,tyopt,pat_wild ~loc,Ity.MaskVisible,empty_spec) in
     let e = mk_expr ~loc (Eapply(e_ref,mk_expr ~loc e)) in
     let id = { id with id_ats = (ATstr Pmodule.ref_attr) :: id.id_ats } in
     mk_expr ~loc:id.id_loc (Elet(id,ghost,Expr.RKnone,e,body))
  | _ -> failwith "invalid variable declaration"


let build_path_function (startlabel, preconds, id , t, revbody) acc =
  let attr = ATstr (Ident.create_attribute ("hyp_name:" ^ id.id_str)) in
  (* TODO : add also an "expl:" *)
  let t = { t with term_desc = Tattr(attr,t) } in
  let e = mk_expr ~loc:id.id_loc (Eassert(Expr.Assert,t)) in
  let body =
    List.fold_left
      (fun acc e -> mk_expr ~loc:e.expr_loc (Esequence (e, acc)))
      e revbody
  in
  let body =
    List.fold_left
      (fun acc t ->
        let e = mk_expr ~loc:t.term_loc (Eassert(Expr.Assume,t)) in
        mk_expr ~loc:acc.expr_loc (Esequence (e, acc)))
      body preconds
  in
  let f =
    Efun([], None, pat_wild ~loc:Loc.dummy_position, Ity.MaskVisible, empty_spec, body)
  in
  let loc = Loc.dummy_position in
  let id = mk_id ~loc ("_" ^ startlabel ^ "_to_" ^ id.id_str) in
  mk_expr ~loc (Elet (id,false,Expr.RKnone, mk_expr ~loc f, acc))

let build_return_function retty pat spec (startlabel, e, revbody) acc =
  let body =
    List.fold_left
      (fun acc e -> mk_expr ~loc:e.expr_loc (Esequence (e, acc)))
      e revbody
  in
  let f =
    Efun([], Some retty, pat, Ity.MaskVisible, spec, body)
  in
  let loc = Loc.dummy_position in
  let id = mk_id ~loc ("_" ^ startlabel ^ "_to_return") in
  mk_expr ~loc (Elet (id,false,Expr.RKnone, mk_expr ~loc f, acc))


let translate_letcfg (id,args,retty,pat,spec,locals,block,blocks) =
  Debug.dprintf debug "translating cfg function `%s`@." id.id_str;
  Debug.dprintf debug "return type is `%a`@." pp_pty retty;
  let (funs,ret_funs) = translate_cfg spec.sp_pre block blocks in
  let loc = Loc.dummy_position in
  let body = Eany([],Expr.RKnone,Some retty,pat,Ity.MaskVisible,spec) in
  let body =
    List.fold_right (build_return_function retty pat spec) ret_funs
      (mk_expr ~loc body)
  in
  let body =
    List.fold_right build_path_function funs body
  in
  let body =
    List.fold_right declare_local locals body
  in
  let f =
    Efun(args, Some retty, pat, Ity.MaskVisible, spec, body)
  in
  Dlet (id,false,Expr.RKnone,mk_expr ~loc:id.id_loc f)

let translate_decl d acc =
  match d with
  | Dmlw_decl d -> d :: acc
  | Dletcfg l -> List.fold_right (fun d acc -> (translate_letcfg d)::acc) l acc

let translate (m,dl) =
  (m,List.fold_right translate_decl dl [])

let read_channel env _path file c =
  let f : Cfg_ast.cfg_file =
    try
      Cfg_lexer.parse_channel file c
    with Loc.Located(loc,e) ->
      Format.eprintf "%a%a@." Loc.report_position loc Exn_printer.exn_printer e;
      exit 1
  in
  Debug.dprintf debug "%s parsed successfully.@." file;
  let ptree = Modules (List.map translate f) in
  let mm = try
      Typing.type_mlw_file env [] (file ^ ".mlw") ptree
    with
      Loc.Located(loc,e) ->
      let msg = Format.asprintf "%a" Exn_printer.exn_printer e in
      Format.eprintf "%a%s@." Loc.report_position loc msg;
      Debug.dprintf debug "%a@."
        (Mlw_printer.with_marker ~msg loc Mlw_printer.pp_mlw_file)
        ptree;
      exit 1
  in
  Debug.dprintf debug "%a@." Mlw_printer.pp_mlw_file ptree;
  mm

let () =
  Env.register_format mlw_language "mlcfg" ["mlcfg"] read_channel
    ~desc:"whyml extending with functions implemented by control-flow-graphs"
