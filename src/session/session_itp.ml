




open Stdlib

module Hprover = Whyconf.Hprover

let debug = Debug.register_info_flag "session_itp"
    ~desc:"Pring@ debugging@ messages@ about@ Why3@ session@ \
           creation,@ reading@ and@ writing."

let debug_stack_trace = Debug.lookup_flag "stack_trace"

type transID = int
type proofNodeID = int
type proofAttemptID = int

let print_proofNodeID fmt id =
  Format.fprintf fmt "%d" id

type theory = {
  theory_name                   : Ident.ident;
  theory_goals                  : proofNodeID list;
  theory_parent_name            : string;
  mutable theory_detached_goals : proofNodeID list;
  mutable theory_checksum       : Termcode.checksum option;
}

let theory_name t = t.theory_name
let theory_goals t = t.theory_goals
let theory_detached_goals t = t.theory_detached_goals

type proof_parent = Trans of transID | Theory of theory

type proof_attempt_node = {
  parent                 : proofNodeID;
  prover                 : Whyconf.prover;
  limit                  : Call_provers.resource_limit;
  mutable proof_state    : Call_provers.prover_result option;
  (* None means that the call was not done or never returned *)
  mutable proof_obsolete : bool;
  proof_script           : string option;  (* non empty for external ITP *)
}

type proof_node = {
  proofn_name                    : Ident.ident;
  proofn_task                    : Task.task;
  proofn_table                   : Task.names_table option;
  proofn_parent                  : proof_parent;
  proofn_checksum                : Termcode.checksum option;
  proofn_shape                   : Termcode.shape;
  proofn_attempts                : proofAttemptID Hprover.t;
  mutable proofn_transformations : transID list;
}

type transformation_node = {
  transf_name                      : string;
  transf_args                      : string list;
  transf_subtasks                  : proofNodeID list;
  transf_parent                    : proofNodeID;
  mutable transf_detached_subtasks : proofNodeID list;
}

type file = {
  file_name              : string;
  file_format            : string option;
  file_theories          : theory list;
  file_detached_theories : theory list;
}

type any =
  | AFile of file
  | ATh of theory
  | ATn of transID
  | APn of proofNodeID
  | APa of proofAttemptID

module Hpn = Hint
module Htn = Hint
module Hpan = Hint

type session = {
  proofAttempt_table            : proof_attempt_node Hint.t;
  mutable next_proofAttemptID   : int;
  proofNode_table               : proof_node Hint.t;
  mutable next_proofNodeID      : int;
  trans_table                   : transformation_node Hint.t;
  mutable next_transID          : int;
  session_dir                   : string; (** Absolute path *)
  session_files                 : file Hstr.t;
  mutable session_shape_version : int;
  session_prover_ids            : int Hprover.t;
}

let theory_parent s th =
  Hstr.find s.session_files th.theory_parent_name

(* TODO replace *)
let init_Hpn (s : session) (h: 'a Hpn.t) (d: 'a) : unit =
  Hint.iter (fun k _pn -> Hpn.replace h k d) s.proofNode_table

let init_Htn (s : session) (h: 'a Htn.t) (d: 'a) : unit =
  Hint.iter (fun k _pn -> Htn.replace h k d) s.trans_table

(*
let _session_iter_proofNode f s =
  Hint.iter f s.proofNode_table
*)

let session_iter_proof_attempt f s =
  Hint.iter f s.proofAttempt_table

(* This is not needed. Keeping it as information on the structure
type tree = {
    tree_node_id : proofNodeID;
    tree_goal_name : string;
    tree_proof_attempts : proof_attempt list; (* proof attempts on this node *)
    tree_transformations : (transID * string * tree list) list;
                                (* transformations on this node *)
  }
*)

(*
let rec get_tree s id : tree =
  let t = Hint.find s.proofNode_table id in
  let pal =
    Hprover.fold (fun _ pa acc -> pa.proofa_attempt::acc) t.proofn_attempts []
  in
  let trl = List.map (get_trans s) t.proofn_transformations in
  { tree_node_id = id;
    tree_goal_name = t.proofn_name.Ident.id_string;
    tree_proof_attempts = pal;
    tree_transformations = trl;
  }

and get_trans s id =
  let tr = Hint.find s.trans_table id in
  (id, tr.transf_name, List.map (get_tree s) tr.transf_subtasks)
*)

(*
let get_theories s =
  Hstr.fold
    (fun _fn f acc ->
     let c =
       List.map
         (fun th -> (th.theory_name.Ident.id_string, th.theory_goals))
         f.file_theories
     in
     (f,c) :: acc)
    s.session_files []
 *)

let get_files s = s.session_files
let get_dir s = s.session_dir

let get_shape_version s = s.session_shape_version

(*
let get_node (s : session) (n : int) =
  let _ = Hint.find s.proofNode_table n in n

let get_trans (s : session) (n : int) =
  let _ = Hint.find s.trans_table n in n
*)

(* Generation of new IDs *)
let gen_transID (s : session) =
  let id = s.next_transID in
  s.next_transID <- id + 1;
  id

let gen_proofNodeID (s : session) =
  let id = s.next_proofNodeID in
  s.next_proofNodeID <- id + 1;
  id

let gen_proofAttemptID (s : session) =
  let id = s.next_proofAttemptID in
  s.next_proofAttemptID <- id + 1;
  id

(* Get elements of the session tree *)

exception BadID

let get_proof_attempt_node (s : session) (id : proofAttemptID) =
  try
    Hint.find s.proofAttempt_table id
  with Not_found -> raise BadID

let get_proofNode (s : session) (id : proofNodeID) =
  try
    Hint.find s.proofNode_table id
  with Not_found -> raise BadID

let get_task (s:session) (id:proofNodeID) =
  let node = get_proofNode s id in
  node.proofn_task

let get_table (s: session) (id: proofNodeID) =
  let node = get_proofNode s id in
  node.proofn_table

let get_transfNode (s : session) (id : transID) =
  try
    Hint.find s.trans_table id
  with Not_found -> raise BadID

let get_transformations (s : session) (id : proofNodeID) =
  (get_proofNode s id).proofn_transformations

let get_proof_attempt_ids (s : session) (id : proofNodeID) =
  (get_proofNode s id).proofn_attempts

let get_proof_attempt_parent (s : session) (a : proofAttemptID) =
  (get_proof_attempt_node s a).parent

let get_proof_attempts (s : session) (id : proofNodeID) =
  Hprover.fold (fun _ a l ->
                let pa = get_proof_attempt_node s a in
                pa :: l)
               (get_proofNode s id).proofn_attempts []

let get_sub_tasks (s : session) (id : transID) =
  (get_transfNode s id).transf_subtasks

let get_detached_sub_tasks (s : session) (id : transID) =
  (get_transfNode s id).transf_detached_subtasks

let get_transf_args (s : session) (id : transID) =
  (get_transfNode s id).transf_args

let get_transf_name (s : session) (id : transID) =
  (get_transfNode s id).transf_name

let get_proof_name (s : session) (id : proofNodeID) =
  (get_proofNode s id).proofn_name

let get_proof_parent (s : session) (id : proofNodeID) =
  (get_proofNode s id).proofn_parent

let get_trans_parent (s : session) (id : transID) =
  (get_transfNode s id).transf_parent

(* TODO to be done with detached transformations *)
let get_detached_trans (_s: session) (_id: proofNodeID) =
  []

