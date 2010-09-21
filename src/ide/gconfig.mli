
open Why

type prover_data =
    { prover_id : string;
      prover_name : string;
      prover_version : string;
      command : string;
      driver_name : string;
      driver : Driver.driver;
      mutable editor : string;
    }

type t = 
    { mutable window_width : int;
      mutable window_height : int;
      mutable tree_width : int;
      mutable task_height : int;
      mutable time_limit : int;
      mutable mem_limit : int;
      mutable verbose : int;
      mutable max_running_processes : int;
      mutable provers : prover_data list;
      mutable default_editor : string;
      mutable env : Why.Env.env;
      mutable config : Whyconf.config;
    }

val get_prover_data : Why.Env.env ->
           string ->
           Why.Whyconf.config_prover -> prover_data list -> prover_data list

val save_config : unit -> unit

val config      : t

val get_main : unit -> Whyconf.main

(***************)
(* boomy icons *)
(***************)

val image_yes : GdkPixbuf.pixbuf ref

(* tree object icons *)
val image_directory : GdkPixbuf.pixbuf ref
val image_file : GdkPixbuf.pixbuf ref
val image_prover : GdkPixbuf.pixbuf ref
val image_transf : GdkPixbuf.pixbuf ref

(* status icons *)
val image_scheduled : GdkPixbuf.pixbuf ref
val image_running : GdkPixbuf.pixbuf ref
val image_valid : GdkPixbuf.pixbuf ref
val image_timeout : GdkPixbuf.pixbuf ref
val image_unknown : GdkPixbuf.pixbuf ref
val image_failure : GdkPixbuf.pixbuf ref

(*************************)
(* miscellaneous dialogs *)
(*************************)

val show_legend_window : unit -> unit
val show_about_window : unit -> unit
val preferences : t -> unit

val run_auto_detection : t -> unit

(*
Local Variables: 
compile-command: "unset LANG; make -C ../.. bin/whyide.opt"
End: 
*)
