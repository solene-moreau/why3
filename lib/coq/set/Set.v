(********************************************************************)
(*                                                                  *)
(*  The Why3 Verification Platform   /   The Why3 Development Team  *)
(*  Copyright 2010-2020   --   Inria - CNRS - Paris-Sud University  *)
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
Require HighOrd.
Require map.Map.
Require map.Const.

(* Why3 goal *)
Definition any_function {a:Type} {a_WT:WhyType a} {b:Type} {b_WT:WhyType b} :
  a -> b.
Proof.

Defined.

Require Import ClassicalEpsilon.

Lemma predicate_extensionality:
  forall A (P Q : A -> bool),
    (forall x, P x = Q x) -> P = Q.
Admitted.

(* Why3 assumption *)
Definition set (a:Type) := a -> Init.Datatypes.bool.

Global Instance set_WhyType : forall (a:Type) {a_WT:WhyType a}, WhyType (set a).
Proof.
intros.
split.
exact (fun _ => false).
intros x y.
apply excluded_middle_informative.
Qed.

(* Why3 assumption *)
Definition mem {a:Type} {a_WT:WhyType a} (x:a) (s:a -> Init.Datatypes.bool) :
    Prop :=
  ((s x) = Init.Datatypes.true).

Hint Unfold mem.

(* Why3 assumption *)
Definition infix_eqeq {a:Type} {a_WT:WhyType a} (s1:a -> Init.Datatypes.bool)
    (s2:a -> Init.Datatypes.bool) : Prop :=
  forall (x:a), mem x s1 <-> mem x s2.

Notation "x == y" := (infix_eqeq x y) (at level 70, no associativity).

(* Why3 goal *)
Lemma extensionality {a:Type} {a_WT:WhyType a} :
  forall (s1:a -> Init.Datatypes.bool) (s2:a -> Init.Datatypes.bool),
  infix_eqeq s1 s2 -> (s1 = s2).
Proof.
intros s1 s2 h1.
apply predicate_extensionality.
intros x.
generalize (h1 x).
unfold mem.
intros [h2 h3].
destruct (s1 x).
now rewrite h2.
destruct (s2 x).
now apply h3.
easy.
Qed.

(* Why3 assumption *)
Definition subset {a:Type} {a_WT:WhyType a} (s1:a -> Init.Datatypes.bool)
    (s2:a -> Init.Datatypes.bool) : Prop :=
  forall (x:a), mem x s1 -> mem x s2.

(* Why3 goal *)
Lemma subset_refl {a:Type} {a_WT:WhyType a} :
  forall (s:a -> Init.Datatypes.bool), subset s s.
Proof.
now intros s x.
Qed.

(* Why3 goal *)
Lemma subset_trans {a:Type} {a_WT:WhyType a} :
  forall (s1:a -> Init.Datatypes.bool) (s2:a -> Init.Datatypes.bool)
    (s3:a -> Init.Datatypes.bool),
  subset s1 s2 -> subset s2 s3 -> subset s1 s3.
Proof.
intros s1 s2 s3 h1 h2 x H.
now apply h2, h1.
Qed.

(* Why3 assumption *)
Definition is_empty {a:Type} {a_WT:WhyType a} (s:a -> Init.Datatypes.bool) :
    Prop :=
  forall (x:a), ~ mem x s.

(* Why3 goal *)
Lemma is_empty_empty {a:Type} {a_WT:WhyType a} :
  is_empty (map.Const.const Init.Datatypes.false : a -> Init.Datatypes.bool).
Proof.
now intros x.
Qed.

(* Why3 goal *)
Lemma empty_is_empty {a:Type} {a_WT:WhyType a} :
  forall (s:a -> Init.Datatypes.bool), is_empty s ->
  (s = (map.Const.const Init.Datatypes.false : a -> Init.Datatypes.bool)).
Proof.
intros s h1.
apply predicate_extensionality.
unfold is_empty in h1; unfold Const.const.
unfold mem in h1.
intros x. generalize (h1 x).
destruct (s x); intuition.
Qed.

