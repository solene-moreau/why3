(* This file is generated by Why3's Coq driver *)
(* Beware! Only edit allowed sections below    *)
Require Import BuiltIn.
Require BuiltIn.
Require int.Int.
Require list.List.
Require list.Length.
Require list.Mem.
Require list.Append.
Require list.NumOcc.
Require list.Permut.

(* Why3 assumption *)
Definition unit := unit.

Axiom qtmark : Type.
Parameter qtmark_WhyType : WhyType qtmark.
Existing Instance qtmark_WhyType.

(* Why3 assumption *)
Inductive t (a:Type) :=
  | mk_t : (list a) -> t a.
Axiom t_WhyType : forall (a:Type) {a_WT:WhyType a}, WhyType (t a).
Existing Instance t_WhyType.
Implicit Arguments mk_t [[a]].

(* Why3 assumption *)
Definition elts {a:Type} {a_WT:WhyType a} (v:(t a)): (list a) :=
  match v with
  | (mk_t x) => x
  end.

(* Why3 assumption *)
Definition length {a:Type} {a_WT:WhyType a} (q:(t a)): Z :=
  (list.Length.length (elts q)).

Axiom elt : Type.
Parameter elt_WhyType : WhyType elt.
Existing Instance elt_WhyType.

Parameter le: elt -> elt -> Prop.

Axiom total_preorder1 : forall (x:elt) (y:elt), (le x y) \/ (le y x).

Axiom total_preorder2 : forall (x:elt) (y:elt) (z:elt), (le x y) -> ((le y
  z) -> (le x z)).

(* Why3 assumption *)
Inductive sorted: (list elt) -> Prop :=
  | Sorted_Nil : (sorted Init.Datatypes.nil)
  | Sorted_One : forall (x:elt), (sorted
      (Init.Datatypes.cons x Init.Datatypes.nil))
  | Sorted_Two : forall (x:elt) (y:elt) (l:(list elt)), (le x y) -> ((sorted
      (Init.Datatypes.cons y l)) -> (sorted
      (Init.Datatypes.cons x (Init.Datatypes.cons y l)))).

Axiom sorted_mem : forall (x:elt) (l:(list elt)), ((forall (y:elt),
  (list.Mem.mem y l) -> (le x y)) /\ (sorted l)) <-> (sorted
  (Init.Datatypes.cons x l)).

Import Permut.

(* Why3 goal *)
Theorem WP_parameter_merge : forall (q1:(list elt)) (q2:(list elt))
  (q:(list elt)), (q = Init.Datatypes.nil) -> forall (q3:(list elt))
  (q21:(list elt)) (q11:(list elt)), (list.Permut.permut
  (Init.Datatypes.app (Init.Datatypes.app q3 q11) q21)
  (Init.Datatypes.app q1 q2)) -> ((0%Z < (list.Length.length q11))%Z ->
  ((~ ((list.Length.length q11) = 0%Z)) ->
  ((~ ((list.Length.length q21) = 0%Z)) -> ((~ (q11 = Init.Datatypes.nil)) ->
  forall (x1:elt),
  match q11 with
  | Init.Datatypes.nil => False
  | (Init.Datatypes.cons x _) => (x1 = x)
  end -> ((~ (q21 = Init.Datatypes.nil)) -> forall (x2:elt),
  match q21 with
  | Init.Datatypes.nil => False
  | (Init.Datatypes.cons x _) => (x2 = x)
  end -> ((~ (le x1 x2)) -> ((~ (q21 = Init.Datatypes.nil)) ->
  forall (q22:(list elt)), forall (o:elt),
  match q21 with
  | Init.Datatypes.nil => False
  | (Init.Datatypes.cons x t1) => (o = x) /\ (q22 = t1)
  end -> forall (q4:(list elt)),
  (q4 = (Init.Datatypes.app q3 (Init.Datatypes.cons o Init.Datatypes.nil))) ->
  (list.Permut.permut (Init.Datatypes.app (Init.Datatypes.app q4 q11) q22)
  (Init.Datatypes.app q1 q2))))))))).
(* Why3 intros q1 q2 q h1 q3 q21 q11 h2 h3 h4 h5 h6 x1 h7 h8 x2 h9 h10 h11
        q22 o h12 q4 h13. *)
Proof.
intros q q2 q1 h1 q3 q21 q11 h2 h3 h4 h5 h6 x1 h7 x2 h8 h9 q22 o h10
        q4 h11.
destruct q21.
elim h9.
intuition; subst.
apply Permut_trans with (app (app q3 q11) (cons e q21)); auto.
repeat rewrite <- Append.Append_assoc.
eapply Permut_append; auto.
apply Permut_refl.
simpl.
apply (Permut_cons_append e).
Qed.

