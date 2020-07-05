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

open Format
open Why3
open Wstdlib
open Whyconf
open Theory
open Task

let usage_msg = sprintf
  "Usage: %s [options] [[<file>|-] [-T <theory> [-G <goal>]...]...]...\n\
   Run some transformation or prover on the given goals.\n"
  (Filename.basename Sys.argv.(0))

let opt_queue = Queue.create ()

let opt_input = ref None
let opt_theory = ref None
let opt_trans = ref []
let opt_metas = ref []
(* Option for printing counterexamples with JSON formatting *)
let opt_json = ref false

let add_opt_file x =
  let tlist = Queue.create () in
  Queue.push (Some x, tlist) opt_queue;
  opt_input := Some tlist

let add_opt_theory x =
  let l = Strings.split '.' x in
  let p, t = match List.rev l with
    | t::p -> List.rev p, t
    | _ -> assert false
  in
  match !opt_input, p with
  | None, [] ->
      eprintf "Option '-T'/'--theory' with a non-qualified \
        argument requires an input file.@.";
      exit 1
  | Some tlist, [] ->
      let glist = Queue.create () in
      let elist = Queue.create () in
      Queue.push (x, p, t, glist, elist) tlist;
      opt_theory := Some glist
  | _ ->
      let tlist = Queue.create () in
      Queue.push (None, tlist) opt_queue;
      opt_input := None;
      let glist = Queue.create () in
      let elist = Queue.create () in
      Queue.push (x, p, t, glist,elist) tlist;
      opt_theory := Some glist

let add_opt_goal x =
  let glist = match !opt_theory, !opt_input with
    | None, None -> eprintf
        "Option '-G'/'--goal' requires an input file or a library theory.@.";
        exit 1
    | None, Some _ ->
        add_opt_theory "Top";
        Opt.get !opt_theory
    | Some glist, _ -> glist in
  let l = Strings.split '.' x in
  Queue.push (x, l) glist

let add_opt_trans x = opt_trans := x::!opt_trans

let add_opt_meta meta =
  let meta_name, meta_arg =
    try
      let index = String.index meta '=' in
      (String.sub meta 0 index),
      Some (String.sub meta (index+1) (String.length meta - (index + 1)))
    with Not_found ->
      meta, None
  in
  opt_metas := (meta_name,meta_arg)::!opt_metas

let opt_driver = ref []
let opt_parser = ref None
let opt_prover = ref None
let opt_output = ref None
let opt_timelimit = ref None
let opt_memlimit = ref None
let opt_command = ref None
let opt_task = ref None

let opt_print_theory = ref false
let opt_print_namespace = ref false

let option_list =
  let open Getopt in
  [ Key ('T', "theory"), Hnd1 (AString, add_opt_theory),
    "<theory> select <theory> in the input file or in the library";
    Key ('G', "goal"), Hnd1 (AString, add_opt_goal),
    "<goal> select <goal> in the last selected theory";
    Key ('P', "prover"), Hnd1 (AString, fun s -> opt_prover := Some s),
    "<prover> prove or print (with -o) the selected goals";
    Key ('F', "format"), Hnd1 (AString, fun s -> opt_parser := Some s),
    "<format> select input format (default: \"why\")";
    Key ('t', "timelimit"), Hnd1 (AInt, fun i -> opt_timelimit := Some i),
    "<sec> set the prover's time limit (default=10, no limit=0)";
    Key ('m', "memlimit"), Hnd1 (AInt, fun i -> opt_memlimit := Some i),
    "<MiB> set the prover's memory limit (default: no limit)";
    Key ('a', "apply-transform"), Hnd1 (AString, add_opt_trans),
    "<transf> apply a transformation to every task";
    Key ('M', "meta"), Hnd1 (AString, add_opt_meta),
    "<meta>[=<string>] add a meta to every task";
    Key ('D', "driver"), Hnd1 (AString, fun s -> opt_driver := s::!opt_driver),
    "<file> specify a prover's driver (conflicts with -P)";
    Key ('o', "output"), Hnd1 (AString, fun s -> opt_output := Some s),
    "<dir> print the selected goals to separate files in <dir>";
    KLong "json", Hnd0 (fun () -> opt_json := true),
    " print counterexamples in JSON format";
    KLong "print-theory", Hnd0 (fun () -> opt_print_theory := true),
    " print selected theories";
    KLong "print-namespace", Hnd0 (fun () -> opt_print_namespace := true),
    " print namespaces of selected theories";
    Debug.Args.desc_shortcut
      "parse_only" (KLong "parse-only") " stop after parsing";
    Debug.Args.desc_shortcut
      "type_only" (KLong "type-only") " stop after type checking";
    Termcode.opt_extra_expl_prefix
  ]