let is_detached (s: session) (a: any) =
  match a with
  | AFile _file -> false
  | ATh th     ->
    let parent_name = th.theory_parent_name in
    let parent = Hstr.find s.session_files parent_name in
    List.exists (fun x -> x = th) parent.file_detached_theories
  | ATn tn     ->
    let pn_id = get_trans_parent s tn in
    let pn = get_proofNode s pn_id in
    pn.proofn_task = None ||
    List.exists (fun x -> x = tn) (get_detached_trans s pn_id)
  | APn pn     ->
    let pn = get_proofNode s pn in
    pn.proofn_task = None
  | APa pa     ->
    let pa = get_proof_attempt_node s pa in
    let pn_id = pa.parent in
    let pn = get_proofNode s pn_id in
    pn.proofn_task = None

let rec get_encapsulating_theory s any =
  match any with
  | AFile _f -> assert (false)
  | ATh th -> th
  | ATn tn ->
      let pn_id = get_trans_parent s tn in
      get_encapsulating_theory s (APn pn_id)
  | APn pn ->
      (match get_proof_parent s pn with
      | Theory th -> th
      | Trans tn -> get_encapsulating_theory s (ATn tn)
      )
  | APa pa ->
      let pn = get_proof_attempt_parent s pa in
      get_encapsulating_theory s (APn pn)

let get_encapsulating_file s any =
  match any with
  | AFile f -> f
  | ATh th -> theory_parent s th
  | _ ->
      let th = get_encapsulating_theory s any in
      theory_parent s th


(* Remove elements of the session tree *)

let remove_transformation (s : session) (id : transID) =
  let nt = get_transfNode s id in
  Hint.remove s.trans_table id;
  let pn = get_proofNode s nt.transf_parent in
  let trans_up = List.filter (fun tid -> tid != id) pn.proofn_transformations in
  pn.proofn_transformations <- trans_up

let remove_proof_attempt (s : session) (id : proofNodeID)
    (prover : Whyconf.prover) =
  let pn = get_proofNode s id in
  let pa = Hprover.find pn.proofn_attempts prover in
  Hprover.remove pn.proofn_attempts prover;
  Hint.remove s.proofAttempt_table pa

let remove_proof_attempt_pa s (id: proofAttemptID) =
  let pa = get_proof_attempt_node s id in
  let pn = pa.parent in
  let prover = pa.prover in
  remove_proof_attempt s pn prover

let mark_obsolete s (id: proofAttemptID) =
  let pa = get_proof_attempt_node s id in
  pa.proof_obsolete <- true

(* Iterations functions on the session tree *)

let rec fold_all_any_of_transn s f acc trid =
  let tr = get_transfNode s trid in
  let acc =
    List.fold_left
      (fold_all_any_of_proofn s f)
      acc tr.transf_subtasks
  in
  f acc (ATn trid)

and fold_all_any_of_proofn s f acc pnid =
  let pn = get_proofNode s pnid in
  let acc =
    List.fold_left
      (fun acc trid ->
        fold_all_any_of_transn s f acc trid)
      acc pn.proofn_transformations
  in
  let acc =
    Hprover.fold
      (fun _p paid acc ->
        f acc (APa paid))
      pn.proofn_attempts acc
  in
  f acc (APn pnid)

let fold_all_any_of_theory s f acc th =
  let acc = List.fold_left (fold_all_any_of_proofn s f) acc th.theory_goals in
  f acc (ATh th)

let fold_all_any_of_file s f acc file =
  let acc =
    List.fold_left (fold_all_any_of_theory s f) acc file.file_theories in
  f acc (AFile file)

let fold_all_any s f acc any =
  match any with
  | AFile file -> fold_all_any_of_file s f acc file
  | ATh th -> fold_all_any_of_theory s f acc th
  | APn pn -> fold_all_any_of_proofn s f acc pn
  | ATn tn -> fold_all_any_of_transn s f acc tn
  | APa _ -> f acc any

exception RemoveError

(* Cannot remove a proof_attempt that was scheduled but did not finish yet.
   It can be interrupted though. *)
let removable_proof_attempt s pa =
  let pa = get_proof_attempt_node s pa in
  match pa.proof_state with
  | None -> false
  | Some _pr -> true

let any_removable s any =
  match any with
  | APa pa -> removable_proof_attempt s pa
  | _ -> true

(* Check whether the subtree [n] contains an unremovable proof_attempt
   (ie: scheduled or running) *)
let check_removable s (n: any) =
  fold_all_any s (fun acc any -> any_removable s any && acc) true n

let remove_subtree s (n: any) ~notification : unit =

  let remove s (n: any) =
    (* These removal functions should not be used for direct removal: subtrees
       must be removed first.  *)
    let remove_file s (f: file) =
      Hstr.remove s.session_files f.file_name in
    let remove_proof_node s pnid =
      Hint.remove s.proofNode_table pnid in
    let remove_theory _s (_th: theory) =
      (* Not in any table *)
      () in
    match n with
    | ATn tn -> remove_transformation s tn
    | APa pa -> remove_proof_attempt_pa s pa
    | AFile f -> remove_file s f
    | APn pn -> remove_proof_node s pn
    | ATh th -> remove_theory s th
  in

  (* If a subtree cannot be removed then fail *)
  if not (check_removable s n) then
    raise RemoveError;

  match n with
  | APn _pn when not (is_detached s n) -> raise RemoveError
  | ATh _th when not (is_detached s n) -> raise RemoveError
  | _ ->
    fold_all_any s (fun _ x -> remove s x; notification x) () n

let rec fold_all_sub_goals_of_proofn s f acc pnid =
  let pn = get_proofNode s pnid in
  let acc =
    List.fold_left
      (fun acc trid ->
         let tr = get_transfNode s trid in
         List.fold_left
           (fold_all_sub_goals_of_proofn s f)
           acc tr.transf_subtasks)
      acc pn.proofn_transformations
  in
  f acc pn

let fold_all_sub_goals_of_theory s f acc th =
  List.fold_left (fold_all_sub_goals_of_proofn s f) acc th.theory_goals

let theory_iter_proofn s f th =
  fold_all_sub_goals_of_theory s (fun _ -> f) () th

let theory_iter_proof_attempt s f th =
  theory_iter_proofn s
    (fun pn -> Hprover.iter (fun _ pan ->
                             let pan = get_proof_attempt_node s pan in
                             f pan)
         pn.proofn_attempts) th

(**************)
(* Copy/Paste *)
(**************)

let get_any_parent s a =
  match a with
  | AFile _f -> None
  | ATh th  -> Some (AFile (theory_parent s th))
  | ATn tr  -> Some (APn (get_trans_parent s tr))
  | APn pn  ->
      (match (get_proofNode s pn).proofn_parent with
      | Theory th -> Some (ATh th)
      | Trans tr -> Some (ATn tr))
  | APa pa  ->
      Some (APn (get_proof_attempt_node s pa).parent)

(* True if bid is an ancestor of aid, false if not *)
let rec is_below s (aid: any) (bid: any) =
  aid = bid ||
  match (get_any_parent s aid) with
  | None     -> false
  | Some pid -> is_below s pid bid

open Format
open Ident

let print_proof_attempt fmt pa =
  fprintf fmt "%a tl=%d %a"
          Whyconf.print_prover pa.prover
          pa.limit.Call_provers.limit_time
          (Pp.print_option Call_provers.print_prover_result) pa.proof_state

let rec print_proof_node s (fmt: Format.formatter) p =
  let pn = get_proofNode s p in
  let parent = match pn.proofn_parent with
  | Theory t -> t.theory_name.id_string
  | Trans id -> (get_transfNode s id).transf_name
  in
  fprintf fmt
    "@[<hv 1> Goal %s;@ parent %s;@ sum %s;@ @[<hv 1>[%a]@]@ @[<hv 1>[%a]@]@]"
    pn.proofn_name.id_string parent
    (Opt.fold (fun _ a -> Termcode.string_of_checksum a) "None" pn.proofn_checksum)
    (Pp.print_list Pp.semi print_proof_attempt)
      (Hprover.fold (fun _key e l ->
                     let e = get_proof_attempt_node s e in
                     e :: l)
        pn.proofn_attempts [])
      (Pp.print_list Pp.semi (print_trans_node s)) pn.proofn_transformations

