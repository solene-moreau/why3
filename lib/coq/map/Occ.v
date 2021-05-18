(********************************************************************)
(*                                                                  *)
(*  The Why3 Verification Platform   /   The Why3 Development Team  *)
(*  Copyright 2010-2021 --  Inria - CNRS - Paris-Saclay University  *)
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
Require int.Int.
Require map.Map.

(* Why3 goal *)
Definition occ {a:Type} {a_WT:WhyType a} :
  a -> (Numbers.BinNums.Z -> a) -> Numbers.BinNums.Z -> Numbers.BinNums.Z ->
  Numbers.BinNums.Z.
Proof.
intros v m l u.
induction (Z.to_nat (u-l)) as [|delta occ_].
exact Z0.
exact ((if why_decidable_eq (m (l + Z_of_nat delta)%Z) v then 1 else 0) + occ_)%Z.
Defined.

Lemma occ_equation :
  forall {a:Type} {a_WT:WhyType a} v m l u,
  (l < u)%Z ->
  occ v m l u =
  ((if why_decidable_eq (m (u - 1)%Z) v then 1 else 0) + occ v m l (u - 1))%Z.
Proof.
intros a a_WT v m l u Hlu.
assert (0 < u - l)%Z as h1' by omega.
unfold occ.
replace (u - 1 - l)%Z with (u - l - 1)%Z by ring.
replace (u - 1)%Z with (l + (u - l - 1))%Z by ring.
rewrite <- (Z2Nat.id (u - l - 1)) by omega.
rewrite (Z2Nat.inj_sub _ 1) by easy.
destruct (u - l)%Z ; try easy.
simpl.
assert (exists n, Pos.to_nat p = S n) as [n ->].
  exists (Z.to_nat (Z.pred (Zpos p))).
  rewrite Z2Nat.inj_pred.
  apply (S_pred _ O).
  apply Pos2Nat.is_pos.
simpl.
now rewrite <- minus_n_O, Nat2Z.id.
Qed.

Require Import Zwf.

Lemma occ_equation' :
  forall {a:Type} {a_WT:WhyType a} v m l u,
  (l < u)%Z ->
  occ v m l u =
  ((if why_decidable_eq (m l) v then 1 else 0) + occ v m (l + 1) u)%Z.
