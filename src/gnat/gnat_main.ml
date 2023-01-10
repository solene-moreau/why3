(* This is the main file of gnatwhy3 *)

(* Gnatwhy3 does the following:
   - it reads a .gnat-json file that was generated by gnat2why
   - it computes the VCs
   - it runs the selected provers on each VC.
   - it generates a summary of what was proved and not proved in JSON format
 and outputs this JSON format to stdout (for gnat2why to read).

   See gnat_objectives.mli for the notion of objective and goal.

   See gnat_report.mli for the JSON format

   gnat_main can be seen as the "driver" for gnatwhy3. Much of the
   functionality is elsewhere.
   Specifically, this file does:
      - compute the objective that belongs to a goal/VC
      - drive the scheduling of VCs, and handling of results
      - output the messages
*)

open Why3
open Gnat_scheduler

module C = Gnat_objectives.Make (Gnat_scheduler)

let rec is_trivial fml =
   let open Term in
   (* Check wether the formula is trivial.  *)
   match fml.t_node with
   | Ttrue -> true
   | Tquant (_,tq) ->
         let _,_,t = t_open_quant tq in
         is_trivial t
   | Tlet (_,tb) ->
         let _, t = t_open_bound tb in
         is_trivial t
   | Tbinop (Timplies,_,t2) ->
         is_trivial t2
   | Tcase (_,tbl) ->
         List.for_all (fun b ->
            let _, t = t_open_branch b in
            is_trivial t) tbl
   | _ -> false

let register_goal cont goal_id =
  (* Register the goal by extracting the explanation and trace. If the goal is
   * trivial, do not register. For trivial goals, we register a dummy proof
   * attempt that succeeded. *)
  let s = cont.Controller_itp.controller_session in
  let task = Session_itp.get_task s goal_id in
  let fml = Task.task_goal_fmla task in
  let is_trivial = is_trivial fml in
  if is_trivial then Gnat_objectives.add_trivial_proof s goal_id;
  match is_trivial, Gnat_expl.search_labels fml with
  | true, None ->
      Gnat_objectives.set_not_interesting goal_id
  | false, None ->
      let base_msg = "Task has no tracability label" in
      let msg =
        if Gnat_config.debug then
          Pp.sprintf "%s: %a.@." base_msg Pretty.print_term fml
        else base_msg in
      Gnat_util.abort_with_message ~internal:true msg
  | _, Some c ->
      begin
        if c.Gnat_expl.check.Gnat_expl.already_proved then
          Gnat_objectives.set_not_interesting goal_id
        else
          Gnat_objectives.add_to_objective c goal_id
      end

let rec handle_vc_result c goal result =
   (* This function is called when the prover has returned from a VC.
       goal           is the VC that the prover has dealt with
       result         a boolean, true if the prover has proved the VC
       prover_result  the actual proof result, to extract statistics
   *)
   let obj, status = C.register_result c goal result in
   match status with
   | Gnat_objectives.Proved -> ()
   | Gnat_objectives.Not_Proved -> ()
   | Gnat_objectives.Work_Left ->
       List.iter (create_manual_or_schedule c obj) (Gnat_objectives.next obj)
   | Gnat_objectives.Counter_Example ->
     (* In this case, counterexample prover and VC will be never None *)
     let prover_ce = (Opt.get Gnat_config.prover_ce) in
     match Gnat_objectives.ce_goal obj with
     | None -> assert false
     | Some g ->
       C.schedule_goal_with_prover c ~callback:(interpret_result c) g prover_ce

and interpret_result c pa pas =
   (* callback function for the scheduler, here we filter if an interesting
      goal has been dealt with, and only then pass on to handle_vc_result *)
   match pas with
   | Controller_itp.Done r ->
     let session = c.Controller_itp.controller_session in
     let goal = Session_itp.get_proof_attempt_parent session pa in
     let answer = r.Call_provers.pr_answer in
     if Gnat_config.debug_prover_errors &&
        answer = Call_provers.HighFailure &&
        not (Gnat_config.is_ce_prover session pa) then
       Gnat_report.add_warning r.Call_provers.pr_output;
     handle_vc_result c goal (answer = Call_provers.Valid)
   | Controller_itp.InternalFailure e ->
       let s = Format.asprintf "Internal Why3 unexpected error during \
                                elaboration of prover file:\n %a"
           Exn_printer.exn_printer e in
       Gnat_report.add_warning s
   | _ ->
         ()

and create_manual_or_schedule (c: Controller_itp.controller) _obj goal =
  let s = c.Controller_itp.controller_session in
  match Gnat_config.manual_prover with
  | Some _ when C.goal_has_splits s goal &&
                not (Session_itp.pn_proved c.Controller_itp.controller_session goal) ->
                  handle_vc_result c goal false
  | _ -> schedule_goal c goal

