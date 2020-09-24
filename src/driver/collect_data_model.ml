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

open Wstdlib
open Printer
open Model_parser
open Smtv2_model_defs

exception Not_value

let debug_cntex = Debug.register_flag "cntex_collection"
    ~desc:"Intermediate representation debugging for counterexamples"

(** Intermediate data structure for propagations of tree projections inside
    counterexamples.
*)

type projection_name = string

module Mpr: Extmap.S with type key = projection_name = Mstr

type tree_variable =
  | Tree of tree
  | Tree_var of string

and tarray =
  | TArray_var of variable
  | TConst of tterm
  | TStore of tarray * tterm * tterm

and tterm =
  | TSval of model_value
  | TApply of (string * tterm list)
  | TArray of tarray
  | TVar of variable
  | TFunction_var of variable
  | TProver_var of tree_variable
  | TIte of tterm * tterm * tterm * tterm
  | TRecord of string * ((string * tterm) list)
  | TTo_array of tterm

and tree_definition =
  | TFunction of (variable * string option) list * tterm
  | TTerm of tterm
  | TNoelement

and tree =
  | Node of tree Mpr.t
  | Leaf of tree_definition

(* correpondence_table = map from var_name to tree representing its definition:
   Initially all var name begins with its original definition which is then
   refined using projections (that are saved in the tree) *)
type correspondence_table = tree Mstr.t

let rec print_array fmt a =
  match a with
  | TArray_var v -> Format.fprintf fmt "ARRAY_VAR : %s" v
  | TConst t -> Format.fprintf fmt "CONST : %a" print_term t
  | TStore (a, t1, t2) ->
      Format.fprintf fmt "STORE : %a %a %a"
        print_array a print_term t1 print_term t2

(* Printing function for terms *)
and print_term fmt t =
  match t with
  | TSval v -> print_model_value fmt v
  | TApply (s, lt) ->
      Format.fprintf fmt "Apply: (%s, %a)" s
        (Pp.print_list_delim ~start:Pp.lsquare ~stop:Pp.rsquare ~sep:Pp.comma print_term)
        lt
  | TArray a -> Format.fprintf fmt "Array: %a" print_array a
  | TProver_var (Tree_var v) -> Format.fprintf fmt "PROVERVAR: %s" v
  | TProver_var _ -> Format.fprintf fmt "PROVERVAR: TREE"
  | TFunction_var v -> Format.fprintf fmt "LOCAL: %s" v
  | TVar v -> Format.fprintf fmt "VAR: %s" v
  | TIte (teq1, teq2, tthen, telse) ->
      Format.fprintf fmt "ITE (%a = %a) then %a else %a"
        print_term teq1 print_term teq2 print_term tthen print_term telse
  | TRecord (n, l) ->
      Format.fprintf fmt "record_type: %s; list_fields: %a" n
        (Pp.print_list Pp.semi
           (fun fmt (x, a) -> Format.fprintf fmt "(%s, %a)" x print_term a))
        l
  | TTo_array t -> Format.fprintf fmt "TO_array: %a@." print_term t

let print_def fmt d =
  match d with
  | TFunction (_vars, t) -> Format.fprintf fmt "FUNCTION : %a" print_term t
  | TTerm t -> Format.fprintf fmt "TERM : %a" print_term t
  | TNoelement -> Format.fprintf fmt "NOELEMENT"

let rec print_tree fmt t =
  match t with
  | Node mpt -> Format.fprintf fmt "NODE : [%a]" print_mpt mpt
  | Leaf td -> Format.fprintf fmt "LEAF: %a" print_def td

and print_mpt fmt t =
  Mpr.iter (fun key e -> Format.fprintf fmt "P: %s; T: %a" key print_tree e) t

let subst_local_var var value t =
  let rec aux t =
    match t with
    | TFunction_var var' when var' = var ->
        value
    | TFunction_var _ | TVar _ | TProver_var _ | TSval _ ->
        t
    | TApply (s, args) ->
        TApply (s, List.map aux args)
    | TIte (t1, t2, t3, t4) ->
        TIte (aux t1, aux t2, aux t3, aux t4)
    | TArray tarray ->
        TArray (aux_array tarray)
    | TRecord (s, fields) ->
        let aux_field (s, t) = (s, aux t) in
        TRecord (s, List.map aux_field fields)
    | TTo_array t ->
        TTo_array (aux t)
  and aux_array a =
    match a with
    | TArray_var _ ->
        a
    | TConst t ->
        TConst (aux t)
    | TStore (a, t1, t2) ->
        TStore (aux_array a, aux t1, aux t2) in
  aux t