and print_trans_node s fmt id =
  let tn = get_transfNode s id in
  let args = get_transf_args s id in
  let name = tn.transf_name in
  let l = tn.transf_subtasks in
  let parent = (get_proofNode s tn.transf_parent).proofn_name.id_string in
  fprintf fmt "@[<hv 1> Trans %s;@ args %a;@ parent %s;@ [%a]@]"
    name (Pp.print_list Pp.colon pp_print_string) args parent
    (Pp.print_list Pp.semi (print_proof_node s)) l

let print_theory s fmt th : unit =
  fprintf fmt "@[<hv 2> Theory %s;@ [%a]@]" th.theory_name.Ident.id_string
    (Pp.print_list Pp.semi (fun fmt a -> print_proof_node s fmt a)) th.theory_goals

let print_file s fmt (file, thl) =
  fprintf fmt "@[<hv 2> File %s;@ [%a]@]" file.file_name
    (Pp.print_list Pp.semi (print_theory s)) thl

let print_s s fmt =
  fprintf fmt "@[%a@]" (Pp.print_list Pp.semi (print_file s))

let _print_session fmt s =
  let l = Hstr.fold (fun _ f acc -> (f,f.file_theories) :: acc) (get_files s) [] in
  fprintf fmt "%a@." (print_s s) l;;


let empty_session ?shape_version dir =
  let shape_version = match shape_version with
    | Some v -> v
    | None -> Termcode.current_shape_version
  in
  { proofAttempt_table = Hint.create 97;
    next_proofAttemptID = 0;
    proofNode_table = Hint.create 97;
    next_proofNodeID = 0;
    trans_table = Hint.create 97;
    next_transID = 0;
    session_dir = dir;
    session_files = Hstr.create 3;
    session_shape_version = shape_version;
    session_prover_ids = Hprover.create 7;
  }

(**************************************************)
(* proof node/attempt/transformation manipulation *)
(**************************************************)

exception AlreadyExist

let add_proof_attempt session prover limit state obsolete edit parentID =
  let pn = get_proofNode session parentID in
  try
    let _ = Hprover.find pn.proofn_attempts prover in
    raise AlreadyExist
  with Not_found ->
    let id = gen_proofAttemptID session in
    let pa = { parent = parentID;
               prover = prover;
               limit = limit;
               proof_state = state;
               proof_obsolete = obsolete;
               proof_script = edit } in
    Hprover.add pn.proofn_attempts prover id;
    Hint.replace session.proofAttempt_table id pa;
    id

let graft_proof_attempt ?file (s : session) (id : proofNodeID) (pr : Whyconf.prover)
    ~limit =
  let pn = get_proofNode s id in
  try
    let id = Hprover.find pn.proofn_attempts pr in
    let pa = Hint.find s.proofAttempt_table id in
    let pa = { pa with limit = limit;
               proof_state = None;
               proof_obsolete = false} in
    Hint.replace s.proofAttempt_table id pa;
    id
  with Not_found ->
    add_proof_attempt s pr limit None false file id


(* [mk_proof_node s n t p id] register in the session [s] a proof node
   of proofNodeID [id] of parent [p] of task [t] *)
let mk_proof_node ~version (s : session) (n : Ident.ident) (t : Task.task)
    (parent : proof_parent) (node_id : proofNodeID) =
  let tables = Args_wrapper.build_name_tables t in
  let sum = Some (Termcode.task_checksum ~version t) in
  let shape = Termcode.t_shape_task ~version t in
  let pn = { proofn_name = n;
             proofn_task = t;
             proofn_table = Some tables;
             proofn_parent = parent;
             proofn_checksum = sum;
             proofn_shape = shape;
             proofn_attempts = Hprover.create 7;
             proofn_transformations = [] } in
  Hint.add s.proofNode_table node_id pn

let mk_proof_node_no_task (s : session) (n : Ident.ident)
    (parent : proof_parent) (node_id : proofNodeID) sum shape =
  let pn = { proofn_name = n;
             proofn_task = None;
             proofn_table = None;
             proofn_parent = parent;
             proofn_checksum = sum;
             proofn_shape = shape;
             proofn_attempts = Hprover.create 7;
             proofn_transformations = [] } in
  Hint.add s.proofNode_table node_id pn

(* Detach a new proof to a proof_parent *)
let graft_detached_proof_on_parent s (pn: proofNodeID) (parent: proof_parent) =
  match parent with
  | Theory th ->
      th.theory_detached_goals <- th.theory_detached_goals @ [pn]
  | Trans tr_id ->
      let tr = get_transfNode s tr_id in
      tr.transf_detached_subtasks <- tr.transf_detached_subtasks @ [pn]

(* Intended as a feature to save a proof (also for testing detached stuff) *)
let copy_proof_node_as_detached (s: session) (pn_id: proofNodeID) =
  let pn = get_proofNode s pn_id in
  let new_pn_id = gen_proofNodeID s in
  let parent = pn.proofn_parent in
  let new_goal = Ident.id_register (Ident.id_clone pn.proofn_name) in
  let checksum = pn.proofn_checksum in
  let shape = pn.proofn_shape in
  let _: unit = mk_proof_node_no_task s new_goal parent new_pn_id checksum shape in
  graft_detached_proof_on_parent s new_pn_id parent;
  new_pn_id

let _mk_proof_node_task (s : session) (t : Task.task)
    (parent : proof_parent) (node_id : proofNodeID) =
  let name,_,_ = Termcode.goal_expl_task ~root:false t in
  mk_proof_node ~version:s.session_shape_version s name t parent node_id

let mk_transf_proof_node (s : session) (parent_name : string)
    (tid : transID) (index : int) (t : Task.task) =
  let id = gen_proofNodeID s in
  let gid,_expl,_ = Termcode.goal_expl_task ~root:false t in
(*  let expl = match expl with
    | None -> string_of_int index ^ "."
    | Some e -> string_of_int index ^ ". " ^ e
  in
    let expl = Some expl in *)
  let goal_name = parent_name ^ "." ^ string_of_int index in
  let goal_name = Ident.id_register (Ident.id_derive goal_name gid) in
  mk_proof_node ~version:s.session_shape_version s goal_name t (Trans tid) id;
  id

let mk_transf_node (s : session) (id : proofNodeID) (node_id : transID)
    (name : string) (args : string list) (pnl : proofNodeID list) =
  let pn = get_proofNode s id in
  let tn = { transf_name = name;
             transf_args = args;
             transf_subtasks = pnl;
             transf_parent = id;
             transf_detached_subtasks = [] } in
  Hint.add s.trans_table node_id tn;
  pn.proofn_transformations <- node_id::pn.proofn_transformations

exception BadCopyDetached of string

let rec copy_structure ~notification s from_any to_any : unit =
  match from_any, to_any with
  | APn from_id, APn to_id ->
    let transformations = get_transformations s from_id in
    let new_transformations =
      List.map (fun x ->
        let tr_id = gen_transID s in
        let old_tr = get_transfNode s x in
        mk_transf_node s to_id tr_id old_tr.transf_name old_tr.transf_args [];
        notification ~parent:to_any (ATn tr_id);
        copy_structure ~notification s (ATn x) (ATn tr_id);
        tr_id) transformations in
    (get_proofNode s to_id).proofn_transformations <- new_transformations;
    Hprover.iter (fun _k old_pa ->
      let old_pa = get_proof_attempt_node s old_pa in
      let pa_id =
        add_proof_attempt s old_pa.prover old_pa.limit None true None to_id in
      notification ~parent:to_any (APa pa_id))
      (get_proofNode s from_id).proofn_attempts
  | ATn from_tn, ATn to_tn ->
    let sub_tasks = get_sub_tasks s from_tn in
    let new_sub_tasks =
      List.map (fun old_pn_id ->
        let old_pn = get_proofNode s old_pn_id in
        let pn_id = gen_proofNodeID s in
        let new_id = Ident.id_register (Ident.id_clone old_pn.proofn_name) in
        mk_proof_node_no_task s new_id (Trans to_tn)
          pn_id old_pn.proofn_checksum old_pn.proofn_shape;
        notification ~parent:to_any (APn pn_id);
        copy_structure ~notification s (APn old_pn_id) (APn pn_id);
        pn_id) sub_tasks in
    let tr = get_transfNode s to_tn in
    tr.transf_detached_subtasks <- new_sub_tasks
  | _ -> raise (BadCopyDetached "copy_structure")

