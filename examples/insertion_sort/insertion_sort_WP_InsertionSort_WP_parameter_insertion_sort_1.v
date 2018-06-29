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
Definition contents {a:Type} {a_WT:WhyType a} (v:(@ref a a_WT)): a :=
  match v with
  | (mk_ref x) => x
  end.

(* Why3 assumption *)
Inductive array
  (a:Type) {a_WT:WhyType a} :=
  | mk_array : Z -> (@map.Map.map Z _ a a_WT) -> array a.
Axiom array_WhyType : forall (a:Type) {a_WT:WhyType a}, WhyType (array a).
Existing Instance array_WhyType.
Implicit Arguments mk_array [[a] [a_WT]].

(* Why3 assumption *)
Definition elts {a:Type} {a_WT:WhyType a} (v:(@array a a_WT)): (@map.Map.map
  Z _ a a_WT) := match v with
  | (mk_array x x1) => x1
  end.

(* Why3 assumption *)
Definition length {a:Type} {a_WT:WhyType a} (v:(@array a a_WT)): Z :=
  match v with
  | (mk_array x x1) => x
  end.

(* Why3 assumption *)
Definition get {a:Type} {a_WT:WhyType a} (a1:(@array a a_WT)) (i:Z): a :=
  (map.Map.get (elts a1) i).

(* Why3 assumption *)
Definition set {a:Type} {a_WT:WhyType a} (a1:(@array a a_WT)) (i:Z)
  (v:a): (@array a a_WT) := (mk_array (length a1) (map.Map.set (elts a1) i
  v)).

(* Why3 assumption *)
Definition make {a:Type} {a_WT:WhyType a} (n:Z) (v:a): (@array a a_WT) :=
  (mk_array n (map.Map.const v:(@map.Map.map Z _ a a_WT))).

(* Why3 assumption *)
Definition sorted_sub (a:(@map.Map.map Z _ Z _)) (l:Z) (u:Z): Prop :=
  forall (i1:Z) (i2:Z), ((l <= i1)%Z /\ ((i1 <= i2)%Z /\ (i2 < u)%Z)) ->
  ((map.Map.get a i1) <= (map.Map.get a i2))%Z.

(* Why3 assumption *)
Definition sorted_sub1 (a:(@array Z _)) (l:Z) (u:Z): Prop := (sorted_sub
  (elts a) l u).

(* Why3 assumption *)
Definition sorted (a:(@array Z _)): Prop := (sorted_sub (elts a) 0%Z
  (length a)).

(* Why3 assumption *)
Definition map_eq_sub {a:Type} {a_WT:WhyType a} (a1:(@map.Map.map Z _
  a a_WT)) (a2:(@map.Map.map Z _ a a_WT)) (l:Z) (u:Z): Prop := forall (i:Z),
  ((l <= i)%Z /\ (i < u)%Z) -> ((map.Map.get a1 i) = (map.Map.get a2 i)).

(* Why3 assumption *)
Definition array_eq_sub {a:Type} {a_WT:WhyType a} (a1:(@array a a_WT))
  (a2:(@array a a_WT)) (l:Z) (u:Z): Prop := ((length a1) = (length a2)) /\
  (((0%Z <= l)%Z /\ (l <= (length a1))%Z) /\ (((0%Z <= u)%Z /\
  (u <= (length a1))%Z) /\ (map_eq_sub (elts a1) (elts a2) l u))).

(* Why3 assumption *)
Definition array_eq {a:Type} {a_WT:WhyType a} (a1:(@array a a_WT))
  (a2:(@array a a_WT)): Prop := ((length a1) = (length a2)) /\ (map_eq_sub
  (elts a1) (elts a2) 0%Z (length a1)).

(* Why3 assumption *)
Definition exchange {a:Type} {a_WT:WhyType a} (a1:(@array a a_WT))
  (a2:(@array a a_WT)) (i:Z) (j:Z): Prop := ((length a1) = (length a2)) /\
  (map.MapPermut.exchange (elts a1) (elts a2) 0%Z (length a1) i j).

