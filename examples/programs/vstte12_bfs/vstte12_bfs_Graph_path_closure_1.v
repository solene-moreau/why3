(* This file is generated by Why3's Coq driver *)
(* Beware! Only edit allowed sections below    *)
Require Import ZArith.
Require Import Rbase.
Require int.Int.
Parameter set : forall (a:Type), Type.

Parameter mem: forall (a:Type), a -> (set a) -> Prop.

Implicit Arguments mem.

Definition infix_eqeq (a:Type)(s1:(set a)) (s2:(set a)): Prop :=
  forall (x:a), (mem x s1) <-> (mem x s2).
Implicit Arguments infix_eqeq.

Axiom extensionality : forall (a:Type), forall (s1:(set a)) (s2:(set a)),
  (infix_eqeq s1 s2) -> (s1 = s2).

Definition subset (a:Type)(s1:(set a)) (s2:(set a)): Prop := forall (x:a),
  (mem x s1) -> (mem x s2).
Implicit Arguments subset.

Axiom subset_trans : forall (a:Type), forall (s1:(set a)) (s2:(set a))
  (s3:(set a)), (subset s1 s2) -> ((subset s2 s3) -> (subset s1 s3)).

Parameter empty: forall (a:Type), (set a).

Set Contextual Implicit.
Implicit Arguments empty.
Unset Contextual Implicit.

Definition is_empty (a:Type)(s:(set a)): Prop := forall (x:a), ~ (mem x s).
Implicit Arguments is_empty.

Axiom empty_def1 : forall (a:Type), (is_empty (empty:(set a))).

Parameter add: forall (a:Type), a -> (set a) -> (set a).

Implicit Arguments add.

Axiom add_def1 : forall (a:Type), forall (x:a) (y:a), forall (s:(set a)),
  (mem x (add y s)) <-> ((x = y) \/ (mem x s)).

Parameter remove: forall (a:Type), a -> (set a) -> (set a).

Implicit Arguments remove.

Axiom remove_def1 : forall (a:Type), forall (x:a) (y:a) (s:(set a)), (mem x
  (remove y s)) <-> ((~ (x = y)) /\ (mem x s)).

Axiom subset_remove : forall (a:Type), forall (x:a) (s:(set a)),
  (subset (remove x s) s).

Parameter union: forall (a:Type), (set a) -> (set a) -> (set a).

Implicit Arguments union.

Axiom union_def1 : forall (a:Type), forall (s1:(set a)) (s2:(set a)) (x:a),
  (mem x (union s1 s2)) <-> ((mem x s1) \/ (mem x s2)).

Parameter inter: forall (a:Type), (set a) -> (set a) -> (set a).

Implicit Arguments inter.

Axiom inter_def1 : forall (a:Type), forall (s1:(set a)) (s2:(set a)) (x:a),
  (mem x (inter s1 s2)) <-> ((mem x s1) /\ (mem x s2)).

Parameter diff: forall (a:Type), (set a) -> (set a) -> (set a).

Implicit Arguments diff.

Axiom diff_def1 : forall (a:Type), forall (s1:(set a)) (s2:(set a)) (x:a),
  (mem x (diff s1 s2)) <-> ((mem x s1) /\ ~ (mem x s2)).

Axiom subset_diff : forall (a:Type), forall (s1:(set a)) (s2:(set a)),
  (subset (diff s1 s2) s1).

Parameter cardinal: forall (a:Type), (set a) -> Z.

Implicit Arguments cardinal.

Axiom cardinal_nonneg : forall (a:Type), forall (s:(set a)),
  (0%Z <= (cardinal s))%Z.

Axiom cardinal_empty : forall (a:Type), forall (s:(set a)),
  ((cardinal s) = 0%Z) <-> (is_empty s).

Axiom cardinal_add : forall (a:Type), forall (x:a), forall (s:(set a)),
  (~ (mem x s)) -> ((cardinal (add x s)) = (1%Z + (cardinal s))%Z).

Axiom cardinal_remove : forall (a:Type), forall (x:a), forall (s:(set a)),
  (mem x s) -> ((cardinal s) = (1%Z + (cardinal (remove x s)))%Z).

Axiom cardinal_subset : forall (a:Type), forall (s1:(set a)) (s2:(set a)),
  (subset s1 s2) -> ((cardinal s1) <= (cardinal s2))%Z.

Parameter vertex : Type.

Parameter succ: vertex -> (set vertex).


Inductive path : vertex -> vertex -> Z -> Prop :=
  | path_empty : forall (v:vertex), (path v v 0%Z)
  | path_succ : forall (v1:vertex) (v2:vertex) (v3:vertex) (n:Z), (path v1 v2
      n) -> ((mem v3 (succ v2)) -> (path v1 v3 (n + 1%Z)%Z)).

Axiom path_nonneg : forall (v1:vertex) (v2:vertex) (n:Z), (path v1 v2 n) ->
  (0%Z <= n)%Z.

Axiom path_inversion : forall (v1:vertex) (v3:vertex) (n:Z), (0%Z <= n)%Z ->
  ((path v1 v3 (n + 1%Z)%Z) -> exists v2:vertex, (path v1 v2 n) /\ (mem v3
  (succ v2))).

(* YOU MAY EDIT THE CONTEXT BELOW *)

(* DO NOT EDIT BELOW *)

Theorem path_closure : forall (s:(set vertex)), (forall (x:vertex), (mem x
  s) -> forall (y:vertex), (mem y (succ x)) -> (mem y s)) ->
  forall (v1:vertex) (v2:vertex) (n:Z), (path v1 v2 n) -> ((mem v1 s) ->
  (mem v2 s)).
(* YOU MAY EDIT THE PROOF BELOW *)
induction 2; auto.
intuition.
eauto.
Qed.
(* DO NOT EDIT BELOW *)