let config, _, env =
  Whyconf.Args.initialize option_list add_opt_file usage_msg

let opt_driver = ref (match !opt_driver with
  | f::ef -> Some (f, ef)
  | [] -> None)

let () = try
  if Queue.is_empty opt_queue then
    Whyconf.Args.exit_with_usage option_list usage_msg;

  if !opt_prover <> None && !opt_driver <> None then begin
    eprintf "Options '-P'/'--prover' and \
      '-D'/'--driver' cannot be used together.@.";
    exit 1
  end;

  if !opt_output <> None && !opt_driver = None && !opt_prover = None then begin
    eprintf
      "Option '-o'/'--output' requires either a prover or a driver.@.";
    exit 1
  end;

  if !opt_prover = None then begin
    if !opt_timelimit <> None then begin
      eprintf "Option '-t'/'--timelimit' requires a prover.@.";
      exit 1
    end;
    if !opt_memlimit <> None then begin
      eprintf "Option '-m'/'--memlimit' requires a prover.@.";
      exit 1
    end;
    if !opt_driver = None && not !opt_print_namespace then
      opt_print_theory := true
  end;

  let main = Whyconf.get_main config in

  if !opt_timelimit = None then opt_timelimit := Some (Whyconf.timelimit main);
  if !opt_memlimit  = None then opt_memlimit  := Some (Whyconf.memlimit main);
  begin match !opt_prover with
  | Some s ->
    let filter_prover = Whyconf.parse_filter_prover s in
    let prover = Whyconf.filter_one_prover config filter_prover in
    opt_command :=
      Some (String.concat " " (prover.command :: prover.extra_options));
    opt_driver := Some (prover.driver, prover.extra_drivers)
  | None ->
      ()
  end;
  let add_meta task (meta,s) =
    let meta = lookup_meta meta in
    let args = match s with
      | Some s -> [MAstr s]
      | None -> []
    in
    Task.add_meta task meta args
  in
  opt_task := List.fold_left add_meta !opt_task !opt_metas

  with e when not (Debug.test_flag Debug.stack_trace) ->
    eprintf "%a@." Exn_printer.exn_printer e;
    exit 1

let timelimit = match !opt_timelimit with
  | None -> 10
  | Some i when i <= 0 -> 0
  | Some i -> i

let memlimit = match !opt_memlimit with
  | None -> 0
  | Some i when i <= 0 -> 0
  | Some i -> i

let print_th_namespace fmt th =
  Pretty.print_namespace fmt th.th_name.Ident.id_string th

let fname_printer = ref (Ident.create_ident_printer [])

let output_task drv fname _tname th task dir =
  let fname = Filename.basename fname in
  let fname =
    try Filename.chop_extension fname with _ -> fname in
  let tname = th.th_name.Ident.id_string in
  let dest = Driver.file_of_task drv fname tname task in
  (* Uniquify the filename before the extension if it exists*)
  let i = try String.rindex dest '.' with _ -> String.length dest in
  let name = Ident.string_unique !fname_printer (String.sub dest 0 i) in
  let ext = String.sub dest i (String.length dest - i) in
  let cout = open_out (Filename.concat dir (name ^ ext)) in
  Driver.print_task drv (formatter_of_out_channel cout) task;
  close_out cout

