

(* TODO copy of why3js_ocaml.... *)

open Why3
open Itp_communication

module JSU = Js.Unsafe

let log s = ignore (Firebug.console ## log (Js.string s))

let get_opt o = Js.Opt.get o (fun () -> assert false)

let check_def s o =
  Js.Optdef.get o (fun () -> log ("Object " ^ s ^ " is undefined or null");
			     assert false)

let get_global ident =
  let res : 'a Js.optdef = JSU.(get global) (Js.string ident) in
  check_def ident res

let appendChild o c =
  ignore (o ## appendChild ( (c :> Dom.node Js.t)))

let addMouseEventListener prevent o e f =
  let cb = Js.wrap_callback
	     (fun (e : Dom_html.mouseEvent Js.t) ->
	      if prevent then ignore (JSU.(meth_call e "preventDefault" [| |]));
	      f e;
	      Js._false)
  in
  ignore JSU.(meth_call o "addEventListener"
			[| inject (Js.string e);
			   inject cb;
			   inject Js._false |])

(**********)

module AsHtml =
  struct
    include Dom_html.CoerceTo
    let span e = element e
  end

let getElement_exn cast id =
  Js.Opt.get (cast (Dom_html.getElementById id)) (fun () -> raise Not_found)

let getElement cast id =
  try
    getElement_exn cast id
  with
    Not_found ->
    log ("Element " ^ id ^ " does not exist or has invalid type");
    assert false

(**********)

module PE = struct
  let error_panel = getElement AsHtml.div "why3-error-bg"

  let print cls msg =
    error_panel ##. innerHTML :=
      Js.string ("<p class='" ^ cls ^ "'>" ^
                  msg ^ "</p>")

  let error_print_error = print "why3-error"

  let error_print_msg = print "why3-msg"

(* TODO remove this *)
  let printAnswer s =
  error_print_msg s

end

let readBody (xhr: XmlHttpRequest.xmlHttpRequest Js.t) =
  let data = ref None in
  let resType = xhr ##. responseType in
  PE.printAnswer (Js.to_string resType);
  data := Some (xhr ##. responseText);
  match !data with
  | None -> raise Not_found
  | Some data -> PE.printAnswer (Js.to_string data); Js.to_string data

(* TEMPORAZRY TODO s todo *)
exception TODO1
exception TODO2

module Editor =
  struct
    type range
    type marker
    let name = ref (Js.string "")
    let saved = ref false
    let ace = get_global "ace"

    let _Range : (int -> int -> int -> int -> range Js.t) Js.constr =
      let r =
	JSU.(get (meth_call ace "require" [| inject (Js.string "ace/range") |])
		 (Js.string "Range"))
      in
      check_def "Range" r

    let editor =
      let e =
	JSU.(meth_call ace "edit" [| inject (Js.string "why3-editor") |])
      in
      check_def "why3-editor" e

    let task_viewer =
      let e =
	JSU.(meth_call ace "edit" [| inject (Js.string "why3-task-viewer") |])
      in
      check_def "why3-task-viewer" e

    let get_session ed =
      JSU.(meth_call ed "getSession" [| |])


    let mk_annotation row col text kind =
      JSU.(obj [| "row", inject row; "column", inject col;
		  "text", inject text; "type", inject kind |])

    let set_annotations l =
      let a =
	Array.map (fun (r,c,t,k) -> mk_annotation r c t k) (Array.of_list l)
      in
      let a = Js.array a in
      JSU.(meth_call (get_session editor) "setAnnotations" [| inject a |])

    let clear_annotations () =
      ignore (JSU.(meth_call (get_session editor) "clearAnnotations" [| |]))

    let _Infinity = get_global "Infinity"

    let scroll_to_end e =
      let len : int  = JSU.(meth_call (get_session e) "getLength" [| |]) in
      let last_line = len - 1 in
      ignore JSU.(meth_call e "gotoLine" [| inject last_line; inject _Infinity; inject Js._false |])

    let () =
      let editor_theme : Js.js_string Js.t = get_global "editor_theme" in
      let editor_mode : Js.js_string Js.t = get_global "editor_mode" in

      List.iter (fun e ->
		 ignore (JSU.(meth_call e "setTheme" [| inject editor_theme |]));
		 ignore (JSU.(meth_call (get_session e) "setMode" [| inject editor_mode |]));
		 JSU.(set e (Js.string "$blockScrolling") _Infinity)
		) [ editor; task_viewer ];
      JSU.(meth_call task_viewer "setReadOnly" [| inject Js._true|])

    let undo () =
      ignore JSU.(meth_call editor "undo" [| |])

    let redo () =
      ignore JSU.(meth_call editor "redo" [| |])

    let get_value ?(editor=editor) () : Js.js_string Js.t =
      JSU.meth_call editor "getValue" [| |]

    let set_value ?(editor=editor) (str : Js.js_string Js.t) =
      ignore JSU.(meth_call editor "setValue" [| inject (str); inject ~-1 |])

    let _Range = Js.Unsafe.global##._Range

    let mk_range l1 c1 l2 c2 =
      new%js _Range (l1, c1, l2, c2)

    let set_selection_range r =
      let selection = JSU.meth_call editor "getSelection" [| |] in
      ignore JSU.(meth_call selection "setSelectionRange" [| inject r |])

    let add_marker cls r : marker =
      JSU.(meth_call (get_session editor) "addMarker"
                     [| inject r;
			inject (Js.string cls);
			inject (Js.string "text") |])

    let remove_marker m =
      ignore JSU.(meth_call  (get_session editor) "removeMarker" [| inject  m|])

    let get_char buffer i = int_of_float (buffer ## charCodeAt(i))
    let why3_loc_to_range buffer loc =
      let goto_line lstop =
        let rec loop lcur i =
          if lcur == lstop then i
          else
            let c = get_char buffer i in
            loop (if c == 0 then lcur+1 else lcur) (i+1)
        in
        loop 1 0
      in
      let rec convert_range l c i n =
        if n == 0 then (l, c) else
          if (get_char buffer i) == 10
          then convert_range (l+1) 0 (i+1) (n-1)
          else convert_range l (c+1) (i+1) (n-1)
      in
      let l1, b, e = loc in
      let c1 = b in
      let i = goto_line l1 in
      let l2, c2 = convert_range l1 b (i+b) (e-b) in
      mk_range (l1-1) c1 (l2-1) c2

    let focus e =
      ignore JSU.(meth_call e "focus" [| |])

      let set_on_event e f =
	ignore JSU.(meth_call editor "on" [| inject (Js.string e);
					   inject f|])


      let editor_bg = getElement AsHtml.div "why3-editor-bg"

      let disable () =
        ignore JSU.(meth_call editor "setReadOnly" [| inject Js._true|]);
        editor_bg ##. style ##. display := (Js.string "block")


      let enable () =
        ignore JSU.(meth_call editor "setReadOnly" [| inject Js._false|]);
        editor_bg ##. style ##. display := Js.string "none"


      let confirm_unsaved () =
        if not !saved then
          Js.to_bool
            (Dom_html.window ## confirm (Js.string "You have unsaved changes in your editor, proceed anyway ?"))
        else
          true

  end

(* TODO This is not necessary yet ???? *)
module ContextMenu =
  struct
    let task_menu = getElement AsHtml.div "why3-task-menu"
    let split_menu_entry = getElement AsHtml.li "why3-split-menu-entry"
    let prove_menu_entry = getElement AsHtml.li "why3-prove-menu-entry"
    let prove100_menu_entry = getElement AsHtml.li "why3-prove100-menu-entry"
    let prove1000_menu_entry = getElement AsHtml.li "why3-prove1000-menu-entry"
    let clean_menu_entry = getElement AsHtml.li "why3-clean-menu-entry"
    let enabled = ref true

    let enable () = enabled := true
    let disable () = enabled := false

    let show_at x y =
      if !enabled then begin
          task_menu ##. style ##. display := Js.string "block";
          task_menu ##. style ##. left := Js.string ((string_of_int x) ^ "px");
          task_menu ##. style ##. top := Js.string ((string_of_int y) ^ "px")
        end
    let hide () =
      if !enabled then
        task_menu ##. style ##. display := Js.string "none"

    let add_action b f =
      b ##. onclick := Dom.handler (fun _ ->
				   hide ();
				   f ();
				   Editor.(focus editor);
				   Js._false)
    let () = addMouseEventListener false task_menu "mouseleave"
	(fun _ -> hide())


  end

module ToolBar =
  struct

    (* add_action to a button *)
    let add_action b f =
      let cb = fun _ ->
	f ();
(*
	Editor.(focus editor);
 *)
	Js._false
      in
      b ##. onclick := Dom.handler cb


    (* Current buttons *)
    (* TODO rename buttons *)
    let button_open = getElement AsHtml.button "why3-button-open"

    let button_save = getElement AsHtml.button "why3-button-save"

    let button_reload = getElement AsHtml.button "why3-button-undo"

    let button_redo = getElement AsHtml.button "why3-button-redo"

  end


let form = getElement AsHtml.form "why3-form"
(*
let () =
  let cb = fun key ->
    if key ##. keyCode = 97 then
      Js._false else Js._false in
  form ##. onkeypress := (Dom.handler cb)
*)
type httpRequest =
  | Get_task of string
  | Reload

let sendRequest r =
(* TODO    let r = Js.to_string r in*)
   let xhr = XmlHttpRequest.create () in
   let onreadystatechange () =
     if xhr ##. readyState == XmlHttpRequest.DONE then
       if xhr ##. status == 200 then
         PE.printAnswer (readBody xhr)
       else
         PE.printAnswer ("Erreur " ^ string_of_int (xhr ##. status)) in
   xhr ## overrideMimeType (Js.string "text/json");
   let _ = xhr ## _open (Js.string "GET")
                (Js.string ("http://localhost:6789/request?"^r))  (Js._true) in
   xhr ##. onreadystatechange := (Js.wrap_callback onreadystatechange);
   xhr ## send (Js.null)

(* TODO we currently split on the '_' to get arguments. This is bad.
   TODO This is probably also bad to always make request with URI *)
let convert_request r =
  match r with
  | Reload -> "reload"
  | Get_task n -> "gettask_"^n

let sendRequest r =
  sendRequest (convert_request r)


module TaskList =
  struct

    let selected_task = ref "0"

    let task_list = getElement AsHtml.div "why3-task-list"

    (* Task list as we get them from the server *)
    let printed_task_list = Hashtbl.create 16


    let print cls msg =
      task_list ##. innerHTML :=
        (Js.string ("<p class='" ^ cls ^ "'>" ^
                      msg ^ "</p>"))

    let print_error = print "why3-error"

    let print_msg = print "why3-msg"

    let mk_li_content id expl =
      Js.string (Format.sprintf
		   "<span id='%s_container'><span id='%s_icon'></span> %s <span id='%s_msg'></span></span><ul id='%s_ul'></ul>"
		   id id expl id id)


    let attach_to_parent id parent_id expl =
      let doc = Dom_html.document in
      let ul =
        try
          getElement_exn AsHtml.ul parent_id
        with
          Not_found ->
          let ul = Dom_html.createUl doc in
          ul ##. id := Js.string parent_id;
          appendChild task_list ul;
          ul
      in
      let li = Dom_html.createLi doc in
      li ##. id := Js.string id;
      appendChild ul li;
      li ##. innerHTML := mk_li_content id expl


    let task_selection = Hashtbl.create 17
    let is_selected id = Hashtbl.mem task_selection id

    let select_task id (span: Dom_html.element Js.t) pretty =
      (span ##. classList) ## add (Js.string "why3-task-selected");
      Hashtbl.add task_selection id span;
      selected_task := id;
      Editor.set_value ~editor:Editor.task_viewer (Js.string pretty);
      Editor.scroll_to_end Editor.task_viewer

    let deselect_task id =
      try
        let span= Hashtbl.find task_selection id in
        (span ##. classList) ## remove (Js.string "why3-task-selected");
        Hashtbl.remove task_selection id
      with
        Not_found -> ()

    let clear_task_selection () =
      let l = Hashtbl.fold (fun id _ acc -> id :: acc) task_selection [] in
      List.iter deselect_task l


    let clear () =
      clear_task_selection ();
      task_list ##. innerHTML := Js.string "";
      Editor.set_value ~editor:Editor.task_viewer (Js.string "")

    let () =
      Editor.set_on_event
        "focus"
        (Js.wrap_callback  clear_task_selection )

(* TODO remove all this *)
    type id = string
    type loc = int * int * int * int
    type why3_loc = string * (int * int * int) (* kind, line, column, length *)
    type status = [`New | `Valid | `Unknown ]

    type why3_output =
      | Error of string (* msg *)
      | ErrorLoc of (loc * string) (* loc * msg *)
      | Theory of id * string (* Theory (id, name) *)
      | Task of (id * id * string * string * why3_loc list * string * int)
            (* id, parent id, expl, code, location list, pretty, steps*)
      | Result of string list
      | UpdateStatus of status * id
      | Warning of ((int*int) * string) list
      | Idle

   let print_why3_output o =
      let doc = Dom_html.document in
      (* see why3_worker.ml *)
      match o with
     | Idle | Warning [] -> ()
      | Warning lst ->
         let annot =
           List.map (fun ((l1, c1), msg) ->
                     (l1,c1, Js.string msg, Js.string "warning")) lst
         in
         Editor.set_annotations annot

      | Error s -> print_error s

      (*| ErrorLoc ((l1, b, l2, e), s) ->
         let r = Editor.mk_range l1 b l2 e in
         error_marker := Some (Editor.add_marker "why3-error" r, r);
         print_error s;
	 Editor.set_annotations [ (l1, b, Js.string s, Js.string "error") ]
*)
      | Result sl ->
         clear ();
         let ul = Dom_html.createUl doc in
         appendChild task_list ul;
         List.iter (fun (s : string) ->
                    let li = Dom_html.createLi doc in
                    li ##. innerHTML := (Js.string s);
                    appendChild ul li;) sl

      | Theory (th_id, th_name) ->
	 attach_to_parent th_id "why3-theory-list" th_name

      | Task (id, parent_id, expl, _code, locs, pretty, _) ->
	 begin
	   try
	     ignore (Dom_html.getElementById id)
	   with Not_found ->
		attach_to_parent id (parent_id ^ "_ul") expl;
		let span = getElement AsHtml.span (id ^ "_container") in
		span ##. onclick :=
		  Dom.handler
		    (fun ev ->
		     let ctrl = Js.to_bool (ev ##. ctrlKey) in
		     if is_selected id then
                       if ctrl then deselect_task id else
			 clear_task_selection ()
		     else begin
			 if not ctrl then clear_task_selection ();
                         select_task id span pretty
                       end;
		     Js._false);
		addMouseEventListener
		  true span "contextmenu"
		  (fun e ->
		   clear_task_selection ();
                   select_task id span pretty;
		   let x = max 0 ((e ##.clientX) - 2) in
		   let y = max 0 ((e ##.clientY) - 2) in
		   ContextMenu.show_at x y)
	 end
      | _ -> ()

let onclick_do_something id =
  let span = getElement AsHtml.span (id ^ "_container") in
  span ##. onclick :=
    Dom.handler
      (fun ev ->
	let ctrl = Js.to_bool (ev ##. ctrlKey) in
	if is_selected id then
          if ctrl then deselect_task id else
	  clear_task_selection ()
	else begin
	  if not ctrl then clear_task_selection ();
          let pretty =
            if Hashtbl.mem printed_task_list id then
              Hashtbl.find printed_task_list id
            else
              (sendRequest (Get_task id);
               "loading task")
          in (* TODO dummy value *)
          select_task id span pretty
        end;
	Js._false);
  let pretty =
    if Hashtbl.mem printed_task_list id then
      Hashtbl.find printed_task_list id
    else
      (sendRequest (Get_task id);
       "loading task")
  in
  addMouseEventListener
    true span "contextmenu"
    (fun e ->
      clear_task_selection ();
      select_task id span pretty;
      let x = max 0 ((e ##.clientX) - 2) in
      let y = max 0 ((e ##.clientY) - 2) in
      ContextMenu.show_at x y)

let update_status st id =
  try
    let span_icon = getElement AsHtml.span (id ^ "_icon") in
    let span_msg = getElement AsHtml.span (id ^ "_msg") in
    let cls =
      match st with
        `New -> "fa fa-fw fa-cog fa-spin fa-fw why3-task-pending"
      | `Valid -> span_msg ##. innerHTML := Js.string "";
	  "fa-check-circle why3-task-valid"
      | `Unknown -> "fa-question-circle why3-task-unknown"
    in
    span_icon ##. className := Js.string cls
  with
    Not_found -> ()

(* Attach a new node to the task tree if it does not already exists *)
let attach_new_node nid parent (ntype: node_type) name (detached: bool) =
  let parent = string_of_int parent in
  let nid = string_of_int nid in
  try ignore (getElement_exn AsHtml.ul (nid^"_ul")) with
  | Not_found ->
      if nid != parent then
        attach_to_parent nid (parent^"_ul") name
      else
        attach_to_parent nid (parent^"_ul") name

end

(* let printAnswer s = *)
(*   let doc = TaskList.task_list (\*Dom_html.document*\) in *)
(*   let node = doc##createElement (Js.string "P") in *)
(*   let textnode = doc##createTextNode (Js.string s) in *)
(*   Dom.appendChild node textnode; *)
(*   let answers = doc ## getElementById (Js.string "answers") in *)
(*   let opt_answers = Js.Opt.to_option answers in *)
(*   match opt_answers with *)
(*   | None -> () *)
(*   | Some answers -> *)
(*       Dom.appendChild answers node *)



let interpNotif (n: notification) =
  match n with
  | Initialized g ->
      TaskList.print_msg "Initialized"
  | New_node (nid, parent, ntype, name, detached) ->
      TaskList.attach_new_node nid parent ntype name detached;
      TaskList.onclick_do_something (string_of_int nid)
  | Task (nid, task) ->
      Hashtbl.add TaskList.printed_task_list (string_of_int nid) task
  | _ -> failwith "TODO"
(*  | New_task (id, task) ->
      Populate task*)

exception NoNotification

let interpNotifications l =
  match l with
  | [] -> raise NoNotification
  | l -> List.iter interpNotif l

let getNotification2 () =
  let xhr = XmlHttpRequest.create () in
  let onreadystatechange () =
    if xhr ##. readyState == XmlHttpRequest.DONE then
      if xhr ##. status == 200 then
        let r = readBody xhr in
        PE.printAnswer ("r = |" ^ r ^ "|"); (* TODO *)
        let nl = Json_util.parse_list_notification r in
        interpNotifications nl
(* TODO *)
      else
        raise NoNotification
        (* TODO printAnswer ("Erreur" ^ string_of_int xhr##status)*)
  in
  (xhr ##. onreadystatechange :=
    (Js.wrap_callback onreadystatechange));
  xhr ## overrideMimeType (Js.string "text/json");
  let _ = xhr ## _open (Js.string "GET")
                (Js.string "http://localhost:6789/getNotifications") Js._true in
  xhr ## send (Js.null)

let notifHandler = ref None

let startNotificationHandler () =
   if (!notifHandler = None) then
     notifHandler := Some (Dom_html.window ## setInterval
                       (Js.wrap_callback getNotification2)  (Js.float 1000.0))

let stopNotificationHandler () =
   match !notifHandler with
   | None -> ()
   | Some n -> Dom_html.window ## clearInterval (n); notifHandler := None

(*
        let ses = doc ## getElementById (Js.string !pid) in
        match (Js.Opt.to_option ses) with
        | None -> raise TODO1
        | Some ses ->
            (ses ## innerHTML <- (Js.string ""));
            TaskList.print_msg "Node 0 reinitialized everything");
      let parentnode = doc ## getElementById (Js.string !pid) in
      (match (Js.Opt.to_option parentnode) with
      | None -> TaskList.print_msg !pid; raise TODO2
      | Some parentnode ->
      let linode = doc ## createElement (Js.string "LI") in
      let text = (Json_util.convert_node_type_string ntype) ^ " " ^ name in
      let textnode = doc##createTextNode (Js.string text) in
      Dom.appendChild linode textnode;
      let ulnode = doc ## createElement (Js.string "UL") in
      ulnode ## setAttribute (Js.string "id",
                              Js.string ("nid" ^ string_of_int nid));
      Dom.appendChild linode ulnode;
      Dom.appendChild parentnode linode;
      TaskList.print_msg "new_node") (* TODO *)
  | _ -> TaskList.print_msg "Unsupported" (* TODO *)
*)

let () =
  ToolBar.(add_action button_open
    (fun () -> PE.printAnswer "Open"; startNotificationHandler ()))

let () =
  ToolBar.(add_action button_save
    (fun () -> PE.printAnswer "Save"; stopNotificationHandler ()))

let () =
  ToolBar.(add_action button_reload
    (fun () -> PE.printAnswer "Reload"; sendRequest Reload))

let () =
  ToolBar.(add_action button_redo
             (fun () -> (*TaskList.print_msg "Redo";*)
               (*interpNotif (New_node (0, 0, NRoot, "blah", false));*)
               interpNotif (New_node (1, 0, NFile, "beh", false));
               interpNotif (New_node (2, 1, NGoal, "beh2", false));
               TaskList.update_status `Unknown "1";
               TaskList.onclick_do_something "1"

             ))


(* TODO Server handling *)
(*let () = Js.Unsafe.global##stopNotificationHandler <-
   Js.wrap_callback stopNotificationHandler

let () = Js.Unsafe.global##startNotificationHandler <-
   Js.wrap_callback startNotificationHandler
*)

(* let () = Js.Unsafe.global##sendRequest <- Js.wrap_callback sendRequest *)

let () = Js.Unsafe.global##.getNotification1 := Js.wrap_callback getNotification2
(*
let () = Js.Unsafe.global## PE.printAnswer1 <-
  Js.wrap_callback (fun s -> PE.printAnswer s)
*)
