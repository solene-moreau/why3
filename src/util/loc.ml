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

(*
type lexing_loc = Lexing.position * Lexing.position
*)

open Lexing

let current_offset = ref 0
let reloc p = { p with pos_cnum = p.pos_cnum + !current_offset }

let set_file file lb =
  lb.Lexing.lex_curr_p <-
    { lb.Lexing.lex_curr_p with Lexing.pos_fname = file }

let transfer_loc lb_from lb_to =
  lb_to.lex_start_p <- lb_from.lex_start_p;
  lb_to.lex_curr_p <- lb_from.lex_curr_p


(*s Error locations. *)

let finally ff f x =
  let y = try f x with e -> ff (); raise e in ff (); y

open Format

(*s Line number *)

(*
let report_line fmt l = fprintf fmt "%s:%d:" l.pos_fname l.pos_lnum
*)

type position = string * int * int * int

let user_position fname lnum cnum1 cnum2 = (fname,lnum,cnum1,cnum2)

let get loc = loc

let dummy_position = ("",0,0,0)

let join (f1,l1,b1,e1) (f2,_,b2,e2) =
  assert (f1 = f2); (f1,l1,b1,e1+e2-b2)

let extract (b,e) =
  let f = b.pos_fname in
  let l = b.pos_lnum in
  let fc = b.pos_cnum - b.pos_bol in
  let lc = e.pos_cnum - b.pos_bol in
  (f,l,fc,lc)

let compare = Pervasives.compare
let equal = Pervasives.(=)
let hash = Hashtbl.hash

let gen_report_position fmt (f,l,b,e) =
  fprintf fmt "File \"%s\", line %d, characters %d-%d" f l b e

let report_position fmt = fprintf fmt "%a:@\n" gen_report_position

(* located exceptions *)

exception Located of position * exn

let try1 loc f x =
  try f x with Located _ as e -> raise e | e -> raise (Located (loc, e))
let try2 loc f x y =
  try f x y with Located _ as e -> raise e | e -> raise (Located (loc, e))
let try3 loc f x y z =
  try f x y z with Located _ as e -> raise e | e -> raise (Located (loc, e))
let try4 loc f x y z t =
  try f x y z t with Located _ as e -> raise e | e -> raise (Located (loc, e))

let error ?loc e = match loc with
  | None -> raise e
  | Some loc -> raise (Located (loc, e))

(* located messages *)

exception Message of string

let errorm ?loc f =
  let buf = Buffer.create 512 in
  let fmt = Format.formatter_of_buffer buf in
  Format.kfprintf
    (fun _ ->
       Format.pp_print_flush fmt ();
       let s = Buffer.contents buf in
       Buffer.clear buf;
       error ?loc (Message s))
    fmt f

let () = Exn_printer.register
  (fun fmt exn -> match exn with
    | Located (loc,e) ->
        fprintf fmt "%a%a" report_position loc Exn_printer.exn_printer e
    | Message s ->
        fprintf fmt "%s" s
    | _ ->
        raise exn)