(* Why3 goal *)
Lemma mem_singleton {a:Type} {a_WT:WhyType a} :
  forall (x:a) (y:a),
  mem y
  (map.Map.set
   (map.Const.const Init.Datatypes.false : a -> Init.Datatypes.bool) x
   Init.Datatypes.true) ->
  (y = x).
Proof.
intros x y h1.
unfold mem, Map.set, Const.const in h1.
destruct (why_decidable_eq x y) as [->|H] ; intuition.
discriminate h1.
Qed.

(* Why3 goal *)
Lemma add_remove {a:Type} {a_WT:WhyType a} :
  forall (x:a) (s:a -> Init.Datatypes.bool), mem x s ->
  ((map.Map.set (map.Map.set s x Init.Datatypes.false) x Init.Datatypes.true)
   = s).
Proof.
intros x s h1.
apply extensionality; intro y.
unfold mem, Map.set. unfold mem in h1.
destruct (why_decidable_eq x y) as [->|H] ; intuition.
Qed.

(* Why3 goal *)
Lemma remove_add {a:Type} {a_WT:WhyType a} :
  forall (x:a) (s:a -> Init.Datatypes.bool),
  ((map.Map.set (map.Map.set s x Init.Datatypes.true) x Init.Datatypes.false)
   = (map.Map.set s x Init.Datatypes.false)).
Proof.
intros x s.
apply extensionality; intro y.
unfold mem, Map.set.
destruct (why_decidable_eq x y) as [->|H] ; intuition.
Qed.

(* Why3 goal *)
Lemma subset_remove {a:Type} {a_WT:WhyType a} :
  forall (x:a) (s:a -> Init.Datatypes.bool),
  subset (map.Map.set s x Init.Datatypes.false) s.
Proof.
intros x s y.
unfold mem, Map.set.
destruct (why_decidable_eq x y) as [->|H] ; intuition.
Qed.

(* Why3 goal *)
Definition union {a:Type} {a_WT:WhyType a} :
  (a -> Init.Datatypes.bool) -> (a -> Init.Datatypes.bool) ->
  a -> Init.Datatypes.bool.
Proof.
intros s1 s2.
exact (fun x => orb (s1 x) (s2 x)).
Defined.

(* Why3 goal *)
Lemma union'def {a:Type} {a_WT:WhyType a} :
  forall (s1:a -> Init.Datatypes.bool) (s2:a -> Init.Datatypes.bool) (x:a),
  ((union s1 s2 x) = Init.Datatypes.true) <-> mem x s1 \/ mem x s2.
Proof.
intros s1 s2 x.
apply Bool.orb_true_iff.
Qed.

(* Why3 goal *)
Lemma subset_union_1 {a:Type} {a_WT:WhyType a} :
  forall (s1:a -> Init.Datatypes.bool) (s2:a -> Init.Datatypes.bool),
  subset s1 (union s1 s2).
Proof.
intros s1 s2.
unfold subset, union.
unfold mem.
intros x hx.
apply Bool.orb_true_iff. intuition.
Qed.

(* Why3 goal *)
Lemma subset_union_2 {a:Type} {a_WT:WhyType a} :
  forall (s1:a -> Init.Datatypes.bool) (s2:a -> Init.Datatypes.bool),
  subset s2 (union s1 s2).
Proof.
intros s1 s2.
unfold subset, union.
unfold mem.
intros x hx.
apply Bool.orb_true_iff. intuition.
Qed.

(* Why3 goal *)
Definition inter {a:Type} {a_WT:WhyType a} :
  (a -> Init.Datatypes.bool) -> (a -> Init.Datatypes.bool) ->
  a -> Init.Datatypes.bool.
Proof.
intros s1 s2.
exact (fun x => andb (s1 x) (s2 x)).
Defined.

