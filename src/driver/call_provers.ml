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

open Format
open Model_parser

let debug = Debug.register_info_flag "call_prover"
  ~desc:"Print@ debugging@ messages@ about@ prover@ calls@ \
         and@ keep@ temporary@ files."

(** time regexp "%h:%m:%s" *)
type timeunit =
  | Hour
  | Min
  | Sec
  | Msec

type timeregexp = {
  re    : Str.regexp;
  group : timeunit array; (* i-th corresponds to the group i+1 *)
}

type stepsregexp = {
  steps_re        : Str.regexp;
  steps_group_num : int; (* the number of matched group which corresponds to the number of steps *)
}

let timeregexp s =
  let cmd_regexp = Str.regexp "%\\(.\\)" in
  let nb = ref 0 in
  let l = ref [] in
  let add_unit x = l := (!nb,x) :: !l; incr nb; "\\([0-9]+.?[0-9]*\\)" in
  let replace s = match Str.matched_group 1 s with
    | "%" -> "%"
    | "h" -> add_unit Hour
    | "m" -> add_unit Min
    | "s" -> add_unit Sec
    | "i" -> add_unit Msec
    | x -> failwith ("unknown time format specifier: %%"^x^" (should be either %%h, %%m, %%s or %%i")
  in
  let s = Str.global_substitute cmd_regexp replace s in
  let group = Array.make !nb Hour in
  List.iter (fun (i,u) -> group.(i) <- u) !l;
  { re = Str.regexp s; group = group}

let rec grep_time out = function
  | [] -> None
  | re :: l ->
    begin try
            ignore (Str.search_forward re.re out 0);
            let t = ref 0. in
            Array.iteri (fun i u ->
              let v = Str.matched_group (succ i) out in
              match u with
                | Hour -> t := !t +. float_of_string v *. 3600.
                | Min  -> t := !t +. float_of_string v *. 60.
                | Sec  -> t := !t +. float_of_string v
                | Msec -> t := !t +. float_of_string v /. 1000. ) re.group;
            Some( !t )
      with _ -> grep_time out l
    end

let stepsregexp s_re s_group_num =
  {steps_re = (Str.regexp s_re); steps_group_num = s_group_num}

let rec grep_steps out = function
  | [] -> None
  | re :: l ->
    begin try
	    ignore (Str.search_forward re.steps_re out 0);
	    let v = Str.matched_group (re.steps_group_num) out in
	    Some(int_of_string v)
      with _ -> grep_steps out l
    end

(** *)

type prover_answer =
  | Valid
  | Invalid
  | Timeout
  | OutOfMemory
  | StepsLimitExceeded
  | Unknown of string
  | Failure of string
  | HighFailure

type prover_result = {
  pr_answer : prover_answer;
  pr_status : Unix.process_status;
  pr_output : string;
  pr_time   : float;
  pr_steps  : int;		(* -1 if unknown *)
  pr_model  : model_element list;
}

type prover_result_parser = {
  prp_regexps     : (Str.regexp * prover_answer) list;
  prp_timeregexps : timeregexp list;
  prp_stepsregexp : stepsregexp list;
  prp_exitcodes   : (int * prover_answer) list;
  prp_model_parser : Model_parser.model_parser;
}

let print_prover_answer fmt = function
  | Valid -> fprintf fmt "Valid"
  | Invalid -> fprintf fmt "Invalid"
  | Timeout -> fprintf fmt "Timeout"
  | OutOfMemory -> fprintf fmt "Ouf Of Memory"
  | StepsLimitExceeded -> fprintf fmt "Steps limit exceeded"
  | Unknown "" -> fprintf fmt "Unknown"
  | Failure "" -> fprintf fmt "Failure"
  | Unknown s -> fprintf fmt "Unknown (%s)" s
  | Failure s -> fprintf fmt "Failure (%s)" s
  | HighFailure -> fprintf fmt "HighFailure"

let print_prover_status fmt = function
  | Unix.WSTOPPED n -> fprintf fmt "stopped by signal %d" n
  | Unix.WSIGNALED n -> fprintf fmt "killed by signal %d" n
  | Unix.WEXITED n -> fprintf fmt "exited with status %d" n

let print_steps fmt s =
  if s >= 0 then fprintf fmt ", %d steps)" s

let print_prover_result fmt
  {pr_answer=ans; pr_status=status; pr_output=out; pr_time=t; pr_steps=s} =
  fprintf fmt "%a (%.2fs%a)" print_prover_answer ans t print_steps s;
  if ans == HighFailure then
    fprintf fmt "@\nProver exit status: %a@\nProver output:@\n%s@."
      print_prover_status status out

