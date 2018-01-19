(********************************************************************)
(*                                                                  *)
(*  The Why3 Verification Platform   /   The Why3 Development Team  *)
(*  Copyright 2010-2018   --   Inria - CNRS - Paris-Sud University  *)
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
(* from_int is replaced with (BuiltIn.IZR x) by the coq driver *)

(* Why3 goal *)
Lemma Zero : ((BuiltIn.IZR 0%Z) = 0%R).
Proof.
split.
Qed.

(* Why3 goal *)
Lemma One : ((BuiltIn.IZR 1%Z) = 1%R).
Proof.
split.
Qed.

(* Why3 goal *)
Lemma Add : forall (x:Z) (y:Z),
  ((BuiltIn.IZR (x + y)%Z) = ((BuiltIn.IZR x) + (BuiltIn.IZR y))%R).
Proof.
exact plus_IZR.
Qed.

(* Why3 goal *)
Lemma Sub : forall (x:Z) (y:Z),
  ((BuiltIn.IZR (x - y)%Z) = ((BuiltIn.IZR x) - (BuiltIn.IZR y))%R).
Proof.
exact minus_IZR.
Qed.

(* Why3 goal *)
Lemma Mul : forall (x:Z) (y:Z),
  ((BuiltIn.IZR (x * y)%Z) = ((BuiltIn.IZR x) * (BuiltIn.IZR y))%R).
Proof.
exact mult_IZR.
Qed.

(* Why3 goal *)
Lemma Neg : forall (x:Z), ((BuiltIn.IZR (-x)%Z) = (-(BuiltIn.IZR x))%R).
Proof.
exact opp_IZR.
Qed.

(* Why3 goal *)
Lemma Monotonic :
  forall (x:Z) (y:Z), (x <= y)%Z -> ((BuiltIn.IZR x) <= (BuiltIn.IZR y))%R.
Proof.
exact (IZR_le).
Qed.

