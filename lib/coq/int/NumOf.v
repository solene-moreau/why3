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
Require HighOrd.
Require int.Int.

Fixpoint numof_aux (f : Z -> bool) (a : Z) (n : nat) : Z :=
  match n with
    | S n => (numof_aux f a n + (if f (a + (Z.of_nat n)) then 1%Z else 0%Z))%Z
    | 0 => 0%Z
  end.

(* Why3 goal *)
Definition numof: (Z -> bool) -> Z -> Z -> Z.
  exact (fun f a b => numof_aux f a (Z.to_nat (b - a))).
Defined.

(* Why3 goal *)
Lemma Numof_empty : forall (p:(Z -> bool)) (a:Z) (b:Z), (b <= a)%Z ->
  ((numof p a b) = 0%Z).
  intros p a b h1.
  unfold numof.
  assert (Z.to_nat (b - a) = 0).
  revert h1.
  rewrite <-Z.le_sub_0.
  destruct (b - a)%Z; intro.
  easy.
  assert (0 < Z.pos p0)%Z by (apply Pos2Z.is_pos).
  assert False by omega; easy.
  apply Z2Nat.inj_neg.
  rewrite H; easy.
Qed.

(* Why3 goal *)
Lemma Numof_right_no_add : forall (p:(Z -> bool)) (a:Z) (b:Z), (a < b)%Z ->
  ((~ ((p (b - 1%Z)%Z) = true)) -> ((numof p a b) = (numof p a
  (b - 1%Z)%Z))).
intros p a b h1 h2.
unfold numof, numof.
rewrite S_pred with (m := 0) (n := Z.to_nat (b - a)).
rewrite <-Z2Nat.inj_pred.
simpl.
rewrite Z2Nat.id by omega.
rewrite <-Z.sub_pred_l, Z.add_sub_assoc, Int.Comm with (x := a), <-Z.add_sub_assoc, <-Zminus_diag_reverse, <- Z.sub_1_r, <-Zplus_0_r_reverse.
apply Bool.not_true_is_false in h2.
rewrite h2; omega.
change (Z.to_nat 0 < Z.to_nat (b - a)).
rewrite <-Z2Nat.inj_lt; omega.
Qed.

(* Why3 goal *)
Lemma Numof_right_add : forall (p:(Z -> bool)) (a:Z) (b:Z), (a < b)%Z -> (((p
  (b - 1%Z)%Z) = true) -> ((numof p a b) = (1%Z + (numof p a
  (b - 1%Z)%Z))%Z)).
intros p a b h1 h2.
unfold numof, numof.
rewrite S_pred with (m := 0) (n := Z.to_nat (b - a)), <-Z2Nat.inj_pred.
simpl numof_aux.
rewrite Z2Nat.id by omega.
rewrite <-Z.sub_pred_l, Z.add_sub_assoc, Int.Comm with (x := a), <-Z.add_sub_assoc, <-Zminus_diag_reverse, <- Z.sub_1_r, <-Zplus_0_r_reverse.
rewrite h2; omega.
change (Z.to_nat 0 < Z.to_nat (b - a)).
rewrite <-Z2Nat.inj_lt; omega.
Qed.

(* Why3 goal *)
Lemma Numof_bounds : forall (p:(Z -> bool)) (a:Z) (b:Z), (a < b)%Z ->
  ((0%Z <= (numof p a b))%Z /\ ((numof p a b) <= (b - a)%Z)%Z).
  intros p a b h1.
  unfold numof.
  set (x := Z.to_nat (b - a)).
  rewrite <-Z2Nat.id with (n := (b - a)%Z) by omega.
  change (0 <= numof_aux p a x <= Z.of_nat x)%Z.
  induction x.
  simpl; omega.
  rewrite Nat2Z.inj_succ; simpl numof_aux.
  case (p (a + Z.of_nat x)%Z); omega.
Qed.

(* Why3 goal *)
Lemma Numof_append : forall (p:(Z -> bool)) (a:Z) (b:Z) (c:Z), ((a <= b)%Z /\
  (b <= c)%Z) -> ((numof p a c) = ((numof p a b) + (numof p b c))%Z).
  intros p a b c (h1,h2).
  pattern c.
  apply Zlt_lower_bound_ind with (z := b); auto.
  intros.
  case (Z.eq_dec b x).
  intro e; rewrite e.
  rewrite Numof_empty with (a := x) (b := x); omega.
  intro.
  destruct (Bool.bool_dec (p (x - 1)%Z) true).
  rewrite Numof_right_add, Numof_right_add with (a := b) (b := x); auto with zarith.
  generalize (H (x - 1)%Z).
  intuition.
  rewrite Numof_right_no_add, Numof_right_no_add with (a := b) (b := x); auto with zarith.