let rec grep out l = match l with
  | [] ->
      HighFailure
  | (re,pa) :: l ->
      begin try
        ignore (Str.search_forward re out 0);
        match pa with
        | Valid | Invalid | Timeout | OutOfMemory | StepsLimitExceeded -> pa
        | Unknown s -> Unknown (Str.replace_matched s out)
        | Failure s -> Failure (Str.replace_matched s out)
        | HighFailure -> assert false
      with Not_found -> grep out l end

type post_prover_call = unit -> prover_result

type prover_call = {
  call : Unix.process_status -> post_prover_call;
  pid  : int
}

type pre_prover_call = unit -> prover_call

let save f = f ^ ".save"

let rec debug_print_model_with_loc model =
  match model with
  | [] -> ()
  | m_element::t -> begin
    let loc_string = match m_element.me_location with
      | None -> "\"no location\""
      | Some loc -> begin
	Loc.report_position str_formatter loc;
	flush_str_formatter ()
      end in

    Debug.dprintf debug "Call_provers: %s = %s@." m_element.me_name m_element.me_value;
    Debug.dprintf debug "  Call_provers: At %s" loc_string;

    debug_print_model_with_loc t
  end

let parse_prover_run res_parser time out ret on_timelimit timelimit ~printer_mapping =
  let ans = match ret with
    | Unix.WSTOPPED n ->
        Debug.dprintf debug "Call_provers: stopped by signal %d@." n;
        grep out res_parser.prp_regexps
    | Unix.WSIGNALED n ->
        Debug.dprintf debug "Call_provers: killed by signal %d@." n;
        grep out res_parser.prp_regexps
    | Unix.WEXITED n ->
        Debug.dprintf debug "Call_provers: exited with status %d@." n;
        (try List.assoc n res_parser.prp_exitcodes
         with Not_found -> grep out res_parser.prp_regexps)
  in
  Debug.dprintf debug "Call_provers: prover output:@\n%s@." out;
  let time = Opt.get_def (time) (grep_time out res_parser.prp_timeregexps) in
  let steps = Opt.get_def (-1) (grep_steps out res_parser.prp_stepsregexp) in
  let ans = match ans with
    | Unknown _ | HighFailure when on_timelimit && timelimit > 0
      && time >= (0.9 *. float timelimit) -> Timeout
    | _ -> ans
  in
  let model = res_parser.prp_model_parser out printer_mapping in
  Debug.dprintf debug "Call_provers: model:@.";
  debug_print_model_with_loc model;
  { pr_answer = ans;
    pr_status = ret;
    pr_output = out;
    pr_time   = time;
    pr_steps  = steps;
    pr_model  = model;
  }

let actualcommand command timelimit memlimit stepslimit file =
  let arglist = Cmdline.cmdline_split command in
  let use_stdin = ref true in
  (* FIXME: use_stdin is never modified below ?? *)
  let on_timelimit = ref false in
  let cmd_regexp = Str.regexp "%\\(.\\)" in
  let replace s = match Str.matched_group 1 s with
    | "%" -> "%"
    | "f" -> file
    | "t" -> on_timelimit := true; string_of_int timelimit
    | "T" -> string_of_int (succ timelimit)
    | "U" -> string_of_int (2 * timelimit + 1)
    | "m" -> string_of_int memlimit
    (* FIXME: libdir and datadir can be changed in the configuration file
       Should we pass them as additional arguments? Or would it be better
       to prepare the command line in a separate function? *)
    | "l" -> Config.libdir
    | "d" -> Config.datadir
    | "o" -> Config.libobjdir
    | "S" -> string_of_int stepslimit
    | _ -> failwith "unknown specifier, use %%, %f, %t, %T, %U, %m, %l, %d or %S"
  in
  (* FIXME: are we sure that tuples are evaluated from left to right ? *)
  List.map (Str.global_substitute cmd_regexp replace) arglist,
  !use_stdin, !on_timelimit