let unproved = ref false

let loc_contains loc1 loc2 =
  (* [loc1:   [loc2:   ]    ] *)
  let f1, (bl1, bc1), (el1, ec1) = Loc.get_multiline loc1 in
  let f2, (bl2, bc2), (el2, ec2) = Loc.get_multiline loc2 in
  String.equal f1 f2 &&
  (bl1 < bl2 || (bl1 = bl2 && bc1 <= bc2)) &&
  (el1 > el2 || (el1 = el2 && ec1 >= ec2))

let find_rs pm loc =
  let exception Found of Expr.rsymbol in
  let open Expr in
  let open Pdecl in
  let loc_of_exp e = Opt.get_def Loc.dummy_position e.e_loc in
  let loc_of_cexp ce = match ce.c_node with Cfun e -> loc_of_exp e | _ -> Loc.dummy_position in
  let find_pd_rec_defn rd =
    if loc_contains (loc_of_cexp rd.rec_fun) loc then
      raise (Found rd.rec_sym) in
  let find_pd_pdecl pd =
    match pd.pd_node with
    | PDlet (LDvar (_, e)) when
        loc_contains (loc_of_exp e) loc ->
        failwith "find_pd: location in variable declaration :/"
    | PDlet (LDsym (rs, ce)) when loc_contains (loc_of_cexp ce) loc ->
          raise (Found rs)
    | PDlet (LDrec rds) ->
        List.iter find_pd_rec_defn rds
    | _ -> () in
  let rec find_pd_mod_unit =
    let open Pmodule in
    function
    | Uuse _ | Uclone _ | Umeta _ -> ()
    | Uscope (_, us) -> List.iter find_pd_mod_unit us
    | Udecl pd -> find_pd_pdecl pd in
  try List.iter find_pd_mod_unit pm.Pmodule.mod_units; None
  with Found rs -> Some rs

let maybe_model_rs pm loc model rs =
  let open Pinterp in
  try
    ignore (eval_rs env pm.Pmodule.mod_known loc model rs);
    eprintf "maybe_model: term with loc not encountered, was ok, or could not evaluated";
    None
  with
  | Contr _ -> Some true
  | MissingModelValue _ ->
      None

let maybe_model pm m =
  let (>>=) = Opt.bind in
  Opt.get_def true
    (Model_parser.get_model_term_loc m >>= fun loc ->
     find_rs pm loc >>= fun rs ->
     maybe_model_rs pm loc m rs)

let do_task drv fname tname (th : Theory.theory) (task : Task.task) =
  let limit =
    { Call_provers.empty_limit with
      Call_provers.limit_time = timelimit;
                   limit_mem = memlimit } in
  match !opt_output, !opt_command with
    | None, Some command ->
        let call =
          Driver.prove_task ~command ~limit drv task in
        let res = Call_provers.wait_on_call call in
        let pr_model =
          let model = res.Call_provers.pr_model in
          if maybe_model (Pmodule.restore_module th) model
          then model else Model_parser.default_model in
        let res = {res with Call_provers.pr_model} in
        printf "%s %s %s: %a@." fname tname
          (task_goal task).Decl.pr_name.Ident.id_string
          (Call_provers.print_prover_result ~json_model:!opt_json) res;
        if res.Call_provers.pr_answer <> Call_provers.Valid then unproved := true
    | None, None ->
        Driver.print_task drv std_formatter task
    | Some dir, _ -> output_task drv fname tname th task dir