let graft_transf  (s : session) (id : proofNodeID) (name : string)
    (args : string list) (tl : Task.task list) =
  let tid = gen_transID s in
  let parent_name = (get_proofNode s id).proofn_name.Ident.id_string in
  let sub_tasks = List.mapi (mk_transf_proof_node s parent_name tid) tl in
  mk_transf_node s id tid name args sub_tasks;
  tid


let update_proof_attempt ?(obsolete=false) s id pr st =
  try
    let n = get_proofNode s id in
    let pa = Hprover.find n.proofn_attempts pr in
    let pa = get_proof_attempt_node s pa in
    pa.proof_state <- Some st;
    pa.proof_obsolete <- obsolete
  with
  | BadID when not (Debug.test_flag debug_stack_trace) -> assert false

(****************************)
(*     session opening      *)
(****************************)

let db_filename = "why3session.xml"
let shape_filename = "why3shapes"
let compressed_shape_filename = "why3shapes.gz"
let session_dir_for_save = ref "."

exception LoadError of Xml.element * string
exception SessionFileError of string

let bool_attribute field r def =
  try
    match List.assoc field r.Xml.attributes with
    | "true" -> true
    | "false" -> false
    | _ -> assert false
  with Not_found -> def

let int_attribute_def field r def =
  try
    int_of_string (List.assoc field r.Xml.attributes)
  with Not_found | Invalid_argument _ -> def

let string_attribute_def field r def=
  try
    List.assoc field r.Xml.attributes
  with Not_found -> def

let string_attribute_opt field r =
  try
    Some (List.assoc field r.Xml.attributes)
  with Not_found -> None

let string_attribute field r =
  try
    List.assoc field r.Xml.attributes
  with Not_found ->
    eprintf "[Error] missing required attribute '%s' from element '%s'@."
      field r.Xml.name;
    assert false

let load_result r =
  match r.Xml.name with
  | "result" ->
    let status = string_attribute "status" r in
    let answer =
      match status with
      | "valid" -> Call_provers.Valid
      | "invalid" -> Call_provers.Invalid
      | "unknown" -> Call_provers.Unknown ("", None)
      | "timeout" -> Call_provers.Timeout
      | "outofmemory" -> Call_provers.OutOfMemory
      | "failure" -> Call_provers.Failure ""
      | "highfailure" -> Call_provers.HighFailure
      | "steplimitexceeded" -> Call_provers.StepLimitExceeded
      | "stepslimitexceeded" -> Call_provers.StepLimitExceeded
      | s ->
        Warning.emit
          "[Warning] Session.load_result: unexpected status '%s'@." s;
        Call_provers.HighFailure
    in
    let time =
      try float_of_string (List.assoc "time" r.Xml.attributes)
      with Not_found -> 0.0
    in
    let steps =
      try int_of_string (List.assoc "steps" r.Xml.attributes)
      with Not_found -> -1
    in
    Some {
      Call_provers.pr_answer = answer;
      Call_provers.pr_time = time;
      Call_provers.pr_output = "";
      Call_provers.pr_status = Unix.WEXITED 0;
      Call_provers.pr_steps = steps;
      Call_provers.pr_model = Model_parser.default_model;
    }
  | "undone" -> None
  | "unedited" -> None
  | s ->
    Warning.emit "[Warning] Session.load_result: unexpected element '%s'@."
      s;
    None

let load_option attr g =
  try Some (List.assoc attr g.Xml.attributes)
  with Not_found -> None

let load_ident elt =
  let name = string_attribute "name" elt in
  let label = List.fold_left
      (fun acc label ->
         match label with
         | {Xml.name = "label"} ->
           let lab = string_attribute "name" label in
           Ident.Slab.add (Ident.create_label lab) acc
         | _ -> acc
      ) Ident.Slab.empty elt.Xml.elements in
  let preid =
    try
      let load_exn attr g = List.assoc attr g.Xml.attributes in
      let file = load_exn "locfile" elt in
      let lnum =  int_of_string (load_exn "loclnum" elt) in
      let cnumb = int_of_string (load_exn "loccnumb" elt) in
      let cnume = int_of_string (load_exn "loccnume" elt) in
      let pos = Loc.user_position file lnum cnumb cnume in
      Ident.id_user ~label name pos
    with Not_found | Invalid_argument _ ->
      Ident.id_fresh ~label name in
  Ident.id_register preid

(* [load_goal s op p g id] loads the goal of parent [p] from the xml
   [g] of nodeID [id] into the session [s] *)
let rec load_goal session old_provers parent g id =
  match g.Xml.name with
  | "goal" ->
    let gname = load_ident g in
    let csum = string_attribute_opt "sum" g in
    let sum = Opt.map Termcode.checksum_of_string csum in
    let shape =
      try Termcode.shape_of_string (List.assoc "shape" g.Xml.attributes)
      with Not_found -> Termcode.shape_of_string ""
    in
    mk_proof_node_no_task session gname parent id sum shape;
    List.iter (load_proof_or_transf session old_provers id) g.Xml.elements;
  | "label" -> ()
  | s ->
    Warning.emit "[Warning] Session.load_goal: unexpected element '%s'@." s

(* [load_proof_or_transf s op pid a] load either a proof attempt or a
   transformation of parent id [pid] from the xml [a] into the session
   [s] *)
and load_proof_or_transf session old_provers pid a =
  match a.Xml.name with
    | "proof" ->
      begin
        let prover = string_attribute "prover" a in
        try
          let prover = int_of_string prover in
          let (p,timelimit,steplimit,memlimit) = Mint.find prover old_provers in
          let res = match a.Xml.elements with
            | [r] -> load_result r
            | [] -> None
            | _ ->
              Warning.emit "[Error] Too many result elements@.";
              raise (LoadError (a,"too many result elements"))
          in
          let edit = load_option "edited" a in
          let edit = match edit with None | Some "" -> None | _ -> edit in
          let obsolete = bool_attribute "obsolete" a false in
          let timelimit = int_attribute_def "timelimit" a timelimit in
	  let steplimit = int_attribute_def "steplimit" a steplimit in
          let memlimit = int_attribute_def "memlimit" a memlimit in
          let limit = { Call_provers.limit_time  = timelimit;
                        Call_provers.limit_mem   = memlimit;
                        Call_provers.limit_steps = steplimit; }
          in
          ignore(add_proof_attempt session p limit res obsolete edit pid)
        with Failure _ | Not_found ->
          Warning.emit "[Error] prover id not listed in header '%s'@." prover;
          raise (LoadError (a,"prover not listing in header"))
      end
    | "transf" ->
      let trname = string_attribute "name" a in
      let rec get_args id =
        match string_attribute_opt ("arg"^(string_of_int id)) a with
        | Some arg -> arg :: (get_args (id+1))
        | None -> []
      in
      let args = get_args 1 in
      let tid = gen_transID session in
      let subtasks_ids =
        List.rev (List.fold_left
                    (fun goals th ->
                       match th.Xml.name with
                       | "goal" -> (gen_proofNodeID session) :: goals
                       | _ -> goals) [] a.Xml.elements)
      in
      mk_transf_node session pid tid trname args subtasks_ids;
      List.iter2
        (load_goal session old_provers (Trans tid))
        a.Xml.elements subtasks_ids;
    | "metas" -> ()
    | "label" -> ()
    | s ->
      Warning.emit
        "[Warning] Session.load_proof_or_transf: unexpected element '%s'@."
        s