(* Why3 assumption *)
Definition permut {a:Type} {a_WT:WhyType a} (a1:(@array a a_WT)) (a2:(@array
  a a_WT)) (l:Z) (u:Z): Prop := ((length a1) = (length a2)) /\
  (((0%Z <= l)%Z /\ (l <= (length a1))%Z) /\ (((0%Z <= u)%Z /\
  (u <= (length a1))%Z) /\ (map.MapPermut.permut (elts a1) (elts a2) l u))).

(* Why3 assumption *)
Definition permut_sub {a:Type} {a_WT:WhyType a} (a1:(@array a a_WT))
  (a2:(@array a a_WT)) (l:Z) (u:Z): Prop := (map_eq_sub (elts a1) (elts a2)
  0%Z l) /\ ((permut a1 a2 l u) /\ (map_eq_sub (elts a1) (elts a2) u
  (length a1))).

(* Why3 assumption *)
Definition permut_all {a:Type} {a_WT:WhyType a} (a1:(@array a a_WT))
  (a2:(@array a a_WT)): Prop := ((length a1) = (length a2)) /\
  (map.MapPermut.permut (elts a1) (elts a2) 0%Z (length a1)).

Axiom permut_sub_refl : forall {a:Type} {a_WT:WhyType a}, forall (a1:(@array
  a a_WT)) (l:Z) (u:Z), ((0%Z <= l)%Z /\ ((l <= u)%Z /\
  (u <= (length a1))%Z)) -> (permut_sub a1 a1 l u).

Axiom permut_sub_trans : forall {a:Type} {a_WT:WhyType a}, forall (a1:(@array
  a a_WT)) (a2:(@array a a_WT)) (a3:(@array a a_WT)) (l:Z) (u:Z), (permut_sub
  a1 a2 l u) -> ((permut_sub a2 a3 l u) -> (permut_sub a1 a3 l u)).

Axiom exchange_permut_sub : forall {a:Type} {a_WT:WhyType a},
  forall (a1:(@array a a_WT)) (a2:(@array a a_WT)) (i:Z) (j:Z) (l:Z) (u:Z),
  (exchange a1 a2 i j) -> (((l <= i)%Z /\ (i < u)%Z) -> (((l <= j)%Z /\
  (j < u)%Z) -> ((0%Z <= l)%Z -> ((u <= (length a1))%Z -> (permut_sub a1 a2 l
  u))))).

Axiom permut_sub_unmodified : forall {a:Type} {a_WT:WhyType a},
  forall (a1:(@array a a_WT)) (a2:(@array a a_WT)) (l:Z) (u:Z), (permut_sub
  a1 a2 l u) -> forall (i:Z), (((0%Z <= i)%Z /\ (i < l)%Z) \/ ((u <= i)%Z /\
  (i < (length a1))%Z)) -> ((get a2 i) = (get a1 i)).

Axiom permut_sub_weakening : forall {a:Type} {a_WT:WhyType a},
  forall (a1:(@array a a_WT)) (a2:(@array a a_WT)) (l1:Z) (u1:Z) (l2:Z)
  (u2:Z), (permut_sub a1 a2 l1 u1) -> (((0%Z <= l2)%Z /\ (l2 <= l1)%Z) ->
  (((u1 <= u2)%Z /\ (u2 <= (length a1))%Z) -> (permut_sub a1 a2 l2 u2))).

Axiom permut_sub_compose : forall {a:Type} {a_WT:WhyType a},
  forall (a1:(@array a a_WT)) (a2:(@array a a_WT)) (a3:(@array a a_WT))
  (l1:Z) (u1:Z) (l2:Z) (u2:Z), (u1 <= l2)%Z -> ((permut_sub a1 a2 l1 u1) ->
  ((permut_sub a2 a3 l2 u2) -> (permut_sub a1 a3 l1 u2))).

Axiom permut_all_refl : forall {a:Type} {a_WT:WhyType a}, forall (a1:(@array
  a a_WT)), (permut_all a1 a1).

Axiom permut_all_trans : forall {a:Type} {a_WT:WhyType a}, forall (a1:(@array
  a a_WT)) (a2:(@array a a_WT)) (a3:(@array a a_WT)), (permut_all a1 a2) ->
  ((permut_all a2 a3) -> (permut_all a1 a3)).

