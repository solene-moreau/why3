(********************************************************************)
(*                                                                  *)
(*  The Why3 Verification Platform   /   The Why3 Development Team  *)
(*  Copyright 2010-2019   --   Inria - CNRS - Paris-Sud University  *)
(*                                                                  *)
(*  This software is distributed under the terms of the GNU Lesser  *)
(*  General Public License version 2.1, with the special exception  *)
(*  on linking described in file LICENSE.                           *)
(*                                                                  *)
(********************************************************************)

(* This file is generated by Why3's Coq-realize driver *)
(* Beware! Only edit allowed sections below    *)
Require Import BuiltIn.
Require BuiltIn.

(* Why3 assumption *)
Inductive mode :=
  | NearestTiesToEven : mode
  | ToZero : mode
  | Up : mode
  | Down : mode
  | NearestTiesToAway : mode.
Axiom mode_WhyType : WhyType mode.
Existing Instance mode_WhyType.

