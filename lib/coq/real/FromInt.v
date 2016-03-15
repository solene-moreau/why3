(********************************************************************)
(*                                                                  *)
(*  The Why3 Verification Platform   /   The Why3 Development Team  *)
(*  Copyright 2010-2016   --   INRIA - CNRS - Paris-Sud University  *)
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
Require int.Int.
Require real.Real.

(* Why3 comment *)
(* from_int is replaced with (Reals.Raxioms.IZR x) by the coq driver *)

(* Why3 goal *)
Lemma Zero : ((Reals.Raxioms.IZR 0%Z) = 0%R).
split.
Qed.

(* Why3 goal *)
Lemma One : ((Reals.Raxioms.IZR 1%Z) = 1%R).
split.
Qed.

(* Why3 goal *)
Lemma Add : forall (x:Z) (y:Z),
  ((Reals.Raxioms.IZR (x + y)%Z) = ((Reals.Raxioms.IZR x) + (Reals.Raxioms.IZR y))%R).
exact plus_IZR.
Qed.

(* Why3 goal *)
Lemma Sub : forall (x:Z) (y:Z),
  ((Reals.Raxioms.IZR (x - y)%Z) = ((Reals.Raxioms.IZR x) - (Reals.Raxioms.IZR y))%R).
exact minus_IZR.
Qed.

(* Why3 goal *)
Lemma Mul : forall (x:Z) (y:Z),
  ((Reals.Raxioms.IZR (x * y)%Z) = ((Reals.Raxioms.IZR x) * (Reals.Raxioms.IZR y))%R).
exact mult_IZR.
Qed.

(* Why3 goal *)
Lemma Neg : forall (x:Z),
  ((Reals.Raxioms.IZR (-x)%Z) = (-(Reals.Raxioms.IZR x))%R).
exact opp_IZR.
Qed.