let load_theory session parent_name old_provers acc th =
  match th.Xml.name with
  | "theory" ->
    let thname = load_ident th in
    let csum = string_attribute_opt "sum" th in
    let checksum = Opt.map Termcode.checksum_of_string csum in
    let goals = List.rev (List.fold_left (fun goals th -> match th.Xml.name with
        | "goal" -> (gen_proofNodeID session) :: goals
        | _ -> goals) [] th.Xml.elements) in
    let mth = { theory_name = thname;
                theory_checksum = checksum;
                theory_goals = goals;
                theory_parent_name = parent_name;
                theory_detached_goals = [] } in
    List.iter2
      (load_goal session old_provers (Theory mth))
      th.Xml.elements goals;
    mth::acc
  | s ->
    Warning.emit "[Warning] Session.load_theory: unexpected element '%s'@."
      s;
    acc

let load_file session old_provers f =
  match f.Xml.name with
  | "file" ->
    let fn = string_attribute "name" f in
    let fmt = load_option "format" f in
    let ft = List.rev
        (List.fold_left
           (load_theory session fn old_provers) [] f.Xml.elements) in
    let mf = { file_name = fn;
               file_format = fmt;
               file_theories = ft;
               file_detached_theories = [] } in
    Hstr.add session.session_files fn mf;
    old_provers
  | "prover" ->
    (* The id is just for the session file *)
    let id = string_attribute "id" f in
    begin
      try
        let id = int_of_string id in
        let name = string_attribute "name" f in
        let version = string_attribute "version" f in
        let altern = string_attribute_def "alternative" f "" in
        let timelimit = int_attribute_def "timelimit" f 5 in
        let steplimit = int_attribute_def "steplimit" f 1 in
        let memlimit = int_attribute_def "memlimit" f 1000 in
        let p = {Whyconf.prover_name = name;
                 prover_version = version;
                 prover_altern = altern} in
        Mint.add id (p,timelimit,steplimit,memlimit) old_provers
      with Failure _ ->
        Warning.emit "[Warning] Session.load_file: unexpected non-numeric prover id '%s'@." id;
        old_provers
    end
  | s ->
    Warning.emit "[Warning] Session.load_file: unexpected element '%s'@." s;
    old_provers

let build_session (s : session) xml =
  match xml.Xml.name with
  | "why3session" ->
    let shape_version = int_attribute_def "shape_version" xml 1 in
    s.session_shape_version <- shape_version;
    Debug.dprintf debug "[Info] load_session: shape version is %d@\n" shape_version;
    (* just to keep the old_provers somewhere *)
    let old_provers =
      List.fold_left (load_file s) Mint.empty xml.Xml.elements
    in
    Mint.iter
      (fun id (p,_,_,_) ->
         Debug.dprintf debug "prover %d: %a@." id Whyconf.print_prover p;
         Hprover.replace s.session_prover_ids p id)
      old_provers;
    Debug.dprintf debug "[Info] load_session: done@\n"
  | s ->
    Warning.emit "[Warning] Session.load_session: unexpected element '%s'@."
      s

exception ShapesFileError of string

module ReadShapes (C:Compress.S) = struct

let shape = Buffer.create 97
let sum = Strings.create 32

let read_sum_and_shape ch =
  let nsum = C.input ch sum 0 32 in
  if nsum = 0 then raise End_of_file;
  if nsum <> 32 then
    begin
      try
        C.really_input ch sum nsum (32-nsum)
      with End_of_file ->
        raise
          (ShapesFileError
             ("shapes files corrupted (checksum '" ^
                 (String.sub sum 0 nsum) ^
                 "' too short), ignored"))
    end;
  if try C.input_char ch <> ' ' with End_of_file -> true then
      raise (ShapesFileError "shapes files corrupted (space missing), ignored");
    Buffer.clear shape;
    try
      while true do
        let c = C.input_char ch in
        if c = '\n' then raise Exit;
        Buffer.add_char shape c
      done;
      assert false
    with
      | End_of_file ->
        raise (ShapesFileError "shapes files corrupted (premature end of file), ignored");
      | Exit -> Strings.copy sum, Buffer.contents shape


  let use_shapes = ref true

  let fix_attributes ch name attrs =
    if name = "goal" then
      try
        let sum,shape = read_sum_and_shape ch in
        let attrs =
          try
            let old_sum = List.assoc "sum" attrs in
            if sum <> old_sum then
              begin
                Format.eprintf "old sum = %s ; new sum = %s@." old_sum sum;
                raise
                  (ShapesFileError
                     "shapes files corrupted (sums do not correspond)")
              end;
            attrs
          with Not_found -> ("sum", sum) :: attrs
        in
        ("shape",shape) :: attrs
      with _ -> use_shapes := false; attrs
    else attrs

let read_xml_and_shapes xml_fn compressed_fn =
  use_shapes := true;
  try
    let ch = C.open_in compressed_fn in
    let xml = Xml.from_file ~fixattrs:(fix_attributes ch) xml_fn in
    C.close_in ch;
    xml, !use_shapes
  with Sys_error msg ->
    raise (ShapesFileError ("cannot open shapes file for reading: " ^ msg))
end

module ReadShapesNoCompress = ReadShapes(Compress.Compress_none)
module ReadShapesCompress = ReadShapes(Compress.Compress_z)

let read_file_session_and_shapes dir xml_filename =
  try
  let compressed_shape_filename =
    Filename.concat dir compressed_shape_filename
  in
  if Sys.file_exists compressed_shape_filename then
    if Compress.compression_supported then
     ReadShapesCompress.read_xml_and_shapes
       xml_filename compressed_shape_filename
    else
      begin
        Warning.emit "[Warning] could not read goal shapes because \
                                Why3 was not compiled with compress support@.";
        Xml.from_file xml_filename, false
      end
  else
    let shape_filename = Filename.concat dir shape_filename in
    if Sys.file_exists shape_filename then
      ReadShapesNoCompress.read_xml_and_shapes xml_filename shape_filename
    else
      begin
        Warning.emit "[Warning] could not find goal shapes file@.";
        Xml.from_file xml_filename, false
      end
with e ->
  Warning.emit "[Warning] failed to read goal shapes: %s@."
    (Printexc.to_string e);
  Xml.from_file xml_filename, false

let load_session (dir : string) =
  let session = empty_session dir in
  let file = Filename.concat dir db_filename in
  let use_shapes =
    (* If the xml is present we read it, otherwise we consider it empty *)
    if Sys.file_exists file then
      try
        Termcode.reset_dict ();
        let xml,use_shapes =
          read_file_session_and_shapes dir file in
        try
          build_session session xml.Xml.content;
          use_shapes
        with Sys_error msg ->
          failwith ("Open session: sys error " ^ msg)
      with
      | Sys_error msg ->
        (* xml does not exist yet *)
        raise (SessionFileError msg)
      | Xml.Parse_error s ->
        Warning.emit "XML database corrupted, ignored (%s)@." s;
        raise (SessionFileError "XML corrupted")
    else false
  in
    session, use_shapes

(* -------------------- merge/update session --------------------------- *)

