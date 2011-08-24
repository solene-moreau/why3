(* This file is generated by Why3's Coq driver *)
(* Beware! Only edit allowed sections below    *)
Require Import ZArith.
Require Import Rbase.
Parameter bag : forall (a:Type), Type.

Parameter nb_occ: forall (a:Type), a -> (bag a)  -> Z.

Implicit Arguments nb_occ.

Axiom occ_non_negative : forall (a:Type), forall (b:(bag a)) (x:a),
  (0%Z <= (nb_occ x b))%Z.

Definition eq_bag (a:Type)(a1:(bag a)) (b:(bag a)): Prop := forall (x:a),
  ((nb_occ x a1) = (nb_occ x b)).
Implicit Arguments eq_bag.

Axiom bag_extensionality : forall (a:Type), forall (a1:(bag a)) (b:(bag a)),
  (eq_bag a1 b) -> (a1 = b).

Parameter empty_bag: forall (a:Type),  (bag a).

Set Contextual Implicit.
Implicit Arguments empty_bag.
Unset Contextual Implicit.

Axiom occ_empty : forall (a:Type), forall (x:a), ((nb_occ x (empty_bag:(bag
  a))) = 0%Z).

Axiom is_empty : forall (a:Type), forall (b:(bag a)), (forall (x:a),
  ((nb_occ x b) = 0%Z)) -> (b = (empty_bag:(bag a))).

Parameter singleton: forall (a:Type), a  -> (bag a).

Implicit Arguments singleton.

Axiom occ_singleton_eq : forall (a:Type), forall (x:a) (y:a), (x = y) ->
  ((nb_occ y (singleton x)) = 1%Z).

Axiom occ_singleton_neq : forall (a:Type), forall (x:a) (y:a), (~ (x = y)) ->
  ((nb_occ y (singleton x)) = 0%Z).

Parameter union: forall (a:Type), (bag a) -> (bag a)  -> (bag a).

Implicit Arguments union.

Axiom occ_union : forall (a:Type), forall (x:a) (a1:(bag a)) (b:(bag a)),
  ((nb_occ x (union a1 b)) = ((nb_occ x a1) + (nb_occ x b))%Z).

Axiom Union_comm : forall (a:Type), forall (a1:(bag a)) (b:(bag a)),
  ((union a1 b) = (union b a1)).

Axiom Union_identity : forall (a:Type), forall (a1:(bag a)), ((union a1
  (empty_bag:(bag a))) = a1).

Axiom Union_assoc : forall (a:Type), forall (a1:(bag a)) (b:(bag a)) (c:(bag
  a)), ((union a1 (union b c)) = (union (union a1 b) c)).

Axiom bag_simpl : forall (a:Type), forall (a1:(bag a)) (b:(bag a)) (c:(bag
  a)), ((union a1 b) = (union c b)) -> (a1 = c).

Axiom bag_simpl_left : forall (a:Type), forall (a1:(bag a)) (b:(bag a))
  (c:(bag a)), ((union a1 b) = (union a1 c)) -> (b = c).

Definition add (a:Type)(x:a) (b:(bag a)): (bag a) := (union (singleton x) b).
Implicit Arguments add.

Axiom occ_add_eq : forall (a:Type), forall (b:(bag a)) (x:a) (y:a),
  (x = y) -> ((nb_occ x (add x b)) = ((nb_occ x b) + 1%Z)%Z).

Axiom occ_add_neq : forall (a:Type), forall (b:(bag a)) (x:a) (y:a),
  (~ (x = y)) -> ((nb_occ y (add x b)) = (nb_occ y b)).

Parameter card: forall (a:Type), (bag a)  -> Z.

Implicit Arguments card.

Axiom Card_empty : forall (a:Type), ((card (empty_bag:(bag a))) = 0%Z).

Axiom Card_singleton : forall (a:Type), forall (x:a),
  ((card (singleton x)) = 1%Z).

Axiom Card_union : forall (a:Type), forall (x:(bag a)) (y:(bag a)),
  ((card (union x y)) = ((card x) + (card y))%Z).

Axiom Card_zero_empty : forall (a:Type), forall (x:(bag a)),
  ((card x) = 0%Z) -> (x = (empty_bag:(bag a))).

Axiom Max_is_ge : forall (x:Z) (y:Z), (x <= (Zmax x y))%Z /\
  (y <= (Zmax x y))%Z.

Axiom Max_is_some : forall (x:Z) (y:Z), ((Zmax x y) = x) \/ ((Zmax x y) = y).

Axiom Min_is_le : forall (x:Z) (y:Z), ((Zmin x y) <= x)%Z /\
  ((Zmin x y) <= y)%Z.

Axiom Min_is_some : forall (x:Z) (y:Z), ((Zmin x y) = x) \/ ((Zmin x y) = y).

Axiom Max_x : forall (x:Z) (y:Z), (y <= x)%Z -> ((Zmax x y) = x).

Axiom Max_y : forall (x:Z) (y:Z), (x <= y)%Z -> ((Zmax x y) = y).

Axiom Min_x : forall (x:Z) (y:Z), (x <= y)%Z -> ((Zmin x y) = x).

Axiom Min_y : forall (x:Z) (y:Z), (y <= x)%Z -> ((Zmin x y) = y).

Axiom Max_sym : forall (x:Z) (y:Z), (y <= x)%Z -> ((Zmax x y) = (Zmax y x)).

Axiom Min_sym : forall (x:Z) (y:Z), (y <= x)%Z -> ((Zmin x y) = (Zmin y x)).

Parameter diff: forall (a:Type), (bag a) -> (bag a)  -> (bag a).

Implicit Arguments diff.

Axiom Diff_occ : forall (a:Type), forall (b1:(bag a)) (b2:(bag a)) (x:a),
  ((nb_occ x (diff b1 b2)) = (Zmax 0%Z ((nb_occ x b1) - (nb_occ x b2))%Z)).

(* YOU MAY EDIT THE CONTEXT BELOW *)

(* DO NOT EDIT BELOW *)

Theorem Diff_empty_right : forall (a:Type), forall (b:(bag a)), ((diff b
  (empty_bag:(bag a))) = b).
(* YOU MAY EDIT THE PROOF BELOW *)
intros X b.
apply bag_extensionality.
intro x.
rewrite Diff_occ.
rewrite occ_empty.
generalize (occ_non_negative X b x).
generalize (Zmax_spec 0 (nb_occ x b - 0))%Z.
auto with zarith.
Qed.
(* DO NOT EDIT BELOW *)


