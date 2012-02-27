(* This file is generated by Why3's Coq driver *)
(* Beware! Only edit allowed sections below    *)
Require Import ZArith.
Require Import Rbase.
Require int.Int.
Definition unit  := unit.

Parameter qtmark : Type.

Parameter at1: forall (a:Type), a -> qtmark -> a.

Implicit Arguments at1.

Parameter old: forall (a:Type), a -> a.

Implicit Arguments old.

Definition implb(x:bool) (y:bool): bool := match (x,
  y) with
  | (true, false) => false
  | (_, _) => true
  end.

Inductive list (a:Type) :=
  | Nil : list a
  | Cons : a -> (list a) -> list a.
Set Contextual Implicit.
Implicit Arguments Nil.
Unset Contextual Implicit.
Implicit Arguments Cons.

Parameter head: forall (a:Type), (list a) -> a.

Implicit Arguments head.

Axiom head_cons : forall (a:Type), forall (x:a) (l:(list a)), ((head (Cons x
  l)) = x).

Parameter tail: forall (a:Type), (list a) -> (list a).

Implicit Arguments tail.

Axiom tail_cons : forall (a:Type), forall (x:a) (l:(list a)), ((tail (Cons x
  l)) = l).

Set Implicit Arguments.
Fixpoint mem (a:Type)(x:a) (l:(list a)) {struct l}: Prop :=
  match l with
  | Nil => False
  | (Cons y r) => (x = y) \/ (mem x r)
  end.
Unset Implicit Arguments.

Definition disjoint (a:Type)(l1:(list a)) (l2:(list a)): Prop :=
  forall (x:a), ~ ((mem x l1) /\ (mem x l2)).
Implicit Arguments disjoint.

Set Implicit Arguments.
Fixpoint no_repet (a:Type)(l:(list a)) {struct l}: Prop :=
  match l with
  | Nil => True
  | (Cons x r) => (~ (mem x r)) /\ (no_repet r)
  end.
Unset Implicit Arguments.

Set Implicit Arguments.
Fixpoint infix_plpl (a:Type)(l1:(list a)) (l2:(list a)) {struct l1}: (list
  a) :=
  match l1 with
  | Nil => l2
  | (Cons x1 r1) => (Cons x1 (infix_plpl r1 l2))
  end.
Unset Implicit Arguments.

Axiom Append_assoc : forall (a:Type), forall (l1:(list a)) (l2:(list a))
  (l3:(list a)), ((infix_plpl l1 (infix_plpl l2
  l3)) = (infix_plpl (infix_plpl l1 l2) l3)).

Axiom Append_l_nil : forall (a:Type), forall (l:(list a)), ((infix_plpl l
  (Nil:(list a))) = l).

Set Implicit Arguments.
Fixpoint length (a:Type)(l:(list a)) {struct l}: Z :=
  match l with
  | Nil => 0%Z
  | (Cons _ r) => (1%Z + (length r))%Z
  end.
Unset Implicit Arguments.

Axiom Length_nonnegative : forall (a:Type), forall (l:(list a)),
  (0%Z <= (length l))%Z.

Axiom Length_nil : forall (a:Type), forall (l:(list a)),
  ((length l) = 0%Z) <-> (l = (Nil:(list a))).

Axiom Append_length : forall (a:Type), forall (l1:(list a)) (l2:(list a)),
  ((length (infix_plpl l1 l2)) = ((length l1) + (length l2))%Z).

Axiom mem_append : forall (a:Type), forall (x:a) (l1:(list a)) (l2:(list a)),
  (mem x (infix_plpl l1 l2)) <-> ((mem x l1) \/ (mem x l2)).

Axiom mem_decomp : forall (a:Type), forall (x:a) (l:(list a)), (mem x l) ->
  exists l1:(list a), exists l2:(list a), (l = (infix_plpl l1 (Cons x l2))).

Set Implicit Arguments.
Fixpoint reverse (a:Type)(l:(list a)) {struct l}: (list a) :=
  match l with
  | Nil => (Nil:(list a))
  | (Cons x r) => (infix_plpl (reverse r) (Cons x (Nil:(list a))))
  end.
Unset Implicit Arguments.

Axiom reverse_append : forall (a:Type), forall (l1:(list a)) (l2:(list a))
  (x:a), ((infix_plpl (reverse (Cons x l1)) l2) = (infix_plpl (reverse l1)
  (Cons x l2))).

Axiom reverse_reverse : forall (a:Type), forall (l:(list a)),
  ((reverse (reverse l)) = l).

Axiom Reverse_length : forall (a:Type), forall (l:(list a)),
  ((length (reverse l)) = (length l)).

Parameter map : forall (a:Type) (b:Type), Type.

Parameter get: forall (a:Type) (b:Type), (map a b) -> a -> b.

Implicit Arguments get.

Parameter set: forall (a:Type) (b:Type), (map a b) -> a -> b -> (map a b).

Implicit Arguments set.

Axiom Select_eq : forall (a:Type) (b:Type), forall (m:(map a b)),
  forall (a1:a) (a2:a), forall (b1:b), (a1 = a2) -> ((get (set m a1 b1)
  a2) = b1).

Axiom Select_neq : forall (a:Type) (b:Type), forall (m:(map a b)),
  forall (a1:a) (a2:a), forall (b1:b), (~ (a1 = a2)) -> ((get (set m a1 b1)
  a2) = (get m a2)).

Parameter const: forall (b:Type) (a:Type), b -> (map a b).

Set Contextual Implicit.
Implicit Arguments const.
Unset Contextual Implicit.

Axiom Const : forall (b:Type) (a:Type), forall (b1:b) (a1:a), ((get (const(
  b1):(map a b)) a1) = b1).

Parameter loc : Type.

Parameter null: loc.


Inductive list_seg : loc -> (map loc loc) -> (list loc) -> loc -> Prop :=
  | list_seg_nil : forall (p:loc) (next:(map loc loc)), (list_seg p next
      (Nil:(list loc)) p)
  | list_seg_cons : forall (p:loc) (q:loc) (next:(map loc loc)) (l:(list
      loc)), ((~ (p = null)) /\ (list_seg (get next p) next l q)) ->
      (list_seg p next (Cons p l) q).

Axiom list_seg_frame : forall (next1:(map loc loc)) (next2:(map loc loc))
  (p:loc) (q:loc) (v:loc) (pM:(list loc)), ((list_seg p next1 pM null) /\
  ((next2 = (set next1 q v)) /\ ~ (mem q pM))) -> (list_seg p next2 pM null).

Axiom list_seg_functional : forall (next:(map loc loc)) (l1:(list loc))
  (l2:(list loc)) (p:loc), ((list_seg p next l1 null) /\ (list_seg p next l2
  null)) -> (l1 = l2).

(* YOU MAY EDIT THE CONTEXT BELOW *)

(* DO NOT EDIT BELOW *)

Theorem list_seg_sublistl : forall (next:(map loc loc)) (l1:(list loc))
  (l2:(list loc)) (p:loc) (q:loc), (list_seg p next (infix_plpl l1 (Cons q
  l2)) null) -> (list_seg q next (Cons q l2) null).
(* YOU MAY EDIT THE PROOF BELOW *)
induction l1.
intros l2 p q h.
simpl in h.
inversion h; subst; auto.
intros l2 p q h.
simpl in h.
inversion h; subst; auto.
apply IHl1 with (p:= (get next a)).
intuition.
Qed.
(* DO NOT EDIT BELOW *)