(* Printing function for debugging *)
let print_table (t: correspondence_table) =
  Debug.dprintf debug_cntex "Correspondence table key and value@.";
  Mstr.iter (fun key t ->
      Debug.dprintf debug_cntex "%s %a@." key print_tree t)
    t;
  Debug.dprintf debug_cntex "End table@."

let rec collect_prover_vars_term = function
  | Prover_var v -> Sstr.singleton v
  | Sval _ | Var _ | Function_var _ -> Sstr.empty
  | Array a -> collect_prover_vars_array a
  | Ite (t1, t2, t3, t4) ->
      let ss = List.map collect_prover_vars_term [t1; t2; t3; t4] in
      List.fold_right Sstr.union ss Sstr.empty
  | Record (_, fs) ->
      let ss = List.map collect_prover_vars_term (List.map snd fs) in
      List.fold_right Sstr.union ss Sstr.empty
  | To_array t -> collect_prover_vars_term t
  | Apply (_, ts) ->
      let ss = List.map collect_prover_vars_term ts in
      List.fold_right Sstr.union ss Sstr.empty
  | Trees _ -> assert false (* Does not exist at this moment *)

and collect_prover_vars_array = function
  | Avar _ -> Sstr.empty
  | Aconst t -> collect_prover_vars_term t
  | Astore (a, t1, t2) ->
      List.fold_left Sstr.union (collect_prover_vars_array a)
        (List.map collect_prover_vars_term [t1; t2])

let collect_prover_vars = function
  | Noelement -> Sstr.empty
  | Function (_, t) | Term t ->
      collect_prover_vars_term t

exception Bad_variable

(* Get the "radical" of a variable *)
let remove_end_num s =
  let n = ref (String.length s - 1) in
  if !n <= 0 then s else
  begin
    while String.get s !n <= '9' && String.get s !n >= '0' && !n >= 0 do
      n := !n - 1
    done;
    try
      String.sub s 0 (!n + 1)
    with
    | _ -> s
  end

(* Used to handle case of badly formed table *)
exception Incorrect_table

(* Simplify if-then-else in value so that it can be read by
   add_vars_to_table. *)