module CombinedTheoryChecksum = struct

  let b = Buffer.create 1024

  let f () pn =
    match pn.proofn_checksum with
    | None -> assert false
    | Some c -> Buffer.add_string b (Termcode.string_of_checksum c)

  let compute s th =
    let () = fold_all_sub_goals_of_theory s f () th in
    let c = Termcode.buffer_checksum b in
    Buffer.clear b; c

end

(** Pairing *)

module Goal = struct
  type 'a t = proofNodeID * session
  let checksum (id,s) = (get_proofNode s id).proofn_checksum
  let shape (id,s)    = (get_proofNode s id).proofn_shape
  let name (id,s)     = (get_proofNode s id).proofn_name
end

module AssoGoals = Termcode.Pairing(Goal)(Goal)

let found_obsolete = ref false
let found_missed_goals_in_theory = ref false

let save_detached_goals old_s detached_goals_id s parent =
  let save_proof parent old_pa_n =
    let old_pa = old_pa_n in
    ignore (add_proof_attempt s old_pa.prover old_pa.limit
      old_pa.proof_state true old_pa.proof_script
      parent)
  in
  let rec save_goal parent detached_goal_id id =
    let detached_goal = get_proofNode old_s detached_goal_id in
    mk_proof_node_no_task s detached_goal.proofn_name parent id None
      (Termcode.shape_of_string "");
    Hprover.iter (fun _ pa ->
                  let pa = get_proof_attempt_node old_s pa in
                  save_proof id pa) detached_goal.proofn_attempts;
    List.iter (save_trans id) detached_goal.proofn_transformations;
    let new_trans = (get_proofNode s id) in
    new_trans.proofn_transformations <- List.rev new_trans.proofn_transformations
  and save_trans parent_id old_id =
    let old_tr = get_transfNode old_s old_id in
    let name = old_tr.transf_name in
    let args = old_tr.transf_args in
    let id = gen_transID s in
    let subtasks_id = List.map (fun _ -> gen_proofNodeID s) old_tr.transf_subtasks in
    mk_transf_node s parent_id id name args subtasks_id;
    List.iter2 (fun pn_id -> save_goal (Trans id) pn_id)
      old_tr.transf_subtasks subtasks_id
  in
  List.map
      (fun detached_goal -> let id = gen_proofNodeID s in
        save_goal parent detached_goal id;
        id)
      detached_goals_id

let save_detached_theory parent_name old_s detached_theory s =
  let goalsID =
    save_detached_goals old_s detached_theory.theory_goals s (Theory detached_theory) in
    (* List.map (fun _ -> gen_proofNodeID s) detached_theory.theory_goals in *)
  { theory_name = detached_theory.theory_name;
    theory_checksum = None;
    theory_goals = goalsID;
    theory_parent_name = parent_name;
    theory_detached_goals = [] }

let merge_proof new_s ~goal_obsolete new_goal _ old_pa_n =
  let old_pa = old_pa_n in
  let obsolete = goal_obsolete || old_pa.proof_obsolete in
  found_obsolete := obsolete || !found_obsolete;
  ignore (add_proof_attempt new_s old_pa.prover old_pa.limit
    old_pa.proof_state obsolete old_pa.proof_script
    new_goal)

let add_registered_transformation s env old_tr goal_id =
  let goal = get_proofNode s goal_id in
  try
    let tr = List.find (fun transID -> (get_transfNode s transID).transf_name = old_tr.transf_name)
        goal.proofn_transformations in
    (* NOTE: should not happen *)
    Debug.dprintf debug "[merge_theory] trans found@.";
    tr
  with Not_found ->
    Debug.dprintf debug "[merge_theory] trans not found@.";
    let task = goal.proofn_task in
    let tables = match goal.proofn_table with
    | None -> raise (Task.Bad_name_table "Session_itp.add_registered_transformation")
    | Some tables -> tables in
    let subgoals = Trans.apply_transform_args old_tr.transf_name env old_tr.transf_args tables task in
    graft_transf s goal_id old_tr.transf_name old_tr.transf_args subgoals

let rec merge_goal ~use_shapes env new_s old_s ~goal_obsolete old_goal new_goal_id =
  Hprover.iter (fun k pa ->
                let pa = get_proof_attempt_node old_s pa in
                merge_proof new_s ~goal_obsolete new_goal_id k pa)
               old_goal.proofn_attempts;
  List.iter
    (merge_trans ~use_shapes env old_s new_s new_goal_id)
    old_goal.proofn_transformations;
  let new_trans = (get_proofNode new_s new_goal_id) in
  new_trans.proofn_transformations <- List.rev new_trans.proofn_transformations

and merge_trans ~use_shapes env old_s new_s new_goal_id old_tr_id =
  let old_tr = get_transfNode old_s old_tr_id in
  let old_subtasks = List.map (fun id -> id,old_s)
      old_tr.transf_subtasks in
  (* add_registered_transformation actually apply the transformation. It can fail *)
  try (
  let new_tr_id =
    add_registered_transformation new_s env old_tr new_goal_id
  in
  let new_tr = get_transfNode new_s new_tr_id in
  (* attach the session to the subtasks to be able to instantiate Pairing *)
  let new_subtasks = List.map (fun id -> id,new_s)
      new_tr.transf_subtasks in
  List.iter
    (fun (id,s) -> match (get_proofNode s id).proofn_checksum with
       | Some _ -> Debug.dprintf debug "[merge] old subgoal has no checksum@."
       | None ->  Debug.dprintf debug "[merge] old subgoal has no checksum@.") old_subtasks;
  List.iter
    (fun (id,s) -> match (get_proofNode s id).proofn_checksum with
       | Some _ -> Debug.dprintf debug "[merge] new subgoal has no checksum@."
       | None ->  Debug.dprintf debug "[merge] new subgoal has no checksum@.") new_subtasks;
  let associated,detached =
    AssoGoals.associate ~use_shapes old_subtasks new_subtasks
  in
  List.iter (function
      | ((new_goal_id,_), Some ((old_goal_id,_), goal_obsolete)) ->
        Debug.dprintf debug "[merge_theory] pairing paired one goal, yeah !@.";
        merge_goal ~use_shapes env new_s old_s ~goal_obsolete (get_proofNode old_s old_goal_id) new_goal_id
      | ((id,s), None) ->
        Debug.dprintf debug "[merge_theory] pairing found missed sub goal :( : %s @."
          (get_proofNode s id).proofn_name.Ident.id_string;
        found_missed_goals_in_theory := true)
    associated;
  (* save the detached goals *)
  let detached = List.map (fun (a,_) -> a) detached in
  new_tr.transf_detached_subtasks <- save_detached_goals old_s detached new_s (Trans new_tr_id))
  with | _ ->
    (* TODO should create a detached transformation instead *)
    ()


