(* This file is generated by Why3's Coq driver *)
(* Beware! Only edit allowed sections below    *)
Require Import BuiltIn.
Require BuiltIn.
Require HighOrd.
Require int.Int.
Require map.Map.
Require bool.Bool.
Require set.Fset.
Require set.SetApp.

(* Why3 assumption *)
Inductive datatype :=
  | Tint : datatype
  | Tbool : datatype.
Axiom datatype_WhyType : WhyType datatype.
Existing Instance datatype_WhyType.

(* Why3 assumption *)
Inductive operator :=
  | Oplus : operator
  | Ominus : operator
  | Omult : operator
  | Ole : operator.
Axiom operator_WhyType : WhyType operator.
Existing Instance operator_WhyType.

(* Why3 assumption *)
Definition ident := Numbers.BinNums.Z.

(* Why3 assumption *)
Inductive term :=
  | Tconst : Numbers.BinNums.Z -> term
  | Tvar : Numbers.BinNums.Z -> term
  | Tderef : Numbers.BinNums.Z -> term
  | Tbin : term -> operator -> term -> term.
Axiom term_WhyType : WhyType term.
Existing Instance term_WhyType.

(* Why3 assumption *)
Inductive fmla :=
  | Fterm : term -> fmla
  | Fand : fmla -> fmla -> fmla
  | Fnot : fmla -> fmla
  | Fimplies : fmla -> fmla -> fmla
  | Flet : Numbers.BinNums.Z -> term -> fmla -> fmla
  | Fforall : Numbers.BinNums.Z -> datatype -> fmla -> fmla.
Axiom fmla_WhyType : WhyType fmla.
Existing Instance fmla_WhyType.

(* Why3 assumption *)
Inductive value :=
  | Vint : Numbers.BinNums.Z -> value
  | Vbool : Init.Datatypes.bool -> value.
Axiom value_WhyType : WhyType value.
Existing Instance value_WhyType.

(* Why3 assumption *)
Definition env := Numbers.BinNums.Z -> value.

Parameter eval_bin: value -> operator -> value -> value.

Axiom eval_bin'def :
  forall (x:value) (op:operator) (y:value),
  match (x, y) with
  | (Vint x1, Vint y1) =>
      match op with
      | Oplus => ((eval_bin x op y) = (Vint (x1 + y1)%Z))
      | Ominus => ((eval_bin x op y) = (Vint (x1 - y1)%Z))
      | Omult => ((eval_bin x op y) = (Vint (x1 * y1)%Z))
      | Ole =>
          ((x1 <= y1)%Z -> ((eval_bin x op y) = (Vbool Init.Datatypes.true))) /\
          (~ (x1 <= y1)%Z ->
           ((eval_bin x op y) = (Vbool Init.Datatypes.false)))
      end
  | (_, _) => ((eval_bin x op y) = (Vbool Init.Datatypes.false))
  end.

(* Why3 assumption *)
Fixpoint eval_term (sigma:Numbers.BinNums.Z -> value)
  (pi:Numbers.BinNums.Z -> value) (t:term) {struct t}: value :=
  match t with
  | Tconst n => Vint n
  | Tvar id => pi id
  | Tderef id => sigma id
  | Tbin t1 op t2 =>
      eval_bin (eval_term sigma pi t1) op (eval_term sigma pi t2)
  end.

(* Why3 assumption *)
Fixpoint eval_fmla (sigma:Numbers.BinNums.Z -> value)
  (pi:Numbers.BinNums.Z -> value) (f:fmla) {struct f}: Prop :=
  match f with
  | Fterm t => ((eval_term sigma pi t) = (Vbool Init.Datatypes.true))
  | Fand f1 f2 => eval_fmla sigma pi f1 /\ eval_fmla sigma pi f2
  | Fnot f1 => ~ eval_fmla sigma pi f1
  | Fimplies f1 f2 => eval_fmla sigma pi f1 -> eval_fmla sigma pi f2
  | Flet x t f1 =>
      eval_fmla sigma (map.Map.set pi x (eval_term sigma pi t)) f1
  | Fforall x Tint f1 =>
      forall (n:Numbers.BinNums.Z),
      eval_fmla sigma (map.Map.set pi x (Vint n)) f1
  | Fforall x Tbool f1 =>
      forall (b:Init.Datatypes.bool),
      eval_fmla sigma (map.Map.set pi x (Vbool b)) f1
  end.

Parameter subst_term: term -> Numbers.BinNums.Z -> Numbers.BinNums.Z -> term.

Axiom subst_term'def :
  forall (e:term) (r:Numbers.BinNums.Z) (v:Numbers.BinNums.Z),
  match e with
  | Tconst _ => ((subst_term e r v) = e)
  | Tvar _ => ((subst_term e r v) = e)
  | Tderef x =>
      ((r = x) -> ((subst_term e r v) = (Tvar v))) /\
      (~ (r = x) -> ((subst_term e r v) = e))
  | Tbin e1 op e2 =>
      ((subst_term e r v) =
       (Tbin (subst_term e1 r v) op (subst_term e2 r v)))
  end.

(* Why3 assumption *)
Fixpoint fresh_in_term (id:Numbers.BinNums.Z) (t:term) {struct t}: Prop :=
  match t with
  | Tconst _ => True
  | Tvar v => ~ (id = v)
  | Tderef _ => True
  | Tbin t1 _ t2 => fresh_in_term id t1 /\ fresh_in_term id t2
  end.

Axiom eval_subst_term :
  forall (sigma:Numbers.BinNums.Z -> value) (pi:Numbers.BinNums.Z -> value)
    (e:term) (x:Numbers.BinNums.Z) (v:Numbers.BinNums.Z),
  fresh_in_term v e ->
  ((eval_term sigma pi (subst_term e x v)) =
   (eval_term (map.Map.set sigma x (pi v)) pi e)).

Axiom eval_term_change_free :
  forall (t:term) (sigma:Numbers.BinNums.Z -> value)
    (pi:Numbers.BinNums.Z -> value) (id:Numbers.BinNums.Z) (v:value),
  fresh_in_term id t ->
  ((eval_term sigma (map.Map.set pi id v) t) = (eval_term sigma pi t)).

(* Why3 assumption *)
Fixpoint fresh_in_fmla (id:Numbers.BinNums.Z) (f:fmla) {struct f}: Prop :=
  match f with
  | Fterm e => fresh_in_term id e
  | (Fand f1 f2)|(Fimplies f1 f2) =>
      fresh_in_fmla id f1 /\ fresh_in_fmla id f2
  | Fnot f1 => fresh_in_fmla id f1
  | Flet y t f1 => ~ (id = y) /\ fresh_in_term id t /\ fresh_in_fmla id f1
  | Fforall y _ f1 => ~ (id = y) /\ fresh_in_fmla id f1
  end.

(* Why3 assumption *)
Fixpoint subst (f:fmla) (x:Numbers.BinNums.Z)
  (v:Numbers.BinNums.Z) {struct f}: fmla :=
  match f with
  | Fterm e => Fterm (subst_term e x v)
  | Fand f1 f2 => Fand (subst f1 x v) (subst f2 x v)
  | Fnot f1 => Fnot (subst f1 x v)
  | Fimplies f1 f2 => Fimplies (subst f1 x v) (subst f2 x v)
  | Flet y t f1 => Flet y (subst_term t x v) (subst f1 x v)
  | Fforall y ty f1 => Fforall y ty (subst f1 x v)
  end.

Axiom eval_subst :
  forall (f:fmla) (sigma:Numbers.BinNums.Z -> value)
    (pi:Numbers.BinNums.Z -> value) (x:Numbers.BinNums.Z)
    (v:Numbers.BinNums.Z),
  fresh_in_fmla v f ->
  eval_fmla sigma pi (subst f x v) <->
  eval_fmla (map.Map.set sigma x (pi v)) pi f.

Axiom eval_swap :
  forall (f:fmla) (sigma:Numbers.BinNums.Z -> value)
    (pi:Numbers.BinNums.Z -> value) (id1:Numbers.BinNums.Z)
    (id2:Numbers.BinNums.Z) (v1:value) (v2:value),
  ~ (id1 = id2) ->
  eval_fmla sigma (map.Map.set (map.Map.set pi id1 v1) id2 v2) f <->
  eval_fmla sigma (map.Map.set (map.Map.set pi id2 v2) id1 v1) f.

Axiom eval_change_free :
  forall (f:fmla) (sigma:Numbers.BinNums.Z -> value)
    (pi:Numbers.BinNums.Z -> value) (id:Numbers.BinNums.Z) (v:value),
  fresh_in_fmla id f ->
  eval_fmla sigma (map.Map.set pi id v) f <-> eval_fmla sigma pi f.

(* Why3 assumption *)
Inductive stmt :=
  | Sskip : stmt
  | Sassign : Numbers.BinNums.Z -> term -> stmt
  | Sseq : stmt -> stmt -> stmt
  | Sif : term -> stmt -> stmt -> stmt
  | Sassert : fmla -> stmt
  | Swhile : term -> fmla -> stmt -> stmt.
Axiom stmt_WhyType : WhyType stmt.
Existing Instance stmt_WhyType.

Axiom check_skip : forall (s:stmt), (s = Sskip) \/ ~ (s = Sskip).

(* Why3 assumption *)
Inductive one_step: (Numbers.BinNums.Z -> value) ->
  (Numbers.BinNums.Z -> value) -> stmt -> (Numbers.BinNums.Z -> value) ->
  (Numbers.BinNums.Z -> value) -> stmt -> Prop :=
  | one_step_assign :
      forall (sigma:Numbers.BinNums.Z -> value)
        (pi:Numbers.BinNums.Z -> value) (x:Numbers.BinNums.Z) (e:term),
      one_step sigma pi (Sassign x e)
      (map.Map.set sigma x (eval_term sigma pi e)) pi Sskip
  | one_step_seq :
      forall (sigma:Numbers.BinNums.Z -> value)
        (pi:Numbers.BinNums.Z -> value) (sigma':Numbers.BinNums.Z -> value)
        (pi':Numbers.BinNums.Z -> value) (i1:stmt) (i1':stmt) (i2:stmt),
      one_step sigma pi i1 sigma' pi' i1' ->
      one_step sigma pi (Sseq i1 i2) sigma' pi' (Sseq i1' i2)
  | one_step_seq_skip :
      forall (sigma:Numbers.BinNums.Z -> value)
        (pi:Numbers.BinNums.Z -> value) (i:stmt),
      one_step sigma pi (Sseq Sskip i) sigma pi i
  | one_step_if_true :
      forall (sigma:Numbers.BinNums.Z -> value)
        (pi:Numbers.BinNums.Z -> value) (e:term) (i1:stmt) (i2:stmt),
      ((eval_term sigma pi e) = (Vbool Init.Datatypes.true)) ->
      one_step sigma pi (Sif e i1 i2) sigma pi i1
  | one_step_if_false :
      forall (sigma:Numbers.BinNums.Z -> value)
        (pi:Numbers.BinNums.Z -> value) (e:term) (i1:stmt) (i2:stmt),
      ((eval_term sigma pi e) = (Vbool Init.Datatypes.false)) ->
      one_step sigma pi (Sif e i1 i2) sigma pi i2
  | one_step_assert :
      forall (sigma:Numbers.BinNums.Z -> value)
        (pi:Numbers.BinNums.Z -> value) (f:fmla),
      eval_fmla sigma pi f -> one_step sigma pi (Sassert f) sigma pi Sskip
  | one_step_while_true :
      forall (sigma:Numbers.BinNums.Z -> value)
        (pi:Numbers.BinNums.Z -> value) (e:term) (inv:fmla) (i:stmt),
      eval_fmla sigma pi inv ->
      ((eval_term sigma pi e) = (Vbool Init.Datatypes.true)) ->
      one_step sigma pi (Swhile e inv i) sigma pi (Sseq i (Swhile e inv i))
  | one_step_while_false :
      forall (sigma:Numbers.BinNums.Z -> value)
        (pi:Numbers.BinNums.Z -> value) (e:term) (inv:fmla) (i:stmt),
      eval_fmla sigma pi inv ->
      ((eval_term sigma pi e) = (Vbool Init.Datatypes.false)) ->
      one_step sigma pi (Swhile e inv i) sigma pi Sskip.

(* Why3 assumption *)
Inductive many_steps: (Numbers.BinNums.Z -> value) ->
  (Numbers.BinNums.Z -> value) -> stmt -> (Numbers.BinNums.Z -> value) ->
  (Numbers.BinNums.Z -> value) -> stmt -> Numbers.BinNums.Z -> Prop :=
  | many_steps_refl :
      forall (sigma:Numbers.BinNums.Z -> value)
        (pi:Numbers.BinNums.Z -> value) (i:stmt),
      many_steps sigma pi i sigma pi i 0%Z
  | many_steps_trans :
      forall (sigma1:Numbers.BinNums.Z -> value)
        (pi1:Numbers.BinNums.Z -> value) (sigma2:Numbers.BinNums.Z -> value)
        (pi2:Numbers.BinNums.Z -> value) (sigma3:Numbers.BinNums.Z -> value)
        (pi3:Numbers.BinNums.Z -> value) (i1:stmt) (i2:stmt) (i3:stmt)
        (n:Numbers.BinNums.Z),
      one_step sigma1 pi1 i1 sigma2 pi2 i2 ->
      many_steps sigma2 pi2 i2 sigma3 pi3 i3 n ->
      many_steps sigma1 pi1 i1 sigma3 pi3 i3 (n + 1%Z)%Z.

Axiom steps_non_neg :
  forall (sigma1:Numbers.BinNums.Z -> value) (pi1:Numbers.BinNums.Z -> value)
    (sigma2:Numbers.BinNums.Z -> value) (pi2:Numbers.BinNums.Z -> value)
    (i1:stmt) (i2:stmt) (n:Numbers.BinNums.Z),
  many_steps sigma1 pi1 i1 sigma2 pi2 i2 n -> (0%Z <= n)%Z.

Axiom many_steps_seq :
  forall (sigma1:Numbers.BinNums.Z -> value) (pi1:Numbers.BinNums.Z -> value)
    (sigma3:Numbers.BinNums.Z -> value) (pi3:Numbers.BinNums.Z -> value)
    (i1:stmt) (i2:stmt) (n:Numbers.BinNums.Z),
  many_steps sigma1 pi1 (Sseq i1 i2) sigma3 pi3 Sskip n ->
  exists sigma2:Numbers.BinNums.Z -> value, exists pi2:
  Numbers.BinNums.Z -> value, exists n1:Numbers.BinNums.Z, exists n2:
  Numbers.BinNums.Z,
  many_steps sigma1 pi1 i1 sigma2 pi2 Sskip n1 /\
  many_steps sigma2 pi2 i2 sigma3 pi3 Sskip n2 /\ (n = ((1%Z + n1)%Z + n2)%Z).

(* Why3 assumption *)
Definition valid_fmla (p:fmla) : Prop :=
  forall (sigma:Numbers.BinNums.Z -> value) (pi:Numbers.BinNums.Z -> value),
  eval_fmla sigma pi p.

(* Why3 assumption *)
Definition valid_triple (p:fmla) (i:stmt) (q:fmla) : Prop :=
  forall (sigma:Numbers.BinNums.Z -> value) (pi:Numbers.BinNums.Z -> value),
  eval_fmla sigma pi p ->
  forall (sigma':Numbers.BinNums.Z -> value) (pi':Numbers.BinNums.Z -> value)
    (n:Numbers.BinNums.Z),
  many_steps sigma pi i sigma' pi' Sskip n -> eval_fmla sigma' pi' q.

Axiom set : Type.
Parameter set_WhyType : WhyType set.
Existing Instance set_WhyType.

Parameter to_fset: set -> set.Fset.fset Numbers.BinNums.Z.

Parameter choose: set -> Numbers.BinNums.Z.

Axiom choose'spec :
  forall (s:set), ~ set.Fset.is_empty (to_fset s) ->
  set.Fset.mem (choose s) (to_fset s).

(* Why3 assumption *)
Definition assigns (sigma:Numbers.BinNums.Z -> value)
    (a:set.Fset.fset Numbers.BinNums.Z) (sigma':Numbers.BinNums.Z -> value) :
    Prop :=
  forall (i:Numbers.BinNums.Z), ~ set.Fset.mem i a ->
  ((sigma i) = (sigma' i)).

Axiom assigns_refl :
  forall (sigma:Numbers.BinNums.Z -> value)
    (a:set.Fset.fset Numbers.BinNums.Z),
  assigns sigma a sigma.

Axiom assigns_trans :
  forall (sigma1:Numbers.BinNums.Z -> value)
    (sigma2:Numbers.BinNums.Z -> value) (sigma3:Numbers.BinNums.Z -> value)
    (a:set.Fset.fset Numbers.BinNums.Z),
  assigns sigma1 a sigma2 /\ assigns sigma2 a sigma3 ->
  assigns sigma1 a sigma3.

Axiom assigns_union_left :
  forall (sigma:Numbers.BinNums.Z -> value)
    (sigma':Numbers.BinNums.Z -> value) (s1:set.Fset.fset Numbers.BinNums.Z)
    (s2:set.Fset.fset Numbers.BinNums.Z),
  assigns sigma s1 sigma' -> assigns sigma (set.Fset.union s1 s2) sigma'.

Axiom assigns_union_right :
  forall (sigma:Numbers.BinNums.Z -> value)
    (sigma':Numbers.BinNums.Z -> value) (s1:set.Fset.fset Numbers.BinNums.Z)
    (s2:set.Fset.fset Numbers.BinNums.Z),
  assigns sigma s2 sigma' -> assigns sigma (set.Fset.union s1 s2) sigma'.

(* Why3 assumption *)
Fixpoint stmt_writes (i:stmt)
  (w:set.Fset.fset Numbers.BinNums.Z) {struct i}: Prop :=
  match i with
  | Sskip|(Sassert _) => True
  | Sassign id _ => set.Fset.mem id w
  | (Sseq s1 s2)|(Sif _ s1 s2) => stmt_writes s1 w /\ stmt_writes s2 w
  | Swhile _ _ s => stmt_writes s w
  end.

Axiom consequence_rule :
  forall (p:fmla) (p':fmla) (q:fmla) (q':fmla) (i:stmt),
  valid_fmla (Fimplies p' p) -> valid_triple p i q ->
  valid_fmla (Fimplies q q') -> valid_triple p' i q'.

Axiom skip_rule : forall (q:fmla), valid_triple q Sskip q.

Axiom assign_rule :
  forall (q:fmla) (x:Numbers.BinNums.Z) (id:Numbers.BinNums.Z) (e:term),
  fresh_in_fmla id q ->
  valid_triple (Flet id e (subst q x id)) (Sassign x e) q.

Axiom seq_rule :
  forall (p:fmla) (q:fmla) (r:fmla) (i1:stmt) (i2:stmt),
  valid_triple p i1 r /\ valid_triple r i2 q -> valid_triple p (Sseq i1 i2) q.

Axiom if_rule :
  forall (e:term) (p:fmla) (q:fmla) (i1:stmt) (i2:stmt),
  valid_triple (Fand p (Fterm e)) i1 q /\
  valid_triple (Fand p (Fnot (Fterm e))) i2 q ->
  valid_triple p (Sif e i1 i2) q.

Axiom assert_rule :
  forall (f:fmla) (p:fmla), valid_fmla (Fimplies p f) ->
  valid_triple p (Sassert f) p.

Axiom assert_rule_ext :
  forall (f:fmla) (p:fmla), valid_triple (Fimplies f p) (Sassert f) p.

Axiom while_rule :
  forall (e:term) (inv:fmla) (i:stmt),
  valid_triple (Fand (Fterm e) inv) i inv ->
  valid_triple inv (Swhile e inv i) (Fand (Fnot (Fterm e)) inv).

Axiom while_rule_ext :
  forall (e:term) (inv:fmla) (inv':fmla) (i:stmt),
  valid_fmla (Fimplies inv' inv) ->
  valid_triple (Fand (Fterm e) inv') i inv' ->
  valid_triple inv' (Swhile e inv i) (Fand (Fnot (Fterm e)) inv').

(* Why3 goal *)
Theorem wp'VC :
  forall (i:stmt) (q:fmla), forall (result:fmla),
  (exists x:term, exists x1:fmla, exists x2:stmt,
   (i = (Swhile x x1 x2)) /\
   (exists o:fmla,
    valid_triple o x2 x1 /\
    (exists o1:fmla,
     (forall (sigma:Numbers.BinNums.Z -> value)
        (pi:Numbers.BinNums.Z -> value),
      eval_fmla sigma pi o1 ->
      eval_fmla sigma pi
      (Fand (Fimplies (Fand (Fterm x) x1) o)
       (Fimplies (Fand (Fnot (Fterm x)) x1) q)) /\
      (forall (sigma':Numbers.BinNums.Z -> value)
         (pi':Numbers.BinNums.Z -> value) (n:Numbers.BinNums.Z),
       many_steps sigma pi x2 sigma' pi' Sskip n -> eval_fmla sigma' pi' o1)) /\
     (result = (Fand x1 o1))))) ->
  valid_triple result i q.
Proof.
(* intros i q result (x,(x1,(x2,(h1,(o,(h2,(o1,(h3,h4)))))))). *)
intros i Post result.
intros (cond, (inv, (body, (h1,h2)))).
rewrite h1 in *;clear h1 i.
destruct h2 as (WP_body & H_WP_body & abstracted_fmla & H_abstracted & h3).
subst result.
red.  
intros s1 p1 H1 s2 p2 n Hsteps.
assert (H_n_pos := steps_non_neg _ _ _ _ _ _ _ Hsteps).
generalize s1 p1 H1 Hsteps; clear s1 p1 H1 Hsteps.
apply (Z_lt_induction ( 
  fun n => forall s1 p1 : Map.map Z value,
    eval_fmla s1 p1 (Fand inv abstracted_fmla) ->
    many_steps s1 p1 (Swhile cond inv body) s2 p2 Sskip n ->
    eval_fmla s2 p2 Post)); auto.
intros.
elim H0; clear H0; intros H_inv_in_s2 H_abstr_in_s2.
inversion H1; subst; clear H1.
inversion H0; subst; clear H0.
(* case cond = true *)
destruct (many_steps_seq _ _ _ _ _ _ _ H2) as 
  (s3 & p3 & n1 & n2 & First_iter & Next_iter & Hn1n2).
clear H2.
apply H with (3:=Next_iter).
  assert (Hn1_pos := steps_non_neg _ _ _ _ _ _ _ First_iter).
  assert (Hn2_pos := steps_non_neg _ _ _ _ _ _ _ Next_iter).
  omega.
destruct (H_abstracted sigma2 pi2 H_abstr_in_s2) as ((Htrue,_) & Hnext).
clear H_abstracted.
assert (H_abstr_in_s3 := Hnext s3 p3 n1 First_iter); clear Hnext.
split; auto.
red in H_WP_body.
apply H_WP_body with (2:=First_iter).
apply Htrue; auto.
(* case cond = false *)
inversion H2; [subst; clear H2 | inversion H0].
destruct (H_abstracted s2 p2 H_abstr_in_s2) as ((_,Hfalse) & Hnext).
clear H_abstracted.
apply Hfalse; split; auto.
rewrite H11; discriminate.
Qed.