(********************************************************************)
(*                                                                  *)
(*  The Why3 Verification Platform   /   The Why3 Development Team  *)
(*  Copyright 2010-2013   --   INRIA - CNRS - Paris-Sud University  *)
(*                                                                  *)
(*  This software is distributed under the terms of the GNU Lesser  *)
(*  General Public License version 2.1, with the special exception  *)
(*  on linking described in file LICENSE.                           *)
(*                                                                  *)
(********************************************************************)

open Format

(* Lexing locations *)

val current_offset : int ref
val reloc : Lexing.position -> Lexing.position
val set_file : string -> Lexing.lexbuf -> unit

val transfer_loc : Lexing.lexbuf -> Lexing.lexbuf -> unit

(* locations in files *)

type position

val extract : Lexing.position * Lexing.position -> position
val join : position -> position -> position

val dummy_position : position

val user_position : string -> int -> int -> int -> position

val get : position -> string * int * int * int

val compare : position -> position -> int
val equal : position -> position -> bool
val hash : position -> int

val gen_report_position : formatter -> position -> unit

val report_position : formatter -> position -> unit

(* located exceptions *)

exception Located of position * exn

val try1: position -> ('a -> 'b) -> 'a -> 'b
val try2: position -> ('a -> 'b -> 'c) -> 'a -> 'b -> 'c
val try3: position -> ('a -> 'b -> 'c -> 'd) -> 'a -> 'b -> 'c -> 'd
val try4: position -> ('a -> 'b -> 'c -> 'd -> 'e) -> 'a -> 'b -> 'c -> 'd -> 'e

val error: ?loc:position -> exn -> 'a

(* messages *)

exception Message of string

val errorm: ?loc:position -> ('a, Format.formatter, unit, 'b) format4 -> 'a