let merge_theory ~use_shapes env old_s old_th s th : unit =
  let found_missed_goals_in_theory = ref false in
  let old_goals_table = Hstr.create 7 in
  (* populate old_goals_table *)
  List.iter
    (fun id ->
       let pn = get_proofNode old_s id in
       Hstr.add old_goals_table pn.proofn_name.Ident.id_string id)
    old_th.theory_goals;
  let to_checksum = CombinedTheoryChecksum.compute s th in
  let same_theory_checksum =
    match old_th.theory_checksum with
    | None -> false
    | Some c -> Termcode.equal_checksum c to_checksum
  in
  let new_goals = ref [] in
  (* merge goals *)
  List.iter
    (fun ng_id ->
       try
         let new_goal = get_proofNode s ng_id in
         (* look for old_goal with matching name *)
         let old_goal = get_proofNode old_s
           (Hstr.find old_goals_table new_goal.proofn_name.Ident.id_string) in
         Hstr.remove old_goals_table new_goal.proofn_name.Ident.id_string;
         let goal_obsolete =
           match new_goal.proofn_checksum, old_goal.proofn_checksum with
           | None, _ -> assert false
           | Some _, None ->
             Debug.dprintf debug "[merge_theory] goal has no checksum@.";
             not same_theory_checksum
           | Some s1, Some s2 ->
             Debug.dprintf debug "[merge_theory] goal has checksum@.";
             not (Termcode.equal_checksum s1 s2)
         in
         if goal_obsolete then
           found_obsolete := true;
         merge_goal ~use_shapes env s old_s ~goal_obsolete old_goal ng_id
       with
       | Not_found ->
         (* if no goal of matching name is found store it to look for
            matching shape *)
         new_goals := (ng_id,s) :: !new_goals)
    th.theory_goals;
  (* check shapes if no old_goal is found with matching name *)
  (* attach the session to the subtasks to be able to instantiate Pairing *)
  let detached_goals = Hstr.fold (fun _key g tl -> (g,old_s) :: tl) old_goals_table [] in
  let associated,detached =
    AssoGoals.associate ~use_shapes detached_goals !new_goals
  in
  List.iter (function
      | ((new_goal_id,_), Some ((old_goal_id,_), goal_obsolete)) ->
        Debug.dprintf debug "[merge_theory] pairing paired one goal, yeah !@.";
        merge_goal ~use_shapes env s old_s ~goal_obsolete (get_proofNode old_s old_goal_id) new_goal_id
      | (_, None) ->
        Debug.dprintf debug "[merge_theory] pairing found missed sub goal :( @.";
        found_missed_goals_in_theory := true)
    associated;
  (* store the detached goals *)
  let detached = List.map (fun (a,_) -> a) detached in
  th.theory_detached_goals <- save_detached_goals old_s detached s (Theory th)

(* add a theory and its goals to a session. if a previous theory is
   provided in merge try to merge the new theory with the previous one *)
let make_theory_section ?merge (s:session) parent_name (th:Theory.theory)
  : theory =
  let add_goal parent goal id =
    let name,_expl,task = Termcode.goal_expl_task ~root:true goal in
    mk_proof_node ~version:s.session_shape_version s name task parent id;
  in
  let tasks = List.rev (Task.split_theory th None None) in
  let goalsID = List.map (fun _ -> gen_proofNodeID s) tasks in
  let theory = { theory_name = th.Theory.th_name;
                 theory_checksum = None;
                 theory_goals = goalsID;
                 theory_parent_name = parent_name;
                 theory_detached_goals = [] } in
  let parent = Theory theory in
  List.iter2 (add_goal parent) tasks goalsID;
  begin
    match merge with
    | Some (old_s, old_th, env, use_shapes) ->
      merge_theory ~use_shapes env old_s old_th s theory
    | _ -> ()
  end;
  theory

(* add a why file to a session *)
let add_file_section (s:session) (fn:string)
    (theories:Theory.theory list) format : unit =
  let fn = Sysutil.relativize_filename s.session_dir fn in
  if Hstr.mem s.session_files fn then
    Debug.dprintf debug "[session] file %s already in database@." fn
  else
    begin
      let theories = List.map (make_theory_section s fn) theories in
      let f = { file_name = fn;
                file_format = format;
                file_theories = theories;
                file_detached_theories = [] }
      in
      Hstr.add s.session_files fn f
    end

(* add a why file to a session and try to merge its theories with the
   provided ones with matching names *)
let merge_file_section ~use_shapes ~old_ses ~old_theories ~env
    (s:session) (fn:string) (theories:Theory.theory list) format
  : unit =
  let fn = Sysutil.relativize_filename s.session_dir fn in
  if Hstr.mem s.session_files fn then
    Debug.dprintf debug "[session] file %s already in database@." fn
  else
    let theories,detached =
      let old_th_table = Hstr.create 7 in
      List.iter
        (fun th -> Hstr.add old_th_table th.theory_name.Ident.id_string th)
        old_theories;
      let add_theory (th: Theory.theory) =
        try
          (* look for a theory with same name *)
          let theory_name = th.Theory.th_name.Ident.id_string in
          (* if we found one, we remove it from the table and merge it *)
          let old_th = Hstr.find old_th_table theory_name in
          Hstr.remove old_th_table theory_name;
          make_theory_section ~merge:(old_ses,old_th,env,use_shapes) s fn th
        with Not_found ->
          (* if no theory was found we make a new theory section *)
          make_theory_section s fn th
      in
      let theories = List.map add_theory theories in
      (* we save the remaining, detached *)
      let detached = Hstr.fold
          (fun _key th tl ->
             (save_detached_theory fn old_ses th s) :: tl)
          old_th_table [] in
      theories, detached
    in
    let f = { file_name = fn;
              file_format = format;
              file_theories = theories;
              file_detached_theories = detached }
    in
    Hstr.add s.session_files fn f

(************************)
(* saving state on disk *)
(************************)

module Mprover = Whyconf.Mprover
(* dead code
module Sprover = Whyconf.Sprover
*)
module PHprover = Whyconf.Hprover

open Format

let save_string = Pp.html_string

type save_ctxt = {
  prover_ids : int PHprover.t;
  provers : (int * int * int * int) Mprover.t;
  ch_shapes : Compress.Compress_z.out_channel;
}

let get_used_provers_with_stats session =
  let prover_table = PHprover.create 5 in
  session_iter_proof_attempt
    (fun _ pa ->
      (* record mostly used pa.proof_timelimit pa.proof_memlimit *)
      let prover = pa.prover in
      let timelimits,steplimits,memlimits =
        try PHprover.find prover_table prover
        with Not_found ->
          let x = (Hashtbl.create 5,Hashtbl.create 5,Hashtbl.create 5) in
          PHprover.add prover_table prover x;
          x
      in
      let lim_time = pa.limit.Call_provers.limit_time in
      let lim_mem = pa.limit.Call_provers.limit_mem in
      let lim_steps = pa.limit.Call_provers.limit_steps in
      let tf = try Hashtbl.find timelimits lim_time with Not_found -> 0 in
      let sf = try Hashtbl.find steplimits lim_steps with Not_found -> 0 in
      let mf = try Hashtbl.find memlimits lim_mem with Not_found -> 0 in
      Hashtbl.replace timelimits lim_time (tf+1);
      Hashtbl.replace steplimits lim_steps (sf+1);
      Hashtbl.replace memlimits lim_mem (mf+1))
    session;
  prover_table