let rec simplify_value table v =
  match v with
  | TApply (s, args') ->
      let vars, body = (* Function binding for s *)
        match Mstr.find s table with
        | Leaf (TFunction (vars, body)) -> vars, body
        | _ -> raise Incorrect_table
        | exception Not_found -> raise Incorrect_table in
      let vars = List.map fst vars in
      let args = List.map (simplify_value table) args' in
      List.fold_right2 subst_local_var vars args body |>
      simplify_value table
  | TIte (
      TIte (TFunction_var x,
            TProver_var cvc,
            TProver_var cvc1,
            _),
      TProver_var cvc2,
      tth,
      tel) when cvc = cvc1 && cvc = cvc2 ->
      (* Here we chose what we keep from the model. This case is not complete
         but good enough. *)
      let t = TIte (TFunction_var x, TProver_var cvc, tth, tel) in
      simplify_value table t
  | TIte (
      TIte (TProver_var cvc,
            TFunction_var x,
            TProver_var cvc1,
            _),
      TProver_var cvc2,
      tth,
      tel) when cvc = cvc1 && cvc = cvc2 (* Same as above *) ->
      (* Here we chose what we keep from the model. This case is not complete
         but good enough. *)
      let t = TIte (TFunction_var x, TProver_var cvc, tth, tel) in
      simplify_value table t
  | TIte (
      TIte (TFunction_var x,
            TProver_var cvc,
            TProver_var cvc1,
            TProver_var cvc3),
      TProver_var cvc2,
      tth,
      tel) when cvc = cvc1 && cvc <> cvc2 && cvc3 = cvc2 ->
      (* Here we chose what we keep from the model. This case is not complete
         but good enough. *)
      let t = TIte (TFunction_var x, TProver_var cvc3, tth, tel) in
      simplify_value table t
  | TIte (
      TIte (TProver_var cvc,
            TFunction_var x,
            TProver_var cvc1,
            TProver_var cvc3),
      TProver_var cvc2,
      tth,
      tel) when cvc = cvc1 && cvc <> cvc2 && cvc3 = cvc2 (* Same as above *) ->
      (* Here we chose what we keep from the model. This case is not complete
         but good enough. *)
      let t = TIte (TFunction_var x, TProver_var cvc3, tth, tel) in
      simplify_value table t
  | TIte (eq1, eq2, tthen, telse) ->
      TIte (eq1, eq2, simplify_value table tthen, simplify_value table telse)
  | _ -> v

(* Add the variables that can be deduced from ITE to the table of variables *)
let add_vars_to_table key value (table: correspondence_table) : correspondence_table =

  let rec add_vars_to_table ~type_value (table: correspondence_table) value =

    let add_var_ite cvc t1 table : correspondence_table =
      let t1 = Leaf (TTerm t1) in
      match Mstr.find cvc table with
      | Node tree ->
          if Mpr.mem key tree then
            raise Incorrect_table
          else
            let new_tree = Node (Mpr.add key t1 tree) in
            Mstr.add cvc new_tree table
      | Leaf TNoelement ->
          Mstr.add cvc (Node (Mpr.add key t1 Mpr.empty)) table
      | Leaf _ ->
          raise Incorrect_table
      | exception Not_found ->
          Mstr.add cvc (Node (Mpr.add key t1 Mpr.empty)) table
    in

    let value = simplify_value table value in
    match value with
    | TIte (TProver_var (Tree_var cvc), TFunction_var _x, t1, t2) ->
        let table = add_var_ite cvc t1 table in
        add_vars_to_table ~type_value table t2
    | TIte (TFunction_var _x, TProver_var (Tree_var cvc), t1, t2) ->
        let table = add_var_ite cvc t1 table in
        add_vars_to_table ~type_value table t2
    | TIte (t, TFunction_var _x, TProver_var (Tree_var cvc), t2) ->
        let table = add_var_ite cvc t table in
        add_vars_to_table ~type_value table t2
    | TIte (TFunction_var _x, t, TProver_var (Tree_var cvc), t2) ->
        let table = add_var_ite cvc t table in
        add_vars_to_table ~type_value table t2
    | TIte _ -> table
    | _ ->
      begin
        match type_value with
        | None -> table
        | Some type_value ->
            Mstr.fold (fun key_val l_elt acc ->
              let match_str_z3 = type_value ^ "!" in
              let match_str_cvc4 = "_" ^ type_value ^ "_" in
              let match_str = Re.Str.regexp ("\\(" ^ match_str_z3 ^ "\\|" ^ match_str_cvc4 ^ "\\)") in
              match Re.Str.search_forward match_str (remove_end_num key_val) 0 with
              | exception Not_found -> acc
              | _ ->
                  if l_elt = Leaf TNoelement then
                    Mstr.add key_val (Node (Mpr.add key (Leaf (TTerm value)) Mpr.empty)) acc
                  else
                    begin match l_elt with
                      | Node mpt ->
                          (* We always prefer explicit assignment to default
                             type assignment. *)
                          if Mpr.mem key mpt then
                            acc
                          else
                            Mstr.add key_val (Node (Mpr.add key (Leaf (TTerm value)) mpt)) acc
                      | _ -> acc
                    end
              )
              table table
      end
  in

  let type_value, t = match value with
  | TTerm t -> (None, t)
  | TFunction (cvc_var_list, t) ->
    begin
      match cvc_var_list with
      | [(_, type_value)] -> (type_value, t)
      | _ -> (None, t)
    end
  | TNoelement -> raise Bad_variable in

  try add_vars_to_table ~type_value table t
  with Incorrect_table ->
    Debug.dprintf debug_cntex "Badly formed table@.";
    table

let rec refine_definition ~enc (table: correspondence_table) t =
  match t with
  | TTerm t -> TTerm (refine_function ~enc table t)
  | TFunction (vars, t) -> TFunction (vars, refine_function ~enc table t)
  | TNoelement -> TNoelement

and refine_array ~enc table a =
  match a with
  | TArray_var _v -> a
  | TConst t ->
    let t = refine_function ~enc table t in
    TConst t
  | TStore (a, t1, t2) ->
    let a = refine_array ~enc table a in
    let t1 = refine_function ~enc table t1 in
    let t2 = refine_function ~enc table t2 in
    TStore (a, t1, t2)

(* This function takes the table of assigned variables and a term and replace
   the variables with the constant associated with them in the table. If their
   value is not a constant yet, recursively apply on these variables and update
   their value. *)
and refine_function ~enc (table: correspondence_table) (term: tterm) =
  match term with
  | TSval _ -> term
  | TProver_var (Tree_var v) -> begin
        try (
          let tree = Mstr.find v table in
          (* Here, it is very *important* to have [enc] so that we don't go in
             circles: remember that we cannot make any assumptions on the result
             prover.
             There has been cases where projections were legitimately circularly
             defined
          *)
          if Hstr.mem enc v then
            TProver_var (Tree tree)
          else
            let () = Hstr.add enc v () in
            let table = refine_variable_value ~enc table v tree in
            let tree = Mstr.find v table in
            TProver_var (Tree tree)
        )
      with
      | Not_found -> term
      | Not_value -> term
    end
  | TProver_var (Tree t) ->
      let t = refine_tree ~enc table t in
      TProver_var (Tree t)
  | TFunction_var _ -> term
  | TVar _ -> term
  | TIte (t1, t2, t3, t4) ->
    let t1 = refine_function ~enc table t1 in
    let t2 = refine_function ~enc table t2 in
    let t3 = refine_function ~enc table t3 in
    let t4 = refine_function ~enc table t4 in
    TIte (t1, t2, t3, t4)
  | TArray a ->
    TArray (refine_array ~enc table a)
  | TRecord (n, l) ->
    TRecord (n, List.map (fun (f, v) -> f, refine_function ~enc table v) l)
  | TTo_array t ->
    TTo_array (refine_function ~enc table t)
  | TApply (s1, lt) ->
    TApply (s1, List.map (refine_function ~enc table) lt)

and refine_tree ~enc table t =
  match t with
  | Leaf t -> Leaf (refine_definition ~enc table t)
  | Node mpr -> Node (Mpr.map (fun x -> refine_tree ~enc table x) mpr)

and refine_variable_value ~enc (table: correspondence_table) key (t: tree) : correspondence_table =
  let t = refine_tree ~enc table t in
  Mstr.add key t table

(* TODO in the future, we should keep the table that is built at each call of
   this to populate the acc where its called. Because what we do here is
   inefficient. ie we calculate the value of constants several time during
   propagation without saving it: this is currently ok as counterexamples
   parsing is *not* notably taking time/memory *)
let refine_variable_value key t table =
  let encountered_key = Hstr.create 16 in
  refine_variable_value ~enc:encountered_key table key t

(* In the following lf is the list of fields. It is used to differentiate
   projections from fields so that projections cannot be reconstructed into a
   record. *)
let rec convert_array_value lf (a: array) : Model_parser.model_array =
  let array_indices = ref [] in

  let rec create_array_value a =
    match a with
    | Avar _v -> raise Not_value
    | Aconst t -> {
        Model_parser.arr_indices = !array_indices;
        Model_parser.arr_others = convert_to_model_value lf t;
      }
    | Astore (a, t1, t2) ->
        let new_index = {
          Model_parser.arr_index_key = convert_to_model_value lf t1;
          Model_parser.arr_index_value = convert_to_model_value lf t2;
        } in
        array_indices := new_index :: !array_indices;
        create_array_value a in
  create_array_value a

and convert_to_model_value lf (t: term): Model_parser.model_value =
  match t with
  | Sval (Unparsed _) -> raise Not_value
  | Sval v -> v
  | Array a -> Model_parser.Array (convert_array_value lf a)
  | Record (_n, l) ->
      Model_parser.Record (convert_record lf l)
  | Trees tree ->
      begin match tree with
      | [] -> raise Not_value
      | [field, value] ->
          Model_parser.Proj (field, convert_to_model_value lf value)
      | l ->
          if List.for_all (fun x -> Mstr.mem (fst x) lf) l then
            Model_parser.Record
              (List.map (fun (field, value) ->
                   let model_value = convert_to_model_value lf value in
                   (field, model_value))
                  l)
          else
            let (proj_name, proj_value) = List.hd l in
            Model_parser.Proj (proj_name, convert_to_model_value lf proj_value)
      end
  | Prover_var _v -> raise Not_value (*Model_parser.Unparsed "!"*)
  (* TODO change the value returned for non populated prover variable '!' -> '?' ? *)
  | To_array t -> convert_to_model_value lf (Array (convert_z3_array t))
  | Apply (s, lt) -> Model_parser.Apply (s, List.map (convert_to_model_value lf) lt)
  | Function_var _ | Var _ | Ite _ -> raise Not_value

and convert_z3_array (t: term) : array =

  let rec convert_array t =
    match t with
    (* This works for multidim array because, we call convert_to_model_value on
       the new array generated (which will still contain a To_array).
       Example of value for multidim array:
       To_array (Ite (x, 1, (To_array t), To_array t')) -> call on complete term ->
       Astore (1, To_array t, To_array t') -> call on subpart (To_array t) ->
       Astore (1, Aconst t, To_array t') -> call on subpart (To_array t') ->
       Astore (1, Aconst t, Aconst t')
     *)

    | Ite (Function_var _x, if_t, t1, t2) ->
      Astore (convert_array t2, if_t, t1)
    | Ite (if_t, Function_var _x, t1, t2) ->
      Astore (convert_array t2, if_t, t1)
    | t -> Aconst t
  in
  convert_array t

and convert_record lf l =
  List.map (fun (f, v) -> f, convert_to_model_value lf v) l

let convert_to_model_element pm name (t: term) =
  let value = convert_to_model_value pm.list_fields t in
  let attrs =
    try Mstr.find name pm.set_str
    with Not_found -> Ident.Sattr.empty in
  Model_parser.create_model_element ~name ~value ~attrs

let default_apply_to_record (list_records: (string list) Mstr.t)
    (noarg_constructors: string list) (t: term) =

  let rec array_apply_to_record (a: array) =
    match a with
    | Avar _v -> raise Not_value
    | Aconst x ->
        let x = apply_to_record x in
        Aconst x
    | Astore (a, t1, t2) ->
        let a = array_apply_to_record a in
        let t1 = apply_to_record t1 in
        let t2 = apply_to_record t2 in
        Astore (a, t1, t2)

  and apply_to_record (v: term) =
    match v with
    | Sval _ -> v
    (* Var with no arguments can actually be constructors. We check this
       here and if it is the case we change the variable into a value. *)
    | Var s when List.mem s noarg_constructors ->
        Apply (s, [])
    | Prover_var _ | Function_var _ | Var _ -> v
    | Array a ->
        Array (array_apply_to_record a)
    | Record (s, l) ->
        let l = List.map (fun (f,v) -> f, apply_to_record v) l in
        Record (s, l)
    | Apply (s, l) ->
        let l = List.map apply_to_record l in
        if Mstr.mem s list_records then
          Record (s, List.combine (Mstr.find s list_records) l)
        else
          Apply (s, l)
    | Ite (t1, t2, t3, t4) ->
        let t1 = apply_to_record t1 in
        let t2 = apply_to_record t2 in
        let t3 = apply_to_record t3 in
        let t4 = apply_to_record t4 in
        Ite (t1, t2, t3, t4)
    | To_array t1 ->
        let t1 = apply_to_record t1 in
        To_array t1
    (* TODO Does not exist yet *)
    | Trees _ -> raise Not_value
  in
  apply_to_record t

let apply_to_records_ref = ref None

let register_apply_to_records f =
  apply_to_records_ref := Some f

let apply_to_record list_records noarg_constructors t =
  match !apply_to_records_ref with
  | None -> default_apply_to_record list_records noarg_constructors t
  | Some f -> f list_records noarg_constructors t

let definition_apply_to_record list_records noarg_constructors d =
    match d with
    | Function (lt, t) ->
        Function (lt, apply_to_record list_records noarg_constructors t)
    | Term t -> Term (apply_to_record list_records noarg_constructors  t)
    | Noelement -> Noelement

let rec convert_to_tree_def (d: definition) : tree_definition =
  match d with
  | Function (l, t) ->
      TFunction (l, convert_to_tree_term t)
  | Term t -> TTerm (convert_to_tree_term t)
  | Noelement -> TNoelement

and convert_to_tree_term (t: term) : tterm =
  match t with
  | Sval v -> TSval v
  | Apply (s, tl) -> TApply(s, List.map convert_to_tree_term tl)
  | Array a -> TArray (convert_to_tree_array a)
  | Prover_var v -> TProver_var (Tree_var v)
  | Function_var v -> TFunction_var v
  | Var v -> TVar v
  | Ite (t1, t2, t3, t4) ->
      TIte (convert_to_tree_term t1, convert_to_tree_term t2, convert_to_tree_term t3, convert_to_tree_term t4)
  | Record (s, tl) -> TRecord (s, List.map (fun (s, t) -> (s, convert_to_tree_term t)) tl)
  | To_array t -> TTo_array (convert_to_tree_term t)
  (* TODO should not appear here *)
  | Trees _ -> raise Not_value

and convert_to_tree_array a =
  match a with
  | Avar v -> TArray_var v
  | Aconst t -> TConst (convert_to_tree_term t)
  | Astore (a, t1, t2) ->
      TStore (convert_to_tree_array a, convert_to_tree_term t1, convert_to_tree_term t2)

let rec convert_tree_to_term = function
  | Node mpt ->
      let l = Mpr.bindings mpt in
      let l = List.map (fun (k,e) -> (k, convert_tree_to_term e)) l in
      Trees l
  | Leaf t ->
      convert_tdef_to_term t

and convert_tdef_to_term = function
  | TFunction (_l, t) ->
      convert_tterm_to_term t
  | TTerm t ->
      convert_tterm_to_term t
  | TNoelement ->
      (* TODO check which error can be raised here *)
      Sval (Unparsed ("error"))

and convert_tterm_to_term = function
  | TSval v -> Sval v
  | TApply (s, tl) -> Apply (s, List.map convert_tterm_to_term tl)
  | TArray ta -> Array (convert_tarray_to_array ta)
  | TProver_var (Tree_var v) -> Prover_var v
  | TProver_var (Tree v) -> convert_tree_to_term v
  | TFunction_var v -> Function_var v
  | TVar v -> Var v
  | TIte (t1, t2, t3, t4) ->
      let t1 = convert_tterm_to_term t1 in
      let t2 = convert_tterm_to_term t2 in
      let t3 = convert_tterm_to_term t3 in
      let t4 = convert_tterm_to_term t4 in
      Ite (t1, t2, t3, t4)
  | TRecord (s, ls) ->
      Record (s, List.map (fun (s, t) -> (s, convert_tterm_to_term t)) ls)
  | TTo_array t -> To_array (convert_tterm_to_term t)

and convert_tarray_to_array a =
  match a with
  | TArray_var v -> Avar v
  | TConst t -> Aconst (convert_tterm_to_term t)
  | TStore (a, t1, t2) -> Astore (convert_tarray_to_array a, convert_tterm_to_term t1, convert_tterm_to_term t2)

let create_list pm (table: definition Mstr.t) =

  (* Convert list_records to take replace fields with model_trace when necessary. *)
  let list_records =
    let select (a, b) = if b = "" then a else b in
    Mstr.mapi (fun _ -> List.map select) pm.list_records in

  (* Convert Apply that were actually recorded as record to Record. Also replace
     Var that are originally unary constructor  *)
  let table =
    Mstr.mapi (fun _ -> definition_apply_to_record list_records pm.noarg_constructors)
      table in

  (* First populate the table with all references to prover variables *)
  let table =
    let var_sets = List.map collect_prover_vars (Mstr.values table) in
    let vars = List.fold_right Sstr.union var_sets Sstr.empty in
    let vars = Sstr.filter (fun v -> not (Mstr.mem v table)) vars in
    Sstr.fold (fun v -> Mstr.add v Noelement) vars table in

  Debug.dprintf debug_cntex "After parsing@.";
  Mstr.iter (fun k e ->
      let t = convert_to_tree_def e in
      Debug.dprintf debug_cntex "constant %s : %a@."
        k print_def t)
    table;

  let table : tree_definition Mstr.t = Mstr.map convert_to_tree_def table in

  (* First recover values stored in projections that were registered *)
  let table : tree Mstr.t =
    (* Convert the table to a table of tree *)
    (* TODO this could probably be optimized away *)
    let table_leaves = Mstr.map (fun v -> Leaf v) table in
    let table_projs_fields = Mstr.filter (fun key _ ->
        Mstr.mem key pm.list_projections || Mstr.mem key pm.list_fields) table in
    Mstr.fold add_vars_to_table table_projs_fields table_leaves in

  (* Only printed in debug *)
  Debug.dprintf debug_cntex "Value were queried from projections@.";
  print_table table;

  (* Then substitute all variables with their values *)
  let table = Mstr.fold refine_variable_value table table in

  Debug.dprintf debug_cntex "Var values were propagated@.";
  print_table table;

  let table : term Mstr.t = Mstr.map convert_tree_to_term table in

  Lists.map_filter
    (fun (name, term) ->
       try Some (convert_to_model_element pm name term)
       with Not_value when not Debug.(test_flag debug_cntex && test_flag stack_trace) ->
         Debug.dprintf debug_cntex "Element creation failed: %s@." name;
           None)
    (List.rev (Mstr.bindings table))