and schedule_goal (c: Controller_itp.controller) (g : Session_itp.proofNodeID) =
   (* schedule a goal for proof - the goal may not be scheduled actually,
      because we detect that it is not necessary. This may have several
      reasons:
         * command line given to skip proofs
         * goal already proved
         * goal already attempted with identical options
   *)
   if (Gnat_config.manual_prover <> None
       && not (Session_itp.pn_proved c.Controller_itp.controller_session g)) then begin
       actually_schedule_goal c g
   (* then implement reproving logic *)
   end else begin
     (* Maybe the goal is already proved *)
      if Session_itp.pn_proved c.Controller_itp.controller_session g then begin
         handle_vc_result c g true
      (* Maybe there was a previous proof attempt with identical parameters *)
      end else if Gnat_objectives.all_provers_tried c.Controller_itp.controller_session g then begin
         (* the proof attempt was necessarily false *)
         handle_vc_result c g false
      end else begin
         actually_schedule_goal c g
      end;
   end

and actually_schedule_goal c g =
  C.schedule_goal ~callback:(interpret_result c) c g

let handle_obj c obj =
   if Gnat_objectives.objective_status obj <> Gnat_objectives.Proved then begin
     match Gnat_objectives.next obj with
      | [] -> ()
      | l ->
         List.iter (create_manual_or_schedule c obj) l
   end

let all_split_subp c subp =
  let s = c.Controller_itp.controller_session in
   C.init_subp_vcs c subp;
   Gnat_objectives.iter_leaf_goals s subp (register_goal c);
   C.all_split_leaf_goals ();
   Gnat_objectives.clear ()

