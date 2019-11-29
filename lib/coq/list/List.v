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
Definition is_nil {a:Type} {a_WT:WhyType a} (l:Init.Datatypes.list a) : Prop :=
  match l with
  | Init.Datatypes.nil => True
  | Init.Datatypes.cons _ _ => False
  end.

(* Why3 goal *)
Lemma is_nil'spec {a:Type} {a_WT:WhyType a} :
  forall (l:Init.Datatypes.list a), is_nil l <-> (l = Init.Datatypes.nil).
Proof.
intros l.
split.
now destruct l.
now intros ->.
Qed.

Global Instance list_WhyType : forall T {T_WT : WhyType T}, WhyType (list T).
Proof.
split.
apply nil.
induction x as [|xh x] ; intros [|yh y] ; try (now right).
now left.
destruct (IHx y) as [->|E].
destruct (why_decidable_eq xh yh) as [->|Eh].
now left.
right.
contradict Eh.
now injection Eh.
right.
contradict E.
now injection E.
Qed.