(* Why3 goal *)
Lemma inter'def {a:Type} {a_WT:WhyType a} :
  forall (s1:a -> Init.Datatypes.bool) (s2:a -> Init.Datatypes.bool) (x:a),
  ((inter s1 s2 x) = Init.Datatypes.true) <-> mem x s1 /\ mem x s2.
Proof.
intros s1 s2 x.
apply Bool.andb_true_iff.
Qed.

(* Why3 goal *)
Lemma subset_inter_1 {a:Type} {a_WT:WhyType a} :
  forall (s1:a -> Init.Datatypes.bool) (s2:a -> Init.Datatypes.bool),
  subset (inter s1 s2) s1.
Proof.
intros s1 s2.
unfold subset, inter.
unfold mem.
intros x hx.
apply Bool.andb_true_iff in hx. intuition.
Qed.

(* Why3 goal *)
Lemma subset_inter_2 {a:Type} {a_WT:WhyType a} :
  forall (s1:a -> Init.Datatypes.bool) (s2:a -> Init.Datatypes.bool),
  subset (inter s1 s2) s2.
Proof.
intros s1 s2.
unfold subset, inter.
unfold mem.
intros x hx.
apply Bool.andb_true_iff in hx. intuition.
Qed.

(* Why3 goal *)
Definition diff {a:Type} {a_WT:WhyType a} :
  (a -> Init.Datatypes.bool) -> (a -> Init.Datatypes.bool) ->
  a -> Init.Datatypes.bool.
Proof.
intros s1 s2.
exact (fun x => andb (s1 x) (negb (s2 x))).
Defined.

(* Why3 goal *)
Lemma diff'def {a:Type} {a_WT:WhyType a} :
  forall (s1:a -> Init.Datatypes.bool) (s2:a -> Init.Datatypes.bool) (x:a),
  ((diff s1 s2 x) = Init.Datatypes.true) <-> mem x s1 /\ ~ mem x s2.
Proof.
intros s1 s2 x.
unfold mem, diff.
rewrite Bool.not_true_iff_false.
rewrite <- Bool.negb_true_iff.
apply Bool.andb_true_iff.
Qed.

(* Why3 goal *)
Lemma subset_diff {a:Type} {a_WT:WhyType a} :
  forall (s1:a -> Init.Datatypes.bool) (s2:a -> Init.Datatypes.bool),
  subset (diff s1 s2) s1.
Proof.
intros s1 s2 x.
unfold mem.
rewrite diff'def. intuition.
Qed.

(* Why3 goal *)
Definition complement {a:Type} {a_WT:WhyType a} :
  (a -> Init.Datatypes.bool) -> a -> Init.Datatypes.bool.
Proof.
intros s.
exact (fun x => negb (s x)).
Defined.

(* Why3 goal *)
Lemma complement'def {a:Type} {a_WT:WhyType a} :
  forall (s:a -> Init.Datatypes.bool) (x:a),
  ((complement s x) = Init.Datatypes.true) <-> ~ mem x s.
Proof.
intros s x.
unfold mem, complement.
rewrite Bool.not_true_iff_false.
apply Bool.negb_true_iff.
Qed.

(* Why3 goal *)
Definition pick {a:Type} {a_WT:WhyType a} : (a -> Init.Datatypes.bool) -> a.
Proof.
intros s.
assert (i: inhabited a) by (apply inhabits, why_inhabitant).
exact (epsilon i (fun x => mem x s)).
Defined.

(* Why3 goal *)
Lemma pick_def {a:Type} {a_WT:WhyType a} :
  forall (s:a -> Init.Datatypes.bool), ~ is_empty s -> mem (pick s) s.
Proof.
intros s h1.
unfold pick.
apply epsilon_spec.
now apply not_all_not_ex.
Qed.

(* Why3 assumption *)
Definition disjoint {a:Type} {a_WT:WhyType a} (s1:a -> Init.Datatypes.bool)
    (s2:a -> Init.Datatypes.bool) : Prop :=
  forall (x:a), ~ mem x s1 \/ ~ mem x s2.