Qed.

Lemma numof_succ: forall p a, numof p a (a + 1) = (if p a then 1%Z else 0%Z).
  intros.
  unfold numof.
  replace (a + 1 - a)%Z with 1%Z by omega.
  simpl.
  rewrite <-Zplus_0_r_reverse.
  trivial.
Qed.

Lemma numof_pred: forall p a, numof p (a - 1) a = (if p (a - 1)%Z then 1%Z else 0%Z).
  intros.
  replace (numof p (a - 1) a)%Z with (numof p (a - 1) ((a - 1) + 1))%Z.
  apply numof_succ.
  repeat apply f_equal.
  omega.
Qed.

(* Why3 goal *)
Lemma Numof_left_no_add : forall (p:(Z -> bool)) (a:Z) (b:Z), (a < b)%Z ->
  ((~ ((p a) = true)) -> ((numof p a b) = (numof p (a + 1%Z)%Z b))).
  intros p a b h1 h2.
  rewrite Numof_append with (b := (a+1)%Z) by omega.
  rewrite (numof_succ p a).
  apply Bool.not_true_is_false in h2.
  rewrite h2; trivial.
Qed.

(* Why3 goal *)
Lemma Numof_left_add : forall (p:(Z -> bool)) (a:Z) (b:Z), (a < b)%Z -> (((p
  a) = true) -> ((numof p a b) = (1%Z + (numof p (a + 1%Z)%Z b))%Z)).
  intros p a b h1 h2.
  rewrite Numof_append with (b := (a+1)%Z) by omega.
  rewrite (numof_succ p a).
  rewrite h2; trivial.
Qed.

(* Why3 goal *)
Lemma Empty : forall (p:(Z -> bool)) (a:Z) (b:Z), (forall (n:Z),
  ((a <= n)%Z /\ (n < b)%Z) -> ~ ((p n) = true)) -> ((numof p a b) = 0%Z).
  intros p a b.
  case (Z_lt_le_dec a b); intro; [|intro; apply Numof_empty]; auto.
  pattern b.
  apply Zlt_lower_bound_ind with (z := a); auto with zarith; intros.
  case (Z.eq_dec a x); intro e.
  rewrite e; apply Numof_empty; omega.
  rewrite Numof_append with (b := (x - 1)%Z) by omega.
  assert (numof p (x - 1) x = 0)%Z.
  rewrite numof_pred.
  assert (a <= (x - 1)%Z < x)%Z as H2 by omega.
  generalize (H1 (x - 1)%Z H2).
  intro H3; apply Bool.not_true_is_false in H3; rewrite H3; trivial.
  rewrite H2.
  rewrite H; auto with zarith.
Qed.

(* Why3 goal *)
Lemma Full : forall (p:(Z -> bool)) (a:Z) (b:Z), (a <= b)%Z ->
  ((forall (n:Z), ((a <= n)%Z /\ (n < b)%Z) -> ((p n) = true)) -> ((numof p a
  b) = (b - a)%Z)).
  intros p a b h1.
  pattern b.
  apply Zlt_lower_bound_ind with (z := a); auto with zarith; intros.
  case (Z.eq_dec a x); intro e.
  rewrite e; rewrite Zminus_diag; apply Numof_empty; omega.
  rewrite Numof_append with (b := (x - 1)%Z) by omega.
  assert (numof p (x - 1) x = 1)%Z.
  rewrite numof_pred.
  assert (a <= (x - 1)%Z < x)%Z as H2 by omega.
  generalize (H1 (x - 1)%Z H2).
  intro; rewrite H3; trivial.
  rewrite H2.
  rewrite H; auto with zarith.
Qed.

Lemma numof_nat: forall p a b, (0 <= numof p a b)%Z.
  intros.
  case (Z_lt_le_dec a b); intro; [|rewrite Numof_empty; auto with zarith].
  pattern b.
  apply Zlt_lower_bound_ind with (z := a) (x := b); auto with zarith; intros.
  case (Z.eq_dec a x); intro e.
  rewrite e; rewrite Numof_empty; omega.
  rewrite Numof_append with (b := (x - 1)%Z) by omega.
  apply Z.add_nonneg_nonneg.
  apply H; omega.
  rewrite numof_pred.
  case (p (x - 1)%Z); easy.
Qed.

Lemma numof_pos: forall p a b k, (a <= k < b)%Z -> p k = true -> (0 < numof p a b)%Z.
  intros p a b k h.
  generalize h; pattern b.
  apply Zlt_lower_bound_ind with (z := (a + 1)%Z) (x := b); auto with zarith; intros.
  rewrite Z.add_1_r in H0; apply Zle_succ_gt in H0.
  rewrite Numof_append with (b := (x - 1)%Z) by omega.
  case (Z.eq_dec k (x-1)); intro e.
  rewrite e in H1.
  apply Z.add_nonneg_pos.
  apply numof_nat.
  rewrite numof_pred, H1; easy.
  apply Z.add_pos_nonneg.
  apply H; auto with zarith.
  apply numof_nat.
