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
Require int.Int.
Require list.List.
Require list.Length.
Require list.Mem.
Require list.Nth.
Require option.Option.
Require list.NthLength.
Require list.Append.

(* Why3 goal *)
Lemma nth_append_1 {a:Type} {a_WT:WhyType a} :
  forall (l1:Init.Datatypes.list a) (l2:Init.Datatypes.list a)
    (i:Numbers.BinNums.Z),
  (i < (list.Length.length l1))%Z ->
  ((list.Nth.nth i (Init.Datatypes.app l1 l2)) = (list.Nth.nth i l1)).
Proof.
intros l1.
induction l1 as [|x l1].
intros l2 i.
apply NthLength.nth_none_1.
intros l2 i Hi.
simpl.
generalize (Zeq_bool_if i 0).
case Zeq_bool.
easy.
intros _.
apply IHl1.
assert (i < 1 + Length.length l1)%Z by exact Hi.
omega.
Qed.

(* Why3 goal *)
Lemma nth_append_2 {a:Type} {a_WT:WhyType a} :
  forall (l1:Init.Datatypes.list a) (l2:Init.Datatypes.list a)
    (i:Numbers.BinNums.Z),
  ((list.Length.length l1) <= i)%Z ->
  ((list.Nth.nth i (Init.Datatypes.app l1 l2)) =
   (list.Nth.nth (i - (list.Length.length l1))%Z l2)).
Proof.
intros l1.
induction l1 as [|x l1].
intros l2 i _.
simpl.
now rewrite Zminus_0_r.
intros l2 i.
change (Length.length (x :: l1)) with (1 + Length.length l1)%Z.
intros Hi.
replace (i - (1 + Length.length l1))%Z with ((i - 1) - Length.length l1)%Z by ring.
simpl.
generalize (Zeq_bool_if i 0).
case Zeq_bool.
intros Hi'.
exfalso.
generalize (Length.Length_nonnegative l1).
omega.
intros _.
apply IHl1.
omega.
Qed.

