(**************************************************************************)
(*                                                                        *)
(*  Copyright (C) 2010-2011                                               *)
(*    François Bobot                                                      *)
(*    Jean-Christophe Filliâtre                                           *)
(*    Claude Marché                                                       *)
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

(* Smoke detector try to find if the axiomatisation is self-contradicting.

   The second smoke detector add the negation under the implication and
   universal quantification (replace implication by conjunction).
*)

open Ident
open Term
open Decl
open Task

let create app =
  Trans.goal (fun pr t -> [create_prop_decl Pgoal pr (app t)])

let top = create t_not

let rec neg f = match f.t_node with
  | Tbinop (Timplies,f1,f2) -> t_and f1 (neg f2)
(* Would show too much smoke ? 
  | Tbinop (Timplies,f1,f2) -> t_implies f1 (neg f2)
*)
  | Tquant (Tforall,fq) ->
      let vsl,_trl,f = t_open_quant fq in
      t_forall_close vsl _trl (neg f)
  | Tlet (t,fb) ->
      let vs,f = t_open_bound fb in
      t_let_close vs t (neg f)
  | _ -> t_not f

let deep = create neg

let () = List.iter (fun (name,trans) -> Trans.register_transform name trans)
  ["smoke_detector_top",top;
   "smoke_detector_deep",deep]

(*
Local Variables:
compile-command: "unset LANG; make -C ../.. byte"
End:
*)