let  call_on_file ~command ?(timelimit=0) ?(memlimit=0) ?(stepslimit=(-1))
                 ~res_parser
		 ~printer_mapping
                 ?(cleanup=false) ?(inplace=false) ?(redirect=true) fin =

  let command, use_stdin, on_timelimit =
    try actualcommand command timelimit memlimit stepslimit fin
    with e ->
      if cleanup then Sys.remove fin;
      if inplace then Sys.rename (save fin) fin;
      raise e in
  let exec = List.hd command in
  Debug.dprintf debug "@[<hov 2>Call_provers: command is: %a@]@."
    (Pp.print_list Pp.space pp_print_string) command;
  let argarray = Array.of_list command in

  fun () ->
    let fd_in = if use_stdin then Unix.openfile fin [Unix.O_RDONLY] 0 else Unix.stdin in
    let fout,cout,fd_out,fd_err =
      if redirect then
        let fout,cout = Filename.open_temp_file (Filename.basename fin) ".out" in
        let fd_out = Unix.descr_of_out_channel cout in
        fout, cout, fd_out, fd_out
      else
        "", stdout, Unix.stdout, Unix.stderr in
    let time = Unix.gettimeofday () in
    let pid = Unix.create_process exec argarray fd_in fd_out fd_err in
    if use_stdin then Unix.close fd_in;
    if redirect then close_out cout;

    let call = fun ret ->
      let time = Unix.gettimeofday () -. time in
      let out =
        if redirect then
          let cout = open_in fout in
          let out = Sysutil.channel_contents cout in
          close_in cout;
          out
        else "" in

      fun () ->
        if Debug.test_noflag debug then begin
          if cleanup then Sys.remove fin;
          if inplace then Sys.rename (save fin) fin;
          if redirect then Sys.remove fout;
        end;
        parse_prover_run res_parser time out ret on_timelimit timelimit ~printer_mapping
    in
    { call = call; pid = pid }

let call_on_buffer ~command ?(timelimit=0) ?(memlimit=0) ?(stepslimit=(-1))
                   ~res_parser ~filename
		   ~printer_mapping
                   ?(inplace=false) buffer =

  let fin,cin =
    if inplace then begin
      Sys.rename filename (save filename);
      filename, open_out filename
    end else
      Filename.open_temp_file "why_" ("_" ^ filename) in
  Buffer.output_buffer cin buffer; close_out cin;
  call_on_file ~command ~timelimit ~memlimit ~stepslimit
               ~res_parser ~printer_mapping ~cleanup:true ~inplace fin

let query_call pc =
  let pid, ret = Unix.waitpid [Unix.WNOHANG] pc.pid in
  if pid = 0 then None else Some (pc.call ret)

let wait_on_call pc =
  let _, ret = Unix.waitpid [] pc.pid in pc.call ret

let post_wait_call pc ret = pc.call ret

let prover_call_pid pc = pc.pid

let set_socket_name =
  Prove_client.set_socket_name

type server_id = int

let gen_id =
  let x = ref 0 in
  fun () ->
    incr x;
    !x

type save_data =
  { vc_file      : string;
    is_temporary : bool;
    timeout      : int;
    res_parser   : prover_result_parser;
    printer_mapping : Printer.printer_mapping;
  }

let regexs = Hashtbl.create 17

let prove_file_server ~res_parser ~command ~timelimit
                      ~memlimit ~stepslimit ~printer_mapping ?(inplace=false) file =
  let id = gen_id () in
  let cmd, _, _ =
    actualcommand command timelimit memlimit stepslimit file in
  let saved_data =
    { vc_file      = file;
      is_temporary = not inplace;
      timeout      = timelimit;
      res_parser   = res_parser;
      printer_mapping = printer_mapping } in
  Hashtbl.add regexs id saved_data;
  Prove_client.send_request ~id ~timelimit ~memlimit ~cmd;
  id

let read_and_delete_file fn =
  let cin = open_in fn in
  let buf = Buffer.create 1024 in
  try
    while true do
      Buffer.add_string buf (input_line cin);
      Buffer.add_char buf '\n'
    done;
    assert false
  with End_of_file ->
  begin
    close_in cin;
    Sys.remove fn;
    Buffer.contents buf
  end

let handle_answer answer =
  let id = answer.Prove_client.id in
  let save = Hashtbl.find regexs id in
  Hashtbl.remove regexs id;
  if save.is_temporary then
    Sys.remove save.vc_file;
  let out = read_and_delete_file answer.Prove_client.out_file in
  let ret = Unix.WEXITED answer.Prove_client.exit_code in
  let printer_mapping = save.printer_mapping in
  let ans =
    parse_prover_run save.res_parser
                     answer.Prove_client.time
                     out ret answer.Prove_client.timeout save.timeout
                     ~printer_mapping
  in
  id, ans

let wait_for_server_result () =
  List.map handle_answer (Prove_client.read_answers ())
