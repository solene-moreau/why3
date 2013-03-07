(* This file is generated by Why3's Coq 8.4 driver *)
(* Beware! Only edit allowed sections below    *)
Require Import BuiltIn.
Require BuiltIn.
Require int.Int.
Require map.Map.
Require map.MapPermut.

(* Why3 assumption *)
Definition unit := unit.

(* Why3 assumption *)
Inductive ref (a:Type) {a_WT:WhyType a} :=
  | mk_ref : a -> ref a.
Axiom ref_WhyType : forall (a:Type) {a_WT:WhyType a}, WhyType (ref a).
Existing Instance ref_WhyType.
Implicit Arguments mk_ref [[a] [a_WT]].

(* Why3 assumption *)
Definition contents {a:Type} {a_WT:WhyType a} (v:(ref a)): a :=
  match v with
  | (mk_ref x) => x
  end.

(* Why3 assumption *)
Inductive array
  (a:Type) {a_WT:WhyType a} :=
  | mk_array : Z -> (map.Map.map Z a) -> array a.
Axiom array_WhyType : forall (a:Type) {a_WT:WhyType a}, WhyType (array a).
Existing Instance array_WhyType.
Implicit Arguments mk_array [[a] [a_WT]].

(* Why3 assumption *)
Definition elts {a:Type} {a_WT:WhyType a} (v:(array a)): (map.Map.map Z a) :=
  match v with
  | (mk_array x x1) => x1
  end.

(* Why3 assumption *)
Definition length {a:Type} {a_WT:WhyType a} (v:(array a)): Z :=
  match v with
  | (mk_array x x1) => x
  end.

(* Why3 assumption *)
Definition get {a:Type} {a_WT:WhyType a} (a1:(array a)) (i:Z): a :=
  (map.Map.get (elts a1) i).

(* Why3 assumption *)
Definition set {a:Type} {a_WT:WhyType a} (a1:(array a)) (i:Z) (v:a): (array
  a) := (mk_array (length a1) (map.Map.set (elts a1) i v)).

(* Why3 assumption *)
Definition make {a:Type} {a_WT:WhyType a} (n:Z) (v:a): (array a) :=
  (mk_array n (map.Map.const v:(map.Map.map Z a))).

(* Why3 assumption *)
Definition exchange {a:Type} {a_WT:WhyType a} (a1:(array a)) (a2:(array a))
  (i:Z) (j:Z): Prop := (map.MapPermut.exchange (elts a1) (elts a2) i j).

(* Why3 assumption *)
Definition permut_sub {a:Type} {a_WT:WhyType a} (a1:(array a)) (a2:(array a))
  (l:Z) (u:Z): Prop := (map.MapPermut.permut_sub (elts a1) (elts a2) l u).

(* Why3 assumption *)
Definition permut {a:Type} {a_WT:WhyType a} (a1:(array a)) (a2:(array
  a)): Prop := ((length a1) = (length a2)) /\ (map.MapPermut.permut_sub
  (elts a1) (elts a2) 0%Z (length a1)).

Axiom exchange_permut : forall {a:Type} {a_WT:WhyType a}, forall (a1:(array
  a)) (a2:(array a)) (i:Z) (j:Z), (exchange a1 a2 i j) ->
  (((length a1) = (length a2)) -> (((0%Z <= i)%Z /\ (i < (length a1))%Z) ->
  (((0%Z <= j)%Z /\ (j < (length a1))%Z) -> (permut a1 a2)))).

Axiom permut_sym : forall {a:Type} {a_WT:WhyType a}, forall (a1:(array a))
  (a2:(array a)), (permut a1 a2) -> (permut a2 a1).

Axiom permut_trans : forall {a:Type} {a_WT:WhyType a}, forall (a1:(array a))
  (a2:(array a)) (a3:(array a)), (permut a1 a2) -> ((permut a2 a3) -> (permut
  a1 a3)).

(* Why3 assumption *)
Definition map_eq_sub {a:Type} {a_WT:WhyType a} (a1:(map.Map.map Z a))
  (a2:(map.Map.map Z a)) (l:Z) (u:Z): Prop := forall (i:Z), ((l <= i)%Z /\
  (i < u)%Z) -> ((map.Map.get a1 i) = (map.Map.get a2 i)).

(* Why3 assumption *)
Definition array_eq_sub {a:Type} {a_WT:WhyType a} (a1:(array a)) (a2:(array
  a)) (l:Z) (u:Z): Prop := (map_eq_sub (elts a1) (elts a2) l u).

(* Why3 assumption *)
Definition array_eq {a:Type} {a_WT:WhyType a} (a1:(array a)) (a2:(array
  a)): Prop := ((length a1) = (length a2)) /\ (array_eq_sub a1 a2 0%Z
  (length a1)).

Axiom array_eq_sub_permut : forall {a:Type} {a_WT:WhyType a},
  forall (a1:(array a)) (a2:(array a)) (l:Z) (u:Z), (array_eq_sub a1 a2 l
  u) -> (permut_sub a1 a2 l u).

Axiom array_eq_permut : forall {a:Type} {a_WT:WhyType a}, forall (a1:(array
  a)) (a2:(array a)), (array_eq a1 a2) -> (permut a1 a2).

Axiom elt : Type.
Parameter elt_WhyType : WhyType elt.
Existing Instance elt_WhyType.

Parameter le: elt -> elt -> Prop.

(* Why3 assumption *)
Definition sorted_sub (a:(map.Map.map Z elt)) (l:Z) (u:Z): Prop :=
  forall (i1:Z) (i2:Z), (((l <= i1)%Z /\ (i1 <= i2)%Z) /\ (i2 < u)%Z) -> (le
  (map.Map.get a i1) (map.Map.get a i2)).

Axiom le_refl : forall (x:elt), (le x x).

Axiom le_asym : forall (x:elt) (y:elt), (~ (le x y)) -> (le y x).

Axiom le_trans : forall (x:elt) (y:elt) (z:elt), ((le x y) /\ (le y z)) ->
  (le x z).

(* Why3 assumption *)
Definition sorted_sub1 (a:(array elt)) (l:Z) (u:Z): Prop := (sorted_sub
  (elts a) l u).

(* Why3 assumption *)
Definition sorted (a:(array elt)): Prop := (sorted_sub (elts a) 0%Z
  (length a)).

Import MapPermut.

Require Import Why3.
Ltac ae := why3 "alt-ergo" timelimit 3.

(* Why3 goal *)
Theorem WP_parameter_insertion_sort : forall (a:Z), forall (a1:(map.Map.map Z
  elt)), let a2 := (mk_array a a1) in ((0%Z <= a)%Z ->
  ((1%Z <= (a - 1%Z)%Z)%Z -> forall (a3:(map.Map.map Z elt)), forall (i:Z),
  ((1%Z <= i)%Z /\ (i <= (a - 1%Z)%Z)%Z) -> (((sorted_sub a3 0%Z i) /\
  (permut a2 (mk_array a a3))) -> (((0%Z <= a)%Z /\ ((0%Z <= i)%Z /\
  (i < a)%Z)) -> let v := (map.Map.get a3 i) in forall (j:Z) (a4:(map.Map.map
  Z elt)), (((((0%Z <= j)%Z /\ (j <= i)%Z) /\ (permut a2 (mk_array a
  (map.Map.set a4 j v)))) /\ forall (k1:Z) (k2:Z), (((0%Z <= k1)%Z /\
  (k1 <= k2)%Z) /\ (k2 <= i)%Z) -> ((~ (k1 = j)) -> ((~ (k2 = j)) -> (le
  (map.Map.get a4 k1) (map.Map.get a4 k2))))) /\ forall (k:Z),
  (((j + 1%Z)%Z <= k)%Z /\ (k <= i)%Z) -> (le v (map.Map.get a4 k))) ->
  ((0%Z < j)%Z -> (((0%Z <= a)%Z /\ ((0%Z <= (j - 1%Z)%Z)%Z /\
  ((j - 1%Z)%Z < a)%Z)) -> ((~ (le (map.Map.get a4 (j - 1%Z)%Z) v)) ->
  (((0%Z <= (j - 1%Z)%Z)%Z /\ ((j - 1%Z)%Z < a)%Z) -> (((0%Z <= j)%Z /\
  (j < a)%Z) -> forall (a5:(map.Map.map Z elt)), ((0%Z <= a)%Z /\
  (a5 = (map.Map.set a4 j (map.Map.get a4 (j - 1%Z)%Z)))) ->
  ((map.MapPermut.exchange (map.Map.set a4 j v) (map.Map.set a5 (j - 1%Z)%Z
  v) (j - 1%Z)%Z j) -> forall (j1:Z), (j1 = (j - 1%Z)%Z) -> (permut a2
  (mk_array a (map.Map.set a5 j1 v))))))))))))).
(* intros a a1 a2 h1 h2 a3 i (h3,h4) (h5,h6) (h7,(h8,h9)) v j a4
   ((((h10,h11),h12),h13),h14) h15 (h16,(h17,h18)) h19 (h20,h21) (h22,h23) a5
   (h24,h25) h26 j1 h27. *)
intros a a1 a2 h1 _ a3 i (h2,h3) (h4,h5) (h6,h7) v j a4
((((h8,h9),h10),h11),h12) h13 (h14,h15) h16 (h17,h18) (h19,h20) a5 h21 h22 j1
h23.
unfold permut in *.
simpl; split; auto.
simpl in h10.
destruct h10 as (h10a & h10b).
apply permut_trans with (1:=h10b).
ae.
Qed.