let get_prover_to_save prover_ids p (timelimits,steplimits,memlimits) provers =
  let mostfrequent_timelimit,_ =
    Hashtbl.fold
      (fun t f ((_,f') as t') -> if f > f' then (t,f) else t')
      timelimits
      (0,0)
  in
  let mostfrequent_steplimit,_ =
    Hashtbl.fold
      (fun s f ((_,f') as s') -> if f > f' then (s,f) else s')
      steplimits
      (0,0)
  in
  let mostfrequent_memlimit,_ =
    Hashtbl.fold
      (fun m f ((_,f') as m') -> if f > f' then (m,f) else m')
      memlimits
      (0,0)
  in
  let id =
    try
      PHprover.find prover_ids p
    with Not_found ->
      (* we need to find an unused prover id *)
      let occurs = Hashtbl.create 7 in
      PHprover.iter (fun _ n -> Hashtbl.add occurs n ()) prover_ids;
      let id = ref 0 in
      try
        while true do
          try
            let _ = Hashtbl.find occurs !id in incr id
          with Not_found -> raise Exit
        done;
        assert false
      with Exit ->
        PHprover.add prover_ids p !id;
        !id
  in
  Mprover.add p (id,mostfrequent_timelimit,mostfrequent_steplimit,mostfrequent_memlimit) provers

let opt pr lab fmt = function
  | None -> ()
  | Some s -> fprintf fmt "@ %s=\"%a\"" lab pr s

let opt_string = opt save_string

let save_prover fmt id (p,mostfrequent_timelimit,mostfrequent_steplimit,mostfrequent_memlimit) =
  let steplimit =
    if mostfrequent_steplimit < 0 then None else Some mostfrequent_steplimit
  in
  fprintf fmt "@\n@[<h><prover@ id=\"%i\"@ name=\"%a\"@ \
               version=\"%a\"%a@ timelimit=\"%d\"%a@ memlimit=\"%d\"/>@]"
    id save_string p.Whyconf.prover_name save_string p.Whyconf.prover_version
    (fun fmt s -> if s <> "" then fprintf fmt "@ alternative=\"%a\""
        save_string s)
    p.Whyconf.prover_altern
    mostfrequent_timelimit
    (opt pp_print_int "steplimit") steplimit
    mostfrequent_memlimit

let save_option_def name fmt opt =
  match opt with
  | None -> ()
  | Some s -> fprintf fmt "@ %s=\"%s\"" name s

let save_bool_def name def fmt b =
  if b <> def then fprintf fmt "@ %s=\"%b\"" name b

let save_int_def name def fmt n =
  if n <> def then fprintf fmt "@ %s=\"%d\"" name n

let save_result fmt r =
  let steps = if  r.Call_provers.pr_steps >= 0 then
                Some  r.Call_provers.pr_steps
              else
                None
  in
  fprintf fmt "<result@ status=\"%s\"@ time=\"%.2f\"%a/>"
    (match r.Call_provers.pr_answer with
       | Call_provers.Valid -> "valid"
       | Call_provers.Failure _ -> "failure"
       | Call_provers.Unknown _ -> "unknown"
       | Call_provers.HighFailure -> "highfailure"
       | Call_provers.Timeout -> "timeout"
       | Call_provers.OutOfMemory -> "outofmemory"
       | Call_provers.StepLimitExceeded -> "steplimitexceeded"
       | Call_provers.Invalid -> "invalid")
    r.Call_provers.pr_time
    (opt pp_print_int "steps") steps

let save_status fmt s =
  match s with
  | Some result -> save_result fmt result
  | None -> fprintf fmt "<undone/>"

let save_proof_attempt fmt ((id,tl,sl,ml),a) =
  fprintf fmt
    "@\n@[<h><proof@ prover=\"%i\"%a%a%a%a%a>"
    id
    (save_int_def "timelimit" tl) (a.limit.Call_provers.limit_time)
    (save_int_def "steplimit" sl) (a.limit.Call_provers.limit_steps)
    (save_int_def "memlimit" ml) (a.limit.Call_provers.limit_mem)
    (save_bool_def "obsolete" false) a.proof_obsolete
    (save_option_def "edited") a.proof_script;
  save_status fmt a.proof_state;
  fprintf fmt "</proof>@]"

let save_ident fmt id =
  let n = id.Ident.id_string
  in
  fprintf fmt "name=\"%a\"" save_string n

let save_checksum fmt s =
  fprintf fmt "%s" (Termcode.string_of_checksum s)

let rec save_goal s ctxt fmt pnid =
  let pn = get_proofNode s pnid in
  fprintf fmt
    "@\n@[<v 0>@[<h><goal@ %a>@]"
    save_ident pn.proofn_name;
  let sum =
    match pn.proofn_checksum with
    | None -> assert false
    | Some s -> Termcode.string_of_checksum s
  in
  let shape = Termcode.string_of_shape pn.proofn_shape in
  assert (shape <> "");
  Compress.Compress_z.output_string ctxt.ch_shapes sum;
  Compress.Compress_z.output_char ctxt.ch_shapes ' ';
  Compress.Compress_z.output_string ctxt.ch_shapes shape;
  Compress.Compress_z.output_char ctxt.ch_shapes '\n';
  let l = Hprover.fold
      (fun _ a acc ->
       let a = get_proof_attempt_node s a in
       (Mprover.find a.prover ctxt.provers, a) :: acc)
      pn.proofn_attempts [] in
  let l = List.sort (fun ((i1,_,_,_),_) ((i2,_,_,_),_) -> compare i1 i2) l in
  List.iter (save_proof_attempt fmt) l;
  let l =
    List.fold_left (fun acc t -> (get_transfNode s t) :: acc) [] pn.proofn_transformations
  in
  let l = List.sort (fun t1 t2 -> compare t1.transf_name t2.transf_name) l in
  List.iter (save_trans s ctxt fmt) l;
  fprintf fmt "@]@\n</goal>";

and save_trans s ctxt fmt t =
  let arg_id = ref 0 in
  let save_arg fmt s =
    arg_id := !arg_id + 1;
    fprintf fmt "arg%i=\"%a\"" !arg_id save_string s
  in
  fprintf fmt "@\n@[<hov 1>@[<h><transf@ name=\"%a\" %a>@]"
    save_string t.transf_name (Pp.print_list Pp.space save_arg) t.transf_args;
  List.iter (save_goal s ctxt fmt) t.transf_subtasks;
  fprintf fmt "@]@\n</transf>"

let save_theory s ctxt fmt t =
  (* commented out since the session needs to be updated for goals to
     have a checksum *)
  let c = CombinedTheoryChecksum.compute s t in
  t.theory_checksum <- Some c;
  fprintf fmt
    "@\n@[<v 1>@[<h><theory@ %a%a>@]"
    save_ident t.theory_name
    (opt save_checksum "sum") t.theory_checksum;
  List.iter (save_goal s ctxt fmt) t.theory_goals;
  fprintf fmt "@]@\n</theory>"

let save_file s ctxt fmt _ f =
  fprintf fmt
    "@\n@[<v 0>@[<h><file@ name=\"%a\"%a>@]"
    save_string f.file_name (opt_string "format")
    f.file_format;
  List.iter (save_theory s ctxt fmt) f.file_theories;
  fprintf fmt "@]@\n</file>"

let save fname shfname session =
  let ch = open_out fname in
  let chsh = Compress.Compress_z.open_out shfname in
  let fmt = formatter_of_out_channel ch in
  fprintf fmt "<?xml version=\"1.0\" encoding=\"UTF-8\"?>@\n";
  fprintf fmt "<!DOCTYPE why3session PUBLIC \"-//Why3//proof session v5//EN\"@ \"http://why3.lri.fr/why3session.dtd\">@\n";
  fprintf fmt "@[<v 0><why3session shape_version=\"%d\">"
    session.session_shape_version;
  Termcode.reset_dict ();
  let prover_ids = session.session_prover_ids in
  let provers =
    PHprover.fold (get_prover_to_save prover_ids)
      (get_used_provers_with_stats session) Mprover.empty
  in
  let provers_to_save =
    Mprover.fold
      (fun p (id,mostfrequent_timelimit,mostfrequent_steplimit,mostfrequent_memlimit) acc ->
        Mint.add id (p,mostfrequent_timelimit,mostfrequent_steplimit,mostfrequent_memlimit) acc)
      provers Mint.empty
  in
  Mint.iter (save_prover fmt) provers_to_save;
  let ctxt = { prover_ids = prover_ids; provers = provers; ch_shapes = chsh } in
  Hstr.iter (save_file session ctxt fmt) session.session_files;
  fprintf fmt "@]@\n</why3session>";
  fprintf fmt "@.";
  close_out ch


let save_session (s : session) =
  let f = Filename.concat s.session_dir db_filename in
  Sysutil.backup_file f;
  let fs = Filename.concat s.session_dir shape_filename in
  Sysutil.backup_file fs;
  let fz = Filename.concat s.session_dir compressed_shape_filename in
  Sysutil.backup_file fz;
  session_dir_for_save := s.session_dir;
  let fs = if Compress.compression_supported then fz else fs in
  save f fs s