Proof.
intros a a_WT v m l u Hlu.
induction u using (well_founded_induction (Zwf_well_founded l)).
destruct (Z_lt_le_dec (l + 1) u) as [Hlu'|Hlu'].
rewrite Zplus_comm.
rewrite occ_equation with (1 := Hlu).
rewrite occ_equation with (1 := Hlu').
rewrite <- Zplus_assoc.
apply f_equal.
rewrite Zplus_comm.
apply H.
clear -Hlu' ; unfold Zwf ; omega.
clear -Hlu' ; omega.
replace u with (l + 1)%Z.
unfold occ.
rewrite Z.add_simpl_l.
rewrite <- Zminus_diag_reverse.
simpl.
now rewrite (Zplus_0_r l).
clear -Hlu Hlu' ; omega.
Qed.

(* Why3 goal *)
Lemma occ_empty {a:Type} {a_WT:WhyType a} :
  forall (v:a) (m:Numbers.BinNums.Z -> a) (l:Numbers.BinNums.Z)
    (u:Numbers.BinNums.Z),
  (u <= l)%Z -> ((occ v m l u) = 0%Z).
Proof.
intros v m l u h1.
assert (u - l <= 0)%Z as h1' by omega.
unfold occ.
destruct (u - l)%Z ; try reflexivity.
now elim h1'.
Qed.

(* Why3 goal *)
Lemma occ_right_no_add {a:Type} {a_WT:WhyType a} :
  forall (v:a) (m:Numbers.BinNums.Z -> a) (l:Numbers.BinNums.Z)
    (u:Numbers.BinNums.Z),
  (l < u)%Z -> ~ ((m (u - 1%Z)%Z) = v) ->
  ((occ v m l u) = (occ v m l (u - 1%Z)%Z)).
Proof.
intros v m l u h1 h2.
rewrite occ_equation with (1 := h1).
now destruct why_decidable_eq as [H|H].
Qed.

(* Why3 goal *)
Lemma occ_right_add {a:Type} {a_WT:WhyType a} :
  forall (v:a) (m:Numbers.BinNums.Z -> a) (l:Numbers.BinNums.Z)
    (u:Numbers.BinNums.Z),
  (l < u)%Z -> ((m (u - 1%Z)%Z) = v) ->
  ((occ v m l u) = (1%Z + (occ v m l (u - 1%Z)%Z))%Z).
Proof.
intros v m l u h1 h2.
rewrite occ_equation with (1 := h1).
now destruct why_decidable_eq as [H|H].
Qed.

(* Why3 goal *)
Lemma occ_left_no_add {a:Type} {a_WT:WhyType a} :
  forall (v:a) (m:Numbers.BinNums.Z -> a) (l:Numbers.BinNums.Z)
    (u:Numbers.BinNums.Z),
  (l < u)%Z -> ~ ((m l) = v) -> ((occ v m l u) = (occ v m (l + 1%Z)%Z u)).
Proof.
intros v m l u h1 h2.
rewrite occ_equation' with (1 := h1).
now destruct why_decidable_eq as [H|H].
Qed.

(* Why3 goal *)
Lemma occ_left_add {a:Type} {a_WT:WhyType a} :
  forall (v:a) (m:Numbers.BinNums.Z -> a) (l:Numbers.BinNums.Z)
    (u:Numbers.BinNums.Z),
  (l < u)%Z -> ((m l) = v) ->
  ((occ v m l u) = (1%Z + (occ v m (l + 1%Z)%Z u))%Z).
Proof.
intros v m l u h1 h2.
rewrite occ_equation' with (1 := h1).
now destruct why_decidable_eq as [H|H].
Qed.

(* Why3 goal *)
Lemma occ_bounds {a:Type} {a_WT:WhyType a} :
  forall (v:a) (m:Numbers.BinNums.Z -> a) (l:Numbers.BinNums.Z)
    (u:Numbers.BinNums.Z),
  (l <= u)%Z -> (0%Z <= (occ v m l u))%Z /\ ((occ v m l u) <= (u - l)%Z)%Z.
Proof.
intros v m l u h1.
cut (0 <= u - l)%Z. 2: omega.
replace (occ v m l u) with (occ v m l (l + (u - l)))%Z.
pattern (u - l)%Z; apply Z_lt_induction. 2: omega.
intros.
assert (h: (x = 0 \/ x <> 0)%Z) by omega. destruct h.
now rewrite occ_empty; omega.
destruct (why_decidable_eq (m (l + (x-1))%Z) v).
rewrite occ_right_add.
generalize (H (x-1)%Z); clear H; intros.
assert (0 <= occ v m l (l + (x - 1)) <= x-1)%Z.
apply H; omega.
replace (l + x - 1)%Z with (l+(x-1))%Z by ring.
omega.
omega.
replace (l + x - 1)%Z with (l+(x-1))%Z by ring.
trivial.
rewrite occ_right_no_add.
assert (0 <= occ v m l (l + (x - 1)) <= x-1)%Z.
apply H; omega.
replace (l + x - 1)%Z with (l+(x-1))%Z by ring.
omega.
omega.
replace (l + x - 1)%Z with (l+(x-1))%Z by ring.
trivial.
replace (l + (u-l))%Z with u by ring. trivial.
Qed.

(* Why3 goal *)
Lemma occ_append {a:Type} {a_WT:WhyType a} :
  forall (v:a) (m:Numbers.BinNums.Z -> a) (l:Numbers.BinNums.Z)
    (mid:Numbers.BinNums.Z) (u:Numbers.BinNums.Z),
  (l <= mid)%Z /\ (mid <= u)%Z ->
  ((occ v m l u) = ((occ v m l mid) + (occ v m mid u))%Z).
Proof.
intros v m l mid u (h1,h2).
cut (0 <= u - mid)%Z. 2: omega.
replace (occ v m l u) with (occ v m l (mid + (u - mid)))%Z.
replace (occ v m mid u) with (occ v m mid (mid + (u - mid)))%Z.
pattern (u - mid)%Z; apply Z_lt_induction. 2: omega.
intros.
assert (h: (x = 0 \/ x <> 0)%Z) by omega. destruct h.
rewrite (occ_empty _ _ mid (mid+x)%Z).
subst x. ring_simplify ((mid+0)%Z). ring.
omega.
destruct (why_decidable_eq (m (mid + (x-1))%Z) v).
rewrite (occ_right_add _ _ l (mid+x))%Z.
rewrite (occ_right_add _ _ mid (mid+x))%Z.
generalize (H (x-1)%Z); clear H; intros.
assert ((occ v m l (mid+(x-1)) = (occ v m l mid) + occ v m mid (mid + (x - 1)))%Z).
apply H; omega.
replace (mid + x - 1)%Z with (mid+(x-1))%Z by ring.
omega. omega.
trivial.
replace (mid + x - 1)%Z with (mid+(x-1))%Z by ring. trivial.
omega.
replace (mid + x - 1)%Z with (mid+(x-1))%Z by ring. trivial.

rewrite (occ_right_no_add _ _ l (mid+x))%Z.
rewrite (occ_right_no_add _ _ mid (mid+x))%Z.
generalize (H (x-1)%Z); clear H; intros.
assert ((occ v m l (mid+(x-1)) = (occ v m l mid) + occ v m mid (mid + (x - 1)))%Z).
apply H; omega.
replace (mid + x - 1)%Z with (mid+(x-1))%Z by ring.
omega. omega.
trivial.
replace (mid + x - 1)%Z with (mid+(x-1))%Z by ring. trivial.
omega.
replace (mid + x - 1)%Z with (mid+(x-1))%Z by ring. trivial.

replace (mid + (u-mid))%Z with u by ring. trivial.
replace (mid + (u-mid))%Z with u by ring. trivial.
Qed.

(* Why3 goal *)
Lemma occ_neq {a:Type} {a_WT:WhyType a} :
  forall (v:a) (m:Numbers.BinNums.Z -> a) (l:Numbers.BinNums.Z)
    (u:Numbers.BinNums.Z),
  (forall (i:Numbers.BinNums.Z), (l <= i)%Z /\ (i < u)%Z -> ~ ((m i) = v)) ->
  ((occ v m l u) = 0%Z).
Proof.
intros v m l u.
assert (h: (u < l \/ 0 <= u - l)%Z) by omega. destruct h.
rewrite occ_empty. trivial. omega.
replace u with (l + (u - l))%Z. 2:ring.
generalize H.
pattern (u - l)%Z; apply Z_lt_induction. 2: omega.
clear H; intros.
assert (h: (x = 0 \/ x <> 0)%Z) by omega. destruct h.
now rewrite occ_empty; omega.
destruct (why_decidable_eq (m (l + (x-1))%Z) v).
assert (m (l + (x - 1)) <> v)%Z.
  apply H1; omega.
intuition.
rewrite occ_right_no_add.
replace (l+x-1)%Z with (l+(x-1))%Z by ring.
apply H; intuition.
apply (H1 i). omega. assumption.
omega.
replace (l + x - 1)%Z with (l+(x-1))%Z by ring.
trivial.
Qed.

(* Why3 goal *)
Lemma occ_exists {a:Type} {a_WT:WhyType a} :
  forall (v:a) (m:Numbers.BinNums.Z -> a) (l:Numbers.BinNums.Z)
    (u:Numbers.BinNums.Z),
  (0%Z < (occ v m l u))%Z ->
  exists i:Numbers.BinNums.Z, ((l <= i)%Z /\ (i < u)%Z) /\ ((m i) = v).
Proof.
intros v m l u h1.
assert (h: (u < l \/ 0 <= u - l)%Z) by omega. destruct h.
rewrite occ_empty in h1. elimtype False; omega. omega.
generalize h1.
replace u with (l + (u - l))%Z. 2:ring.
generalize H.
pattern (u - l)%Z; apply Z_lt_induction. 2: omega.
clear H; intros.
assert (h: (x = 0 \/ x <> 0)%Z) by omega. destruct h.
rewrite occ_empty in h0. elimtype False; omega. omega.
destruct (why_decidable_eq (m (l + (x-1))%Z) v).
exists (l+(x-1))%Z. split. omega. now trivial.
destruct (H (x-1))%Z as (i,(hi1,hi2)). omega. omega.
rewrite occ_right_no_add in h0.
replace (l + (x - 1))%Z with (l+x-1)%Z by ring. trivial.
omega.
replace (l + x - 1)%Z with (l+(x-1))%Z by ring. trivial.
exists i. split. omega. assumption.
Qed.

(* Why3 goal *)
Lemma occ_pos {a:Type} {a_WT:WhyType a} :
  forall (m:Numbers.BinNums.Z -> a) (l:Numbers.BinNums.Z)
    (u:Numbers.BinNums.Z) (i:Numbers.BinNums.Z),
  (l <= i)%Z /\ (i < u)%Z -> (0%Z < (occ (m i) m l u))%Z.
Proof.
intros m l u i (h1,h2).
pose (v := m i). fold v.
assert (occ v m l u = occ v m l i + occ v m i u)%Z.
  apply occ_append. omega.
assert (occ v m i u = occ v m i (i+1) + occ v m (i+1) u)%Z.
  apply occ_append. omega.
assert (occ v m i (i + 1) = 1)%Z.
rewrite occ_right_add.
  ring_simplify (i+1-1)%Z. rewrite occ_empty. ring. omega. omega.
ring_simplify (i+1-1)%Z. auto.
assert (0 <= occ v m l i <= i -l)%Z. apply occ_bounds. omega.
assert (0 <= occ v m i (i+1) <= (i+1)-i)%Z. apply occ_bounds. omega.
assert (0 <= occ v m (i+1) u <= u - (i+1))%Z. apply occ_bounds. omega.
omega.
Qed.

(* Why3 goal *)
Lemma occ_eq {a:Type} {a_WT:WhyType a} :
  forall (v:a) (m1:Numbers.BinNums.Z -> a) (m2:Numbers.BinNums.Z -> a)
    (l:Numbers.BinNums.Z) (u:Numbers.BinNums.Z),
  (forall (i:Numbers.BinNums.Z), (l <= i)%Z /\ (i < u)%Z ->
   ((m1 i) = (m2 i))) ->
  ((occ v m1 l u) = (occ v m2 l u)).
Proof.
intros v m1 m2 l u h1.
assert (h: (u < l \/ 0 <= u - l)%Z) by omega. destruct h.
rewrite occ_empty.
rewrite occ_empty. trivial.
omega. omega.
generalize h1.
replace u with (l + (u - l))%Z. 2:ring.
generalize H.
pattern (u - l)%Z; apply Z_lt_induction. 2: omega.
clear H; intros.
assert (h: (x = 0 \/ x <> 0)%Z) by omega. destruct h.
rewrite occ_empty. rewrite occ_empty. trivial. omega. omega.
destruct (why_decidable_eq (m1 (l + (x-1))%Z) v).
rewrite occ_right_add.
rewrite (occ_right_add v m2).
apply f_equal.
replace (l + x - 1)%Z with (l+(x-1))%Z by ring.
apply H. omega. omega. intros. apply h0. omega. omega.
replace (l + x - 1)%Z with (l+(x-1))%Z by ring.
rewrite <- h0. trivial. omega. omega.
replace (l + x - 1)%Z with (l+(x-1))%Z by ring. assumption.

rewrite occ_right_no_add.
rewrite (occ_right_no_add v m2).
replace (l + x - 1)%Z with (l+(x-1))%Z by ring.
apply H. omega. omega. intros. apply h0. omega. omega.
replace (l + x - 1)%Z with (l+(x-1))%Z by ring.
rewrite <- h0. trivial. omega. omega.
replace (l + x - 1)%Z with (l+(x-1))%Z by ring. assumption.
Qed.

Lemma occ_single {a:Type} {a_WT:WhyType a} :
  forall (m:Z -> a) (i:Z) (x:a),
  occ x m i (i + 1) = if why_decidable_eq (m i) x then 1%Z else 0%Z.
Proof.
intros m i x.
rewrite occ_equation'.
unfold occ, nat_rect.
rewrite Z.sub_diag.
apply Zplus_0_r.
apply Z.lt_succ_diag_r.
Qed.

Lemma occ_set {a:Type} {a_WT:WhyType a} :
  forall (m:Z -> a) (l:Z) (u:Z) (i:Z) (x:a) (y:a),
  (l <= i < u)%Z ->
  occ y (map.Map.set m i x) l u = (occ y m l u +
  (if why_decidable_eq x y then 1 else 0) -
  if why_decidable_eq (m i) y then 1 else 0)%Z.
Proof.
intros m l u i x y H.
rewrite 2!(occ_append _ _ l i u) by omega.
rewrite 2!(occ_append _ _ i (i + 1) u) by omega.
rewrite 2!occ_single.
rewrite (proj1 (Map.set'def _ _ _ _) eq_refl).
rewrite 2!(occ_eq _ (Map.set m i x) m).
ring.
intros j H1.
apply Map.set'def.
omega.
intros j H1.
apply Map.set'def.
omega.
Qed.

(* Why3 goal *)
Lemma occ_exchange {a:Type} {a_WT:WhyType a} :
  forall (m:Numbers.BinNums.Z -> a) (l:Numbers.BinNums.Z)
    (u:Numbers.BinNums.Z) (i:Numbers.BinNums.Z) (j:Numbers.BinNums.Z) 
    (x:a) (y:a) (z:a),
  (l <= i)%Z /\ (i < u)%Z -> (l <= j)%Z /\ (j < u)%Z -> ~ (i = j) ->
  ((occ z (map.Map.set (map.Map.set m i x) j y) l u) =
   (occ z (map.Map.set (map.Map.set m i y) j x) l u)).
Proof.
intros m l u i j x y z h1 h2 h3.
rewrite 4!occ_set by assumption.
apply not_eq_sym in h3.
rewrite 2!(proj2 (Map.set'def _ _ _ _) h3).
ring.
Qed.