let do_tasks env drv fname tname th task =
  let lookup acc t =
    (try Trans.singleton (Trans.lookup_transform t env) with
       Trans.UnknownTrans _ -> Trans.lookup_transform_l t env) :: acc
  in
  let trans = List.fold_left lookup [] !opt_trans in
  let apply tasks tr =
    List.rev (List.fold_left (fun acc task ->
      List.rev_append (Trans.apply tr task) acc) [] tasks)
  in
  let tasks = List.fold_left apply [task] trans in
  List.iter (do_task drv fname tname th) tasks

let do_theory env drv fname tname th glist elist =
  if !opt_print_theory then
    printf "%a@." Pretty.print_theory th
  else if !opt_print_namespace then
    printf "%a@." print_th_namespace th
  else begin
    let add acc (x,l) =
      let pr = try ns_find_pr th.th_export l with Not_found ->
        eprintf "Goal '%s' not found in theory '%s'.@." x tname;
        exit 1
      in
      Decl.Spr.add pr acc
    in
    let drv = Opt.get drv in
    let prs = Queue.fold add Decl.Spr.empty glist in
    let sel = if Decl.Spr.is_empty prs then None else Some prs in
    let tasks = Task.split_theory th sel !opt_task in
    List.iter (do_tasks env drv fname tname th) tasks;
    let eval (x,l) =
      let ls = try ns_find_ls th.th_export l with Not_found ->
        eprintf "Declaration '%s' not found in theory '%s'.@." x tname;
        exit 1
      in
      match Decl.find_logic_definition th.th_known ls with
      | None -> eprintf "Symbol '%s' has no definition in theory '%s'.@." x tname;
        exit 1
      | Some d ->
        let l,_t = Decl.open_ls_defn d in
        match l with
        | [] ->
(* TODO
          let t = Mlw_interp.eval_global_term env th.th_known t in
          printf "@[<hov 2>Evaluation of %s:@ %a@]@." x Mlw_interp.print_value t
*) ()
        | _ ->
          eprintf "Symbol '%s' is not a constant in theory '%s'.@." x tname;
          exit 1
    in
    Queue.iter eval elist
  end

let do_global_theory env drv (tname,p,t,glist,elist) =
  let th = Env.read_theory env p t in
  do_theory env drv "lib" tname th glist elist

let do_local_theory env drv fname m (tname,_,t,glist,elist) =
  let th = try Mstr.find t m with Not_found ->
    eprintf "Theory '%s' not found in file '%s'.@." tname fname;
    exit 1
  in
  do_theory env drv fname tname th glist elist

let do_input env drv = function
  | None, _ when Debug.test_flag Typing.debug_type_only ||
                 Debug.test_flag Typing.debug_parse_only ->
      ()
  | None, tlist ->
      Queue.iter (do_global_theory env drv) tlist
  | Some f, tlist ->
      let format = !opt_parser in
      let fname, m = match f with
        | "-" -> "stdin",
            Env.read_channel Env.base_language ?format env "stdin" stdin
        | fname ->
            let (mlw_files, _) =
              Env.read_file Env.base_language ?format env fname in
            (fname, mlw_files)
      in
      if Debug.test_flag Typing.debug_type_only then ()
      else
        if Queue.is_empty tlist then
          let glist = Queue.create () in
          let elist = Queue.create () in
          let add_th t th mi = Ident.Mid.add th.th_name (t,th) mi in
          let do_th _ (t,th) =
            do_theory env drv fname t th glist elist
          in
          Ident.Mid.iter do_th (Mstr.fold add_th m Ident.Mid.empty)
        else
          Queue.iter (do_local_theory env drv fname m) tlist

let () =
  try
    let load (f,ef) = load_driver (Whyconf.get_main config) env f ef in
    let drv = Opt.map load !opt_driver in
    Queue.iter (do_input env drv) opt_queue;
    if !unproved then exit 2
  with e when not (Debug.test_flag Debug.stack_trace) ->
    eprintf "%a@." Exn_printer.exn_printer e;
    exit 1

(*
Local Variables:
compile-command: "unset LANG; make -C ../.. byte"
End:
*)
