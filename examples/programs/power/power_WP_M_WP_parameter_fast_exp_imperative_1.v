(* This file is generated by Why3's Coq driver *)
(* Beware! Only edit allowed sections below    *)
Require Import ZArith.
Require Import Rbase.
Require Import ZOdiv.
Definition unit  := unit.

Parameter mark : Type.

Parameter at1: forall (a:Type), a -> mark  -> a.

Implicit Arguments at1.

Parameter old: forall (a:Type), a  -> a.

Implicit Arguments old.

Axiom Abs_pos : forall (x:Z), (0%Z <= (Zabs x))%Z.

Axiom Div_mod : forall (x:Z) (y:Z), (~ (y = 0%Z)) ->
  (x = ((y * (ZOdiv x y))%Z + (ZOmod x y))%Z).

Axiom Div_bound : forall (x:Z) (y:Z), ((0%Z <= x)%Z /\ (0%Z <  y)%Z) ->
  ((0%Z <= (ZOdiv x y))%Z /\ ((ZOdiv x y) <= x)%Z).

Axiom Mod_bound : forall (x:Z) (y:Z), (~ (y = 0%Z)) ->
  (((-(Zabs y))%Z <  (ZOmod x y))%Z /\ ((ZOmod x y) <  (Zabs y))%Z).

Axiom Div_sign_pos : forall (x:Z) (y:Z), ((0%Z <= x)%Z /\ (0%Z <  y)%Z) ->
  (0%Z <= (ZOdiv x y))%Z.

Axiom Div_sign_neg : forall (x:Z) (y:Z), ((x <= 0%Z)%Z /\ (0%Z <  y)%Z) ->
  ((ZOdiv x y) <= 0%Z)%Z.

Axiom Mod_sign_pos : forall (x:Z) (y:Z), ((0%Z <= x)%Z /\ ~ (y = 0%Z)) ->
  (0%Z <= (ZOmod x y))%Z.

Axiom Mod_sign_neg : forall (x:Z) (y:Z), ((x <= 0%Z)%Z /\ ~ (y = 0%Z)) ->
  ((ZOmod x y) <= 0%Z)%Z.

Axiom Rounds_toward_zero : forall (x:Z) (y:Z), (~ (y = 0%Z)) ->
  ((Zabs ((ZOdiv x y) * y)%Z) <= (Zabs x))%Z.

Axiom Div_1 : forall (x:Z), ((ZOdiv x 1%Z) = x).

Axiom Mod_1 : forall (x:Z), ((ZOmod x 1%Z) = 0%Z).

Axiom Div_inf : forall (x:Z) (y:Z), ((0%Z <= x)%Z /\ (x <  y)%Z) ->
  ((ZOdiv x y) = 0%Z).

Axiom Mod_inf : forall (x:Z) (y:Z), ((0%Z <= x)%Z /\ (x <  y)%Z) ->
  ((ZOmod x y) = x).

Axiom Div_mult : forall (x:Z) (y:Z) (z:Z), ((0%Z <  x)%Z /\ ((0%Z <= y)%Z /\
  (0%Z <= z)%Z)) -> ((ZOdiv ((x * y)%Z + z)%Z x) = (y + (ZOdiv z x))%Z).

Axiom Mod_mult : forall (x:Z) (y:Z) (z:Z), ((0%Z <  x)%Z /\ ((0%Z <= y)%Z /\
  (0%Z <= z)%Z)) -> ((ZOmod ((x * y)%Z + z)%Z x) = (ZOmod z x)).

Parameter power: Z -> Z  -> Z.


Axiom Power_0 : forall (x:Z), ((power x 0%Z) = 1%Z).

Axiom Power_s : forall (x:Z) (n:Z), (0%Z <  n)%Z -> ((power x
  n) = (x * (power x (n - 1%Z)%Z))%Z).

Axiom Power_1 : forall (x:Z), ((power x 1%Z) = x).

Axiom Power_sum : forall (x:Z) (n:Z) (m:Z), (0%Z <= n)%Z -> ((0%Z <= m)%Z ->
  ((power x (n + m)%Z) = ((power x n) * (power x m))%Z)).

Axiom Power_mult : forall (x:Z) (n:Z) (m:Z), (0%Z <= n)%Z -> ((0%Z <= m)%Z ->
  ((power x (n * m)%Z) = (power (power x n) m))).

Axiom Power_mult2 : forall (x:Z) (y:Z) (n:Z), (0%Z <= n)%Z ->
  ((power (x * y)%Z n) = ((power x n) * (power y n))%Z).

Inductive ref (a:Type) :=
  | mk_ref : a -> ref a.
Implicit Arguments mk_ref.

Definition contents (a:Type)(u:(ref a)): a :=
  match u with
  | mk_ref contents1 => contents1
  end.
Implicit Arguments contents.

Theorem WP_parameter_fast_exp_imperative : forall (x:Z), forall (n:Z),
  (0%Z <= n)%Z -> forall (e:Z), forall (p:Z), forall (r:Z), ((0%Z <= e)%Z /\
  ((r * (power p e))%Z = (power x n))) -> ((0%Z <  e)%Z ->
  ((~ ((ZOmod e 2%Z) = 1%Z)) -> forall (p1:Z), (p1 = (p * p)%Z) ->
  forall (e1:Z), (e1 = (ZOdiv e 2%Z)) -> ((r * (power p1 e1))%Z = (power x
  n)))).
(* YOU MAY EDIT THE PROOF BELOW *)
intuition.
rewrite <- H4.
apply f_equal.
subst.
assert ((e = e/2 + e/2)%Z).
assert (e mod 2 = 0).
assert (0 <= e mod 2)%Z.
apply Mod_sign_pos.
intuition.
assert (-(Zabs 2) < e mod 2 < (Zabs 2)).
apply Mod_bound.
omega.
assert (Zabs 2 = 2).
auto.
rewrite H6 in H5; omega.
assert (e = 2 * (e/2) + e mod 2).
apply Div_mod; omega.
omega.
rewrite Power_mult2.
rewrite H0 at 3.
rewrite Power_sum; omega.
omega.
Qed.
(* DO NOT EDIT BELOW *)


