(* This file is generated by Why3's Coq driver *)
(* Beware! Only edit allowed sections below    *)
Require Import ZArith.
Require Import Rbase.
Require Import ZOdiv.
Parameter bag : forall (a:Type), Type.

Parameter nb_occ: forall (a:Type), a -> (bag a) -> Z.

Implicit Arguments nb_occ.

Axiom occ_non_negative : forall (a:Type), forall (b:(bag a)) (x:a),
  (0%Z <= (nb_occ x b))%Z.

Definition eq_bag (a:Type)(a1:(bag a)) (b:(bag a)): Prop := forall (x:a),
  ((nb_occ x a1) = (nb_occ x b)).
Implicit Arguments eq_bag.

Axiom bag_extensionality : forall (a:Type), forall (a1:(bag a)) (b:(bag a)),
  (eq_bag a1 b) -> (a1 = b).

Parameter empty_bag: forall (a:Type), (bag a).

Set Contextual Implicit.
Implicit Arguments empty_bag.
Unset Contextual Implicit.

Axiom occ_empty : forall (a:Type), forall (x:a), ((nb_occ x (empty_bag:(bag
  a))) = 0%Z).

Axiom is_empty : forall (a:Type), forall (b:(bag a)), (forall (x:a),
  ((nb_occ x b) = 0%Z)) -> (b = (empty_bag:(bag a))).

Parameter singleton: forall (a:Type), a -> (bag a).

Implicit Arguments singleton.

Axiom occ_singleton : forall (a:Type), forall (x:a) (y:a), ((x = y) /\
  ((nb_occ y (singleton x)) = 1%Z)) \/ ((~ (x = y)) /\ ((nb_occ y
  (singleton x)) = 0%Z)).

Axiom occ_singleton_eq : forall (a:Type), forall (x:a) (y:a), (x = y) ->
  ((nb_occ y (singleton x)) = 1%Z).

Axiom occ_singleton_neq : forall (a:Type), forall (x:a) (y:a), (~ (x = y)) ->
  ((nb_occ y (singleton x)) = 0%Z).

Parameter union: forall (a:Type), (bag a) -> (bag a) -> (bag a).

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

Parameter card: forall (a:Type), (bag a) -> Z.

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

Parameter diff: forall (a:Type), (bag a) -> (bag a) -> (bag a).

Implicit Arguments diff.

Axiom Diff_occ : forall (a:Type), forall (b1:(bag a)) (b2:(bag a)) (x:a),
  ((nb_occ x (diff b1 b2)) = (Zmax 0%Z ((nb_occ x b1) - (nb_occ x b2))%Z)).

Axiom Diff_empty_right : forall (a:Type), forall (b:(bag a)), ((diff b
  (empty_bag:(bag a))) = b).

Axiom Diff_empty_left : forall (a:Type), forall (b:(bag a)),
  ((diff (empty_bag:(bag a)) b) = (empty_bag:(bag a))).

Axiom Diff_add : forall (a:Type), forall (b:(bag a)) (x:a), ((diff (add x b)
  (singleton x)) = b).

Axiom Diff_comm : forall (a:Type), forall (b:(bag a)) (b1:(bag a)) (b2:(bag
  a)), ((diff (diff b b1) b2) = (diff (diff b b2) b1)).

Axiom Add_diff : forall (a:Type), forall (b:(bag a)) (x:a), (0%Z <  (nb_occ x
  b))%Z -> ((add x (diff b (singleton x))) = b).

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

Definition array (a:Type) := (map Z a).

Parameter elements: forall (a:Type), (map Z a) -> Z -> Z -> (bag a).

Implicit Arguments elements.

Axiom Elements_empty : forall (a:Type), forall (a1:(map Z a)) (i:Z) (j:Z),
  (j <= i)%Z -> ((elements a1 i j) = (empty_bag:(bag a))).

Axiom Elements_add : forall (a:Type), forall (a1:(map Z a)) (i:Z) (j:Z),
  (i <  j)%Z -> ((elements a1 i j) = (add (get a1 (j - 1%Z)%Z) (elements a1 i
  (j - 1%Z)%Z))).

Axiom Elements_singleton : forall (a:Type), forall (a1:(map Z a)) (i:Z)
  (j:Z), (j = (i + 1%Z)%Z) -> ((elements a1 i j) = (singleton (get a1 i))).

Axiom Elements_union : forall (a:Type), forall (a1:(map Z a)) (i:Z) (j:Z)
  (k:Z), ((i <= j)%Z /\ (j <= k)%Z) -> ((elements a1 i
  k) = (union (elements a1 i j) (elements a1 j k))).

Axiom Elements_add1 : forall (a:Type), forall (a1:(map Z a)) (i:Z) (j:Z),
  (i <  j)%Z -> ((elements a1 i j) = (add (get a1 i) (elements a1 (i + 1%Z)%Z
  j))).

Axiom Elements_remove_last : forall (a:Type), forall (a1:(map Z a)) (i:Z)
  (j:Z), (i <  (j - 1%Z)%Z)%Z -> ((elements a1 i
  (j - 1%Z)%Z) = (diff (elements a1 i j) (singleton (get a1 (j - 1%Z)%Z)))).

Axiom Occ_elements : forall (a:Type), forall (a1:(map Z a)) (i:Z) (j:Z)
  (n:Z), ((i <= j)%Z /\ (j <  n)%Z) -> (0%Z <  (nb_occ (get a1 j)
  (elements a1 i n)))%Z.

Axiom Elements_set_outside : forall (a:Type), forall (a1:(map Z a)) (i:Z)
  (j:Z), (i <= j)%Z -> forall (k:Z), ((k <  i)%Z \/ (j <= k)%Z) ->
  forall (e:a), ((elements (set a1 k e) i j) = (elements a1 i j)).

Axiom Elements_set_inside : forall (a:Type), forall (a1:(map Z a)) (i:Z)
  (j:Z) (n:Z) (e:a) (b:(bag a)), ((i <= j)%Z /\ (j <  n)%Z) -> (((elements a1
  i n) = (add (get a1 j) b)) -> ((elements (set a1 j e) i n) = (add e b))).

Axiom Elements_set_inside2 : forall (a:Type), forall (a1:(map Z a)) (i:Z)
  (j:Z) (n:Z) (e:a), ((i <= j)%Z /\ (j <  n)%Z) -> ((elements (set a1 j e) i
  n) = (add e (diff (elements a1 i n) (singleton (get a1 j))))).

Axiom Abs_le : forall (x:Z) (y:Z), ((Zabs x) <= y)%Z <-> (((-y)%Z <= x)%Z /\
  (x <= y)%Z).

Definition left1(i:Z): Z := ((2%Z * i)%Z + 1%Z)%Z.

Definition right1(i:Z): Z := ((2%Z * i)%Z + 2%Z)%Z.

Definition parent(i:Z): Z := (ZOdiv (i - 1%Z)%Z 2%Z).

Axiom Parent_inf : forall (i:Z), (0%Z <  i)%Z -> ((parent i) <  i)%Z.

Axiom Left_sup : forall (i:Z), (0%Z <= i)%Z -> (i <  (left1 i))%Z.

Axiom Right_sup : forall (i:Z), (0%Z <= i)%Z -> (i <  (right1 i))%Z.

Axiom Parent_right : forall (i:Z), (0%Z <= i)%Z -> ((parent (right1 i)) = i).

Axiom Parent_left : forall (i:Z), (0%Z <= i)%Z -> ((parent (left1 i)) = i).

Axiom Inf_parent : forall (i:Z) (j:Z), ((0%Z <  j)%Z /\
  (j <= (right1 i))%Z) -> ((parent j) <= i)%Z.

Axiom Child_parent : forall (i:Z), (0%Z <  i)%Z ->
  ((i = (left1 (parent i))) \/ (i = (right1 (parent i)))).

Axiom Parent_pos : forall (j:Z), (0%Z <  j)%Z -> (0%Z <= (parent j))%Z.

Definition parentChild(i:Z) (j:Z): Prop := ((0%Z <= i)%Z /\ (i <  j)%Z) ->
  ((j = (left1 i)) \/ (j = (right1 i))).

Definition map1  := (map Z Z).

Definition logic_heap  := ((map Z Z)* Z)%type.

Definition is_heap_array(a:(map Z Z)) (idx:Z) (sz:Z): Prop :=
  (0%Z <= idx)%Z -> forall (i:Z) (j:Z), (((idx <= i)%Z /\ (i <  j)%Z) /\
  (j <  sz)%Z) -> ((parentChild i j) -> ((get a i) <= (get a j))%Z).

Definition is_heap(h:((map Z Z)* Z)%type): Prop :=
  match h with
  | (a, sz) => (0%Z <= sz)%Z /\ (is_heap_array a 0%Z sz)
  end.

Axiom Is_heap_when_no_element : forall (a:(map Z Z)) (idx:Z) (n:Z),
  ((0%Z <= n)%Z /\ (n <= idx)%Z) -> (is_heap_array a idx n).

Axiom Is_heap_sub : forall (a:(map Z Z)) (i:Z) (n:Z), (is_heap_array a i
  n) -> forall (j:Z), ((i <= j)%Z /\ (j <= n)%Z) -> (is_heap_array a i j).

Axiom Is_heap_sub2 : forall (a:(map Z Z)) (n:Z), (is_heap_array a 0%Z n) ->
  forall (j:Z), ((0%Z <= j)%Z /\ (j <= n)%Z) -> (is_heap_array a j n).

Axiom Is_heap_when_node_modified : forall (a:(map Z Z)) (n:Z) (e:Z) (idx:Z)
  (i:Z), ((0%Z <= i)%Z /\ (i <  n)%Z) -> ((is_heap_array a idx n) ->
  (((0%Z <  i)%Z -> ((get a (parent i)) <= e)%Z) -> ((((left1 i) <  n)%Z ->
  (e <= (get a (left1 i)))%Z) -> ((((right1 i) <  n)%Z -> (e <= (get a
  (right1 i)))%Z) -> (is_heap_array (set a i e) idx n))))).

Axiom Is_heap_add_last : forall (a:(map Z Z)) (n:Z) (e:Z), (0%Z <  n)%Z ->
  (((is_heap_array a 0%Z n) /\ ((get a (parent n)) <= e)%Z) ->
  (is_heap_array (set a n e) 0%Z (n + 1%Z)%Z)).

Axiom Parent_inf_el : forall (a:(map Z Z)) (n:Z), (is_heap_array a 0%Z n) ->
  forall (j:Z), ((0%Z <  j)%Z /\ (j <  n)%Z) -> ((get a (parent j)) <= (get a
  j))%Z.

Axiom Left_sup_el : forall (a:(map Z Z)) (n:Z), (is_heap_array a 0%Z n) ->
  forall (j:Z), ((0%Z <= j)%Z /\ (j <  n)%Z) -> (((left1 j) <  n)%Z ->
  ((get a j) <= (get a (left1 j)))%Z).

Axiom Right_sup_el : forall (a:(map Z Z)) (n:Z), (is_heap_array a 0%Z n) ->
  forall (j:Z), ((0%Z <= j)%Z /\ (j <  n)%Z) -> (((right1 j) <  n)%Z ->
  ((get a j) <= (get a (right1 j)))%Z).

Axiom Is_heap_relation : forall (a:(map Z Z)) (n:Z), (0%Z <  n)%Z ->
  ((is_heap_array a 0%Z n) -> forall (j:Z), (0%Z <= j)%Z -> ((j <  n)%Z ->
  ((get a 0%Z) <= (get a j))%Z)).

Definition model(h:((map Z Z)* Z)%type): (bag Z) :=
  match h with
  | (a, n) => (elements a 0%Z n)
  end.

Axiom Model_empty : forall (a:(map Z Z)), ((model (a, 0%Z)) = (empty_bag:(bag
  Z))).

Axiom Model_singleton : forall (a:(map Z Z)), ((model (a,
  1%Z)) = (singleton (get a 0%Z))).

(* YOU MAY EDIT THE CONTEXT BELOW *)

(* DO NOT EDIT BELOW *)

Theorem Model_set : forall (a:(map Z Z)) (v:Z) (i:Z) (n:Z), ((0%Z <= i)%Z /\
  (i <  n)%Z) -> ((add (get a i) (model ((set a i v), n))) = (add v (model (
  a, n)))).
(* YOU MAY EDIT THE PROOF BELOW *)
intros a v i n H_is.
unfold model in *.
rewrite Elements_union with (i:= 0) (j:=i) (k:=n); auto with *.
pattern (elements (set a i v) 0 i); rewrite Elements_set_outside; auto with *.
rewrite Elements_add1 with (i:= i) (j:=n); auto with *.
rewrite Select_eq; auto with *.
pattern (elements (set a i v) (i + 1) n); rewrite Elements_set_outside; auto with *.
unfold add.
pattern (union (singleton v) (elements a (i + 1) n)); rewrite Union_comm.
pattern (union (elements a 0 i)
     (union (elements a (i + 1) n) (singleton v)));
  rewrite Union_assoc.
pattern (union (singleton (get a i))
  (union (union (elements a 0 i) (elements a (i + 1) n))
     (singleton v))); 
  rewrite Union_assoc.
pattern  (union (singleton (get a i))
     (union (elements a 0 i) (elements a (i + 1) n))); 
  rewrite Union_assoc.
pattern (union (union (singleton (get a i)) (elements a 0 i))
     (elements a (i + 1) n)); 
     rewrite <- Union_assoc.
pattern (union (elements a 0 i) (elements a (i + 1) n));
 rewrite Union_comm.
pattern (union (singleton (get a i))
     (union (elements a (i + 1) n) (elements a 0 i))); 
  rewrite Union_assoc.
fold (add (get a i) (elements a (i + 1) n)).
pattern (add (get a i) (elements a (i + 1) n)); 
  rewrite <- Elements_add1; auto with *.
pattern (union (elements a i n) (elements a 0 i)); 
  rewrite <- Union_comm.
pattern (union (elements a 0 i) (elements a i n)); rewrite <- Elements_union; auto with *.
rewrite <- Union_comm; auto.
Qed.
(* DO NOT EDIT BELOW *)