Axiom exchange_permut_all : forall {a:Type} {a_WT:WhyType a},
  forall (a1:(@array a a_WT)) (a2:(@array a a_WT)) (i:Z) (j:Z), (exchange a1
  a2 i j) -> (permut_all a1 a2).

Axiom array_eq_permut_all : forall {a:Type} {a_WT:WhyType a},
  forall (a1:(@array a a_WT)) (a2:(@array a a_WT)), (array_eq a1 a2) ->
  (permut_all a1 a2).

Axiom permut_sub_permut_all : forall {a:Type} {a_WT:WhyType a},
  forall (a1:(@array a a_WT)) (a2:(@array a a_WT)) (l:Z) (u:Z), (permut_sub
  a1 a2 l u) -> (permut_all a1 a2).

(* Why3 goal *)
Theorem WP_parameter_insertion_sort : forall (a:Z) (a1:(@map.Map.map Z _
  Z _)), let a2 := (mk_array a a1) in ((0%Z <= a)%Z -> let o :=
  (a - 1%Z)%Z in ((1%Z <= o)%Z -> forall (a3:(@map.Map.map Z _ Z _)),
  forall (i:Z), ((1%Z <= i)%Z /\ (i <= o)%Z) -> (((sorted_sub a3 0%Z i) /\
  (permut_all a2 (mk_array a a3))) -> (((0%Z <= a)%Z /\ ((0%Z <= i)%Z /\
  (i < a)%Z)) -> let v := (map.Map.get a3 i) in forall (j:Z)
  (a4:(@map.Map.map Z _ Z _)), (((0%Z <= j)%Z /\ (j <= i)%Z) /\ ((permut_all
  a2 (mk_array a (map.Map.set a4 j v))) /\ ((forall (k1:Z) (k2:Z),
  ((0%Z <= k1)%Z /\ ((k1 <= k2)%Z /\ (k2 <= i)%Z)) -> ((~ (k1 = j)) ->
  ((~ (k2 = j)) -> ((map.Map.get a4 k1) <= (map.Map.get a4 k2))%Z))) /\
  forall (k:Z), (((j + 1%Z)%Z <= k)%Z /\ (k <= i)%Z) -> (v < (map.Map.get a4
  k))%Z))) -> ((0%Z < j)%Z -> let o1 := (j - 1%Z)%Z in (((0%Z <= a)%Z /\
  ((0%Z <= o1)%Z /\ (o1 < a)%Z)) -> ((v < (map.Map.get a4 o1))%Z -> let o2 :=
  (j - 1%Z)%Z in (((0%Z <= o2)%Z /\ (o2 < a)%Z) -> (((0%Z <= j)%Z /\
  (j < a)%Z) -> forall (a5:(@map.Map.map Z _ Z _)), ((0%Z <= a)%Z /\
  (a5 = (map.Map.set a4 j (map.Map.get a4 o2)))) -> ((exchange (mk_array a
  (map.Map.set a4 j v)) (mk_array a (map.Map.set a5 (j - 1%Z)%Z v))
  (j - 1%Z)%Z j) -> forall (j1:Z), (j1 = (j - 1%Z)%Z) -> (permut_all a2
  (mk_array a (map.Map.set a5 j1 v))))))))))))).
(* Why3 intros a a1 a2 h1 o h2 a3 i (h3,h4) (h5,h6) (h7,(h8,h9)) v j a4
        ((h10,h11),(h12,(h13,h14))) h15 o1 (h16,(h17,h18)) h19 o2 (h20,h21)
        (h22,h23) a5 (h24,h25) h26 j1 h27. *)
intros a a1 a2 h1 o h2 a3 i (h3,h4) (h5,h6) (h7,(h8,h9)) v j a4
        ((h10,h11),(h12,(h13,h14))) h15 o1 (h16,(h17,h18)) h19 o2 (h20,h21)
        (h22,h23) a5 (h24,h25) h26 j1 h27.
intuition.
unfold permut_all.
split.
simpl.
auto.
subst a5.
simpl.
apply MapPermut.permut_trans with (elts (set (mk_array a a4) j (Map.get a3 i))); auto.
subst j1.
unfold permut_all in h12.
intuition.
generalize (exchange_permut_all _ _ _ _ h26).
unfold permut_all; simpl; intuition.
subst j1; assumption.
Qed.