(* Why3 goal *)
Lemma disjoint_inter_empty {a:Type} {a_WT:WhyType a} :
  forall (s1:a -> Init.Datatypes.bool) (s2:a -> Init.Datatypes.bool),
  disjoint s1 s2 <-> is_empty (inter s1 s2).
Proof.
intros s1 s2.
unfold disjoint, is_empty, inter.
unfold mem.
intuition.
destruct (H x); intuition.
apply H1.
rewrite Bool.andb_true_iff in H0. intuition.
apply H1.
rewrite Bool.andb_true_iff in H0. intuition.
generalize (H x).
rewrite Bool.andb_true_iff.
destruct (s1 x); destruct (s2 x); intuition.
Qed.

(* Why3 goal *)
Lemma disjoint_diff_eq {a:Type} {a_WT:WhyType a} :
  forall (s1:a -> Init.Datatypes.bool) (s2:a -> Init.Datatypes.bool),
  disjoint s1 s2 <-> ((diff s1 s2) = s1).
Proof.
intros s1 s2.
unfold disjoint, diff.
unfold mem.
intuition.
apply (extensionality _ s1). unfold infix_eqeq.
unfold mem.
intuition.
destruct (H x); intuition.
rewrite Bool.andb_true_iff in H0. intuition.
rewrite Bool.andb_true_iff in H0. intuition.
rewrite Bool.andb_true_iff.
intuition.
destruct (H x); intuition.
rewrite <- H.
rewrite Bool.andb_true_iff.
destruct (s2 x); intuition.
Qed.

(* Why3 goal *)
Lemma disjoint_diff_s2 {a:Type} {a_WT:WhyType a} :
  forall (s1:a -> Init.Datatypes.bool) (s2:a -> Init.Datatypes.bool),
  disjoint (diff s1 s2) s2.
Proof.
intros s1 s2.
unfold disjoint, diff.
unfold mem.
intros x.
rewrite Bool.andb_true_iff.
destruct (s2 x); intuition.
Qed.

(* Why3 goal *)
Definition map {a:Type} {a_WT:WhyType a} {b:Type} {b_WT:WhyType b} :
  (a -> b) -> (a -> Init.Datatypes.bool) -> b -> Init.Datatypes.bool.
Proof.
intros f s y.
set (P := fun (x:a) => mem x s /\ y = f x).
assert (inhabited a).
destruct a_WT.
exact (inhabits why_inhabitant).
set (x := epsilon H P).
destruct b_WT.
destruct (why_decidable_eq y (f x)).
exact (s x).
exact false.
Defined.

(* Why3 goal *)
Lemma map'def {a:Type} {a_WT:WhyType a} {b:Type} {b_WT:WhyType b} :
  forall (f:a -> b) (u:a -> Init.Datatypes.bool) (y:b),
  ((map f u y) = Init.Datatypes.true) <->
  (exists x:a, mem x u /\ (y = (f x))).
Proof.
intros f u y.
unfold map, mem.
destruct b_WT.
destruct a_WT.
set (P := fun (x:a) => u x = true /\ y = f x).
set (inh := (inhabits why_inhabitant0)).
generalize (epsilon_spec inh P).
set (x := epsilon inh P).
destruct (classic (exists x, P x)).
destruct (why_decidable_eq y (f x)).
intuition.
unfold P in H1. intuition.
intuition.
unfold P in H1. intuition.
destruct (why_decidable_eq y (f x)).
intuition.
exists x; unfold P; intuition.
intuition.
discriminate H1.
Qed.

(* Why3 goal *)
Lemma mem_map {a:Type} {a_WT:WhyType a} {b:Type} {b_WT:WhyType b} :
  forall (f:a -> b) (u:a -> Init.Datatypes.bool), forall (x:a), mem x u ->
  mem (f x) (map f u).
Proof.
intros f u x h1.
generalize (map'def f u (f x)).
intuition.
apply H1.
exists x; intuition.
Qed.