Qed.

(* Why3 goal *)
Lemma numof_increasing : forall (p:(Z -> bool)) (i:Z) (j:Z) (k:Z),
  ((i <= j)%Z /\ (j <= k)%Z) -> ((numof p i j) <= (numof p i k))%Z.
intros p i j k (h1,h2).
rewrite (Numof_append p i j k) by omega.
rewrite <-Z.le_sub_le_add_l, Zminus_diag.
apply numof_nat.
Qed.

(* Why3 goal *)
Lemma numof_strictly_increasing : forall (p:(Z -> bool)) (i:Z) (j:Z) (k:Z)
  (l:Z), ((i <= j)%Z /\ ((j <= k)%Z /\ (k < l)%Z)) -> (((p k) = true) ->
  ((numof p i j) < (numof p i l))%Z).
intros p i j k l (h1,(h2,h3)) h4.
rewrite (Numof_append p i j l) by omega.
rewrite <-Z.lt_sub_lt_add_l, Zminus_diag.
apply numof_pos with (k := k); auto with zarith.
Qed.

(* Why3 goal *)
Lemma numof_change_any : forall (p1:(Z -> bool)) (p2:(Z -> bool)) (a:Z)
  (b:Z), (forall (j:Z), ((a <= j)%Z /\ (j < b)%Z) -> (((p1 j) = true) -> ((p2
  j) = true))) -> ((numof p1 a b) <= (numof p2 a b))%Z.
  intros p1 p2 a b.
  case (Z_lt_le_dec a b); intro; [|rewrite Numof_empty, Numof_empty; omega].
  pattern b.
  apply Zlt_lower_bound_ind with (z := a); auto with zarith; intros.
  case (Z.eq_dec a x); intro eq.
  rewrite eq; rewrite Numof_empty, Numof_empty; omega.
  rewrite Numof_append with (b := (x-1)%Z) by omega.
  rewrite Numof_append with (p := p2) (b := (x-1)%Z) by omega.
  apply Z.add_le_mono.
  apply H; auto with zarith.
  rewrite numof_pred, numof_pred.
  case (Bool.bool_dec (p1 (x - 1)%Z) true); intro e.
  rewrite e, H1; auto with zarith.
  apply Bool.not_true_is_false in e; rewrite e.
  case (p2 (x -1 )%Z); easy.
Qed.

(* Why3 goal *)
Lemma numof_change_some : forall (p1:(Z -> bool)) (p2:(Z -> bool)) (a:Z)
  (b:Z) (i:Z), ((a <= i)%Z /\ (i < b)%Z) -> ((forall (j:Z), ((a <= j)%Z /\
  (j < b)%Z) -> (((p1 j) = true) -> ((p2 j) = true))) -> ((~ ((p1
  i) = true)) -> (((p2 i) = true) -> ((numof p1 a b) < (numof p2 a b))%Z))).
  intros p1 p2 a b i (h1,h2) h3 h4 h5.
  generalize (Z_le_lt_eq_dec _ _ (numof_change_any p1 p2 a b h3)).
  intro H; destruct H; trivial.
  cut False; auto with zarith.
  rewrite Numof_append with (b := i) in e by omega.
  rewrite Numof_append with (p := p2) (b := i) in e by omega.
  rewrite (Numof_left_add _ _ _ h2 h5), (Numof_left_no_add _ _ _ h2 h4) in e.
  assert (forall j : int, (a <= j < i)%Z -> p1 j = true -> p2 j = true) by auto with zarith.
  generalize (numof_change_any p1 p2 _ _ H).
  assert (forall j : int, ((i + 1) <= j < b)%Z -> p1 j = true -> p2 j = true) by auto with zarith.
  generalize (numof_change_any p1 p2 _ _ H0).
  omega.
Qed.

Lemma le_ge_eq: forall a b, (a <= b)%Z /\ (b <= a)%Z -> (a = b)%Z.
  auto with zarith.
Qed.

(* Why3 goal *)
Lemma numof_change_equiv : forall (p1:(Z -> bool)) (p2:(Z -> bool)) (a:Z)
  (b:Z), (forall (j:Z), ((a <= j)%Z /\ (j < b)%Z) -> (((p1 j) = true) <->
  ((p2 j) = true))) -> ((numof p2 a b) = (numof p1 a b)).
intros p1 p2 a b h1.
apply le_ge_eq.
split; apply numof_change_any; apply h1.
Qed.