let maybe_giant_step_rac ctr parent models =
  if not Gnat_config.giant_step_rac then None else (
    Debug.dprintf Check_ce.debug_check_ce_categorization "Running giant-step RAC@.";
    let Controller_itp.{controller_config= cnf; controller_env= env} = ctr in
    let pm =
      parent |> Session_itp.find_th ctr.Controller_itp.controller_session |>
      Session_itp.theory_name |> Theory.restore_theory |> Pmodule.restore_module
    in
    let check_term = Rac.Why.mk_check_term_lit cnf env
        ?why_prover:Gnat_config.rac_prover () in
    let compute_term = Rac.Why.mk_compute_term_lit env () in
    let rac = Pinterp.mk_rac check_term in
    let timelimit = Opt.map float_of_int Gnat_config.rac_timelimit in
    let rac_results = Check_ce.get_rac_results ?timelimit ~compute_term
        ~only_giant_step:true rac env pm models in
    let strategy = Check_ce.best_non_empty_giant_step_rac_result in
    let model = Check_ce.select_model_from_giant_step_rac_results ~strategy rac_results in
    match model with
    | None -> None
    | Some (m, _) when not Gnat_config.giant_step_rac ->
        Some (Gnat_counterexamples.post_clean#model m, None)
    | Some (m, Check_ce.RAC_not_done reason) -> (
        if Gnat_config.debug then Warning.emit "%s@." reason;
        Some (Gnat_counterexamples.post_clean#model m, None)
      )
    | Some (m, Check_ce.RAC_done (res_state, res_log)) -> (
        let res = Check_ce.RAC_done (res_state, res_log) in
        Debug.dprintf Check_ce.debug_check_ce_rac_results "%a@."
          (Check_ce.print_rac_result ?verb_lvl:None) res;
        Some (Gnat_counterexamples.post_clean#model m, Some res))
  )

let report_messages c obj =
  let s = c.Controller_itp.controller_session in
  let result =
    if C.session_proved_status c obj then
      let (stats, stat_checker) = C.Save_VCs.extract_stats c obj in
      Gnat_report.Proved (stats, stat_checker)
    else
      let model =
        let ce_pa = C.session_find_ce_pa c obj in
        match ce_pa with
        | None -> None
        | Some pa ->
          let ce_pan = Session_itp.get_proof_attempt_node s pa in
          match ce_pan.Session_itp.proof_state with
          | None -> None
          | Some pr ->
            let not_step_limit (pa,_) = pa <> Call_provers.StepLimitExceeded in
            let models = List.filter not_step_limit pr.Call_provers.pr_models in
            maybe_giant_step_rac c ce_pan.Session_itp.parent models
      in
      let unproved_pa = C.session_find_unproved_pa c obj in
      let manual_info = Opt.bind unproved_pa (Gnat_manual.manual_proof_info s) in
      let unproved_goal =
        (* In some cases (replay) no proofattempt proves the goal but we still
           want a task to be able to extract the expl from it. *)
        match unproved_pa with
        | None -> C.session_find_unproved_goal c obj
        | Some pa -> Some (Session_itp.get_proof_attempt_parent s pa)
      in
      let extra_info =
        match unproved_goal with
        | None -> { Gnat_expl.pretty_node = None; inlined = None }
        | Some g -> Gnat_objectives.get_extra_info g
      in
      Gnat_report.Not_Proved (extra_info, model, manual_info) in
  Gnat_report.register obj (C.Save_VCs.check_to_json s obj) result

(* Escaping all debug printings *)
let escape_buffer = Buffer.create 42
let escape_formatter = Format.formatter_of_buffer escape_buffer
let () = Debug.set_debug_formatter escape_formatter

(* This is to be executed when scheduling ends *)
let ending c () =
  C.remove_all_valid_ce_attempt c.Controller_itp.controller_session;
  Util.timing_step_completed "gnatwhy3.run_vcs";
  C.save_session c;
  Util.timing_step_completed "gnatwhy3.save_session";
  Gnat_objectives.iter (report_messages c);
  let s = Buffer.contents escape_buffer in
  if s <> "" then
    Gnat_report.add_warning s;
  Gnat_report.print_messages ();
  (* Dump profiling data (when compiled with profiling enabled) to file whose
     name is based on the processed .mlw file; otherwise profile data from
     several compilation would be written to a single gmon.out file and
     overwrite each other. When compiled with profiling disabled it has no
     visible effect. Note: we set the filename just before the program exit
     to not interfere with profiling of provers.
   *)
  let basename =
    Filename.chop_extension
      (Filename.basename Gnat_config.filename) in
  Unix.putenv "GMON_OUT_PREFIX" (basename ^ "_gnatwhy3_gmon.out")

let normal_handle_one_subp c subp =
   C.init_subp_vcs c subp;
   let s = c.Controller_itp.controller_session in
   Gnat_objectives.iter_leaf_goals s subp (register_goal c)

(* save session on interrupt initiated by the user *)
let save_session_and_exit c signum =
  (* Ignore all SIGINT, SIGHUP and SIGTERM, which may be received when
     gnatprove is called in GNATStudio, so that the session file is always
     saved. Wrap in exception block as some signals are not supported on
     windows. *)
  begin try
    Sys.set_signal Sys.sigint Sys.Signal_ignore;
    Sys.set_signal Sys.sighup Sys.Signal_ignore;
    Sys.set_signal Sys.sigterm Sys.Signal_ignore;
  with Invalid_argument _ -> () end;
  C.save_session c;
  exit signum

 (* This is the main code. We read the file into the session if not already
    done, we apply the split_goal transformation when needed, and we schedule
    the first VC of all objectives. When done, we save the session.
 *)

let _ =
  if Gnat_config.debug then Debug.(set_flag (lookup_flag "gnat_ast"));
  Debug.set_flag Model_parser.debug_force_binary_floats;
  Debug.set_flag Pinterp.debug_disable_builtin_mach;
  Model_parser.customize_clean Gnat_counterexamples.clean;
  List.iter Introduction.push_attributes_with_prefix
    ["GP_Check:"; "GP_Pretty_Ada:"; "GP_Shape:"; "GP_Sloc:";
     "GP_Already_Proved"; "GP_Inline"; "GP_Inlined"];
  ( try
      let log = Sys.getenv "GNATWHY3LOG" in
      let out = open_out_gen [Open_text; Open_creat; Open_append] 0o666 log in
      let fmt = Format.formatter_of_out_channel out in
      Debug.set_debug_formatter fmt;
      Format.fprintf fmt "@.@.===== %s@." Gnat_config.filename;
      Warning.set_hook (fun ?loc:_ line -> Format.fprintf fmt "%s@." line)
    with Not_found -> () );
  Util.init_timing ();
  try
    let c = Gnat_objectives.init_cont () in
    (* This has to be done after initialization of controller. Otherwise we
       don't have session. *)
    Sys.set_signal Sys.sigint (Sys.Signal_handle (save_session_and_exit c));
    Util.timing_step_completed "gnatwhy3.init";
    begin match Gnat_config.proof_mode with
    | Gnat_config.Progressive
    | Gnat_config.Per_Path
    | Gnat_config.Per_Check ->
        C.iter_subps c (normal_handle_one_subp c);
        Util.timing_step_completed "gnatwhy3.register_vcs";
        if Gnat_config.replay then begin
          C.replay c (*;
          Gnat_objectives.do_scheduled_jobs (fun _ _ -> ());*)
        end else begin
          Gnat_objectives.iter (handle_obj c);
          Util.timing_step_completed "gnatwhy3.schedule_vcs";
        end;
     | Gnat_config.All_Split ->
        C.iter_subps c (all_split_subp c)
     | Gnat_config.No_WP ->
        (* we should never get here *)
        ()
    end;
    Gnat_scheduler.main_loop (ending c)
  with e when Debug.test_flag Debug.stack_trace -> raise e
  | Out_of_memory as e -> raise e
  | e ->
      let s = Pp.sprintf "%a.@." Exn_printer.exn_printer e in
      Gnat_util.abort_with_message ~internal:true s
