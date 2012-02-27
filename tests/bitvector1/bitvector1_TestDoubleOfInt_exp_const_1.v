(* This file is generated by Why3's Coq driver *)
(* Beware! Only edit allowed sections below    *)
Require Import ZArith.
Require Import Rbase.
Definition implb(x:bool) (y:bool): bool := match (x,
  y) with
  | (true, false) => false
  | (_, _) => true
  end.

Parameter pow2: Z -> Z.


Axiom Power_0 : ((pow2 0%Z) = 1%Z).

Axiom Power_s : forall (n:Z), (0%Z <= n)%Z ->
  ((pow2 (n + 1%Z)%Z) = (2%Z * (pow2 n))%Z).

Axiom Power_1 : ((pow2 1%Z) = 2%Z).

Axiom Power_sum : forall (n:Z) (m:Z), ((0%Z <= n)%Z /\ (0%Z <= m)%Z) ->
  ((pow2 (n + m)%Z) = ((pow2 n) * (pow2 m))%Z).

Axiom pow2_0 : ((pow2 0%Z) = 1%Z).

Axiom pow2_1 : ((pow2 1%Z) = 2%Z).

Axiom pow2_2 : ((pow2 2%Z) = 4%Z).

Axiom pow2_3 : ((pow2 3%Z) = 8%Z).

Axiom pow2_4 : ((pow2 4%Z) = 16%Z).

Axiom pow2_5 : ((pow2 5%Z) = 32%Z).

Axiom pow2_6 : ((pow2 6%Z) = 64%Z).

Axiom pow2_7 : ((pow2 7%Z) = 128%Z).

Axiom pow2_8 : ((pow2 8%Z) = 256%Z).

Axiom pow2_9 : ((pow2 9%Z) = 512%Z).

Axiom pow2_10 : ((pow2 10%Z) = 1024%Z).

Axiom pow2_11 : ((pow2 11%Z) = 2048%Z).

Axiom pow2_12 : ((pow2 12%Z) = 4096%Z).

Axiom pow2_13 : ((pow2 13%Z) = 8192%Z).

Axiom pow2_14 : ((pow2 14%Z) = 16384%Z).

Axiom pow2_15 : ((pow2 15%Z) = 32768%Z).

Axiom pow2_16 : ((pow2 16%Z) = 65536%Z).

Axiom pow2_17 : ((pow2 17%Z) = 131072%Z).

Axiom pow2_18 : ((pow2 18%Z) = 262144%Z).

Axiom pow2_19 : ((pow2 19%Z) = 524288%Z).

Axiom pow2_20 : ((pow2 20%Z) = 1048576%Z).

Axiom pow2_21 : ((pow2 21%Z) = 2097152%Z).

Axiom pow2_22 : ((pow2 22%Z) = 4194304%Z).

Axiom pow2_23 : ((pow2 23%Z) = 8388608%Z).

Axiom pow2_24 : ((pow2 24%Z) = 16777216%Z).

Axiom pow2_25 : ((pow2 25%Z) = 33554432%Z).

Axiom pow2_26 : ((pow2 26%Z) = 67108864%Z).

Axiom pow2_27 : ((pow2 27%Z) = 134217728%Z).

Axiom pow2_28 : ((pow2 28%Z) = 268435456%Z).

Axiom pow2_29 : ((pow2 29%Z) = 536870912%Z).

Axiom pow2_30 : ((pow2 30%Z) = 1073741824%Z).

Axiom pow2_31 : ((pow2 31%Z) = 2147483648%Z).

Axiom pow2_32 : ((pow2 32%Z) = 4294967296%Z).

Axiom pow2_33 : ((pow2 33%Z) = 8589934592%Z).

Axiom pow2_34 : ((pow2 34%Z) = 17179869184%Z).

Axiom pow2_35 : ((pow2 35%Z) = 34359738368%Z).

Axiom pow2_36 : ((pow2 36%Z) = 68719476736%Z).

Axiom pow2_37 : ((pow2 37%Z) = 137438953472%Z).

Axiom pow2_38 : ((pow2 38%Z) = 274877906944%Z).

Axiom pow2_39 : ((pow2 39%Z) = 549755813888%Z).

Axiom pow2_40 : ((pow2 40%Z) = 1099511627776%Z).

Axiom pow2_41 : ((pow2 41%Z) = 2199023255552%Z).

Axiom pow2_42 : ((pow2 42%Z) = 4398046511104%Z).

Axiom pow2_43 : ((pow2 43%Z) = 8796093022208%Z).

Axiom pow2_44 : ((pow2 44%Z) = 17592186044416%Z).

Axiom pow2_45 : ((pow2 45%Z) = 35184372088832%Z).

Axiom pow2_46 : ((pow2 46%Z) = 70368744177664%Z).

Axiom pow2_47 : ((pow2 47%Z) = 140737488355328%Z).

Axiom pow2_48 : ((pow2 48%Z) = 281474976710656%Z).

Axiom pow2_49 : ((pow2 49%Z) = 562949953421312%Z).

Axiom pow2_50 : ((pow2 50%Z) = 1125899906842624%Z).

Axiom pow2_51 : ((pow2 51%Z) = 2251799813685248%Z).

Axiom pow2_52 : ((pow2 52%Z) = 4503599627370496%Z).

Axiom pow2_53 : ((pow2 53%Z) = 9007199254740992%Z).

Axiom pow2_54 : ((pow2 54%Z) = 18014398509481984%Z).

Axiom pow2_55 : ((pow2 55%Z) = 36028797018963968%Z).

Axiom pow2_56 : ((pow2 56%Z) = 72057594037927936%Z).

Axiom pow2_57 : ((pow2 57%Z) = 144115188075855872%Z).

Axiom pow2_58 : ((pow2 58%Z) = 288230376151711744%Z).

Axiom pow2_59 : ((pow2 59%Z) = 576460752303423488%Z).

Axiom pow2_60 : ((pow2 60%Z) = 1152921504606846976%Z).

Axiom pow2_61 : ((pow2 61%Z) = 2305843009213693952%Z).

Axiom pow2_62 : ((pow2 62%Z) = 4611686018427387904%Z).

Axiom pow2_63 : ((pow2 63%Z) = 9223372036854775808%Z).

Parameter bv : Type.

Axiom size_positive : (0%Z <  32%Z)%Z.

Parameter nth: bv -> Z -> bool.


Parameter bvzero: bv.


Axiom Nth_zero : forall (n:Z), ((0%Z <= n)%Z /\ (n <  32%Z)%Z) ->
  ((nth bvzero n) = false).

Parameter bvone: bv.


Axiom Nth_one : forall (n:Z), ((0%Z <= n)%Z /\ (n <  32%Z)%Z) -> ((nth bvone
  n) = true).

Definition eq(v1:bv) (v2:bv): Prop := forall (n:Z), ((0%Z <= n)%Z /\
  (n <  32%Z)%Z) -> ((nth v1 n) = (nth v2 n)).

Axiom extensionality : forall (v1:bv) (v2:bv), (eq v1 v2) -> (v1 = v2).

Parameter bw_and: bv -> bv -> bv.


Axiom Nth_bw_and : forall (v1:bv) (v2:bv) (n:Z), ((0%Z <= n)%Z /\
  (n <  32%Z)%Z) -> ((nth (bw_and v1 v2) n) = (andb (nth v1 n) (nth v2 n))).

Parameter bw_or: bv -> bv -> bv.


Axiom Nth_bw_or : forall (v1:bv) (v2:bv) (n:Z), ((0%Z <= n)%Z /\
  (n <  32%Z)%Z) -> ((nth (bw_or v1 v2) n) = (orb (nth v1 n) (nth v2 n))).

Parameter bw_xor: bv -> bv -> bv.


Axiom Nth_bw_xor : forall (v1:bv) (v2:bv) (n:Z), ((0%Z <= n)%Z /\
  (n <  32%Z)%Z) -> ((nth (bw_xor v1 v2) n) = (xorb (nth v1 n) (nth v2 n))).

Axiom Nth_bw_xor_v1true : forall (v1:bv) (v2:bv) (n:Z), (((0%Z <= n)%Z /\
  (n <  32%Z)%Z) /\ ((nth v1 n) = true)) -> ((nth (bw_xor v1 v2)
  n) = (negb (nth v2 n))).

Axiom Nth_bw_xor_v1false : forall (v1:bv) (v2:bv) (n:Z), (((0%Z <= n)%Z /\
  (n <  32%Z)%Z) /\ ((nth v1 n) = false)) -> ((nth (bw_xor v1 v2)
  n) = (nth v2 n)).

Axiom Nth_bw_xor_v2true : forall (v1:bv) (v2:bv) (n:Z), (((0%Z <= n)%Z /\
  (n <  32%Z)%Z) /\ ((nth v2 n) = true)) -> ((nth (bw_xor v1 v2)
  n) = (negb (nth v1 n))).

Axiom Nth_bw_xor_v2false : forall (v1:bv) (v2:bv) (n:Z), (((0%Z <= n)%Z /\
  (n <  32%Z)%Z) /\ ((nth v2 n) = false)) -> ((nth (bw_xor v1 v2)
  n) = (nth v1 n)).

Parameter bw_not: bv -> bv.


Axiom Nth_bw_not : forall (v:bv) (n:Z), ((0%Z <= n)%Z /\ (n <  32%Z)%Z) ->
  ((nth (bw_not v) n) = (negb (nth v n))).

Parameter lsr: bv -> Z -> bv.


Axiom lsr_nth_low : forall (b:bv) (n:Z) (s:Z), (((0%Z <= n)%Z /\
  (n <  32%Z)%Z) /\ (((0%Z <= s)%Z /\ (s <  32%Z)%Z) /\
  ((n + s)%Z <  32%Z)%Z)) -> ((nth (lsr b s) n) = (nth b (n + s)%Z)).

Axiom lsr_nth_high : forall (b:bv) (n:Z) (s:Z), (((0%Z <= n)%Z /\
  (n <  32%Z)%Z) /\ (((0%Z <= s)%Z /\ (s <  32%Z)%Z) /\
  (32%Z <= (n + s)%Z)%Z)) -> ((nth (lsr b s) n) = false).

Parameter asr: bv -> Z -> bv.


Axiom asr_nth_low : forall (b:bv) (n:Z) (s:Z), ((0%Z <= n)%Z /\
  (n <  32%Z)%Z) -> ((0%Z <= s)%Z -> (((n + s)%Z <  32%Z)%Z -> ((nth (asr b
  s) n) = (nth b (n + s)%Z)))).

Axiom asr_nth_high : forall (b:bv) (n:Z) (s:Z), ((0%Z <= n)%Z /\
  (n <  32%Z)%Z) -> ((0%Z <= s)%Z -> ((32%Z <= (n + s)%Z)%Z -> ((nth (asr b
  s) n) = (nth b (32%Z - 1%Z)%Z)))).

Parameter lsl: bv -> Z -> bv.


Axiom lsl_nth_high : forall (b:bv) (n:Z) (s:Z), ((0%Z <= n)%Z /\
  (n <  32%Z)%Z) -> ((0%Z <= s)%Z -> ((0%Z <= (n - s)%Z)%Z -> ((nth (lsl b s)
  n) = (nth b (n - s)%Z)))).

Axiom lsl_nth_low : forall (b:bv) (n:Z) (s:Z), ((0%Z <= n)%Z /\
  (n <  32%Z)%Z) -> ((0%Z <= s)%Z -> (((n - s)%Z <  0%Z)%Z -> ((nth (lsl b s)
  n) = false))).

Parameter to_nat_sub: bv -> Z -> Z -> Z.


Axiom to_nat_sub_zero : forall (b:bv) (j:Z) (i:Z), ((0%Z <= i)%Z /\
  (i <= j)%Z) -> (((nth b j) = false) -> ((to_nat_sub b j i) = (to_nat_sub b
  (j - 1%Z)%Z i))).

Axiom to_nat_sub_one : forall (b:bv) (j:Z) (i:Z), ((0%Z <= i)%Z /\
  (i <= j)%Z) -> (((nth b j) = true) -> ((to_nat_sub b j
  i) = ((pow2 (j - i)%Z) + (to_nat_sub b (j - 1%Z)%Z i))%Z)).

Axiom to_nat_sub_high : forall (b:bv) (j:Z) (i:Z), (j <  i)%Z ->
  ((to_nat_sub b j i) = 0%Z).

Axiom to_nat_of_zero2 : forall (b:bv) (i:Z) (j:Z), ((i <= j)%Z /\
  (0%Z <= i)%Z) -> ((forall (k:Z), ((k <= j)%Z /\ (i <  k)%Z) -> ((nth b
  k) = false)) -> ((to_nat_sub b j 0%Z) = (to_nat_sub b i 0%Z))).

Axiom to_nat_of_zero : forall (b:bv) (i:Z) (j:Z), ((i <= j)%Z /\
  (0%Z <= i)%Z) -> ((forall (k:Z), ((k <= j)%Z /\ (i <= k)%Z) -> ((nth b
  k) = false)) -> ((to_nat_sub b j i) = 0%Z)).

Axiom to_nat_of_one : forall (b:bv) (i:Z) (j:Z), ((i <= j)%Z /\
  (0%Z <= i)%Z) -> ((forall (k:Z), ((k <= j)%Z /\ (i <= k)%Z) -> ((nth b
  k) = true)) -> ((to_nat_sub b j
  i) = ((pow2 ((j - i)%Z + 1%Z)%Z) - 1%Z)%Z)).

Axiom to_nat_sub_footprint : forall (b1:bv) (b2:bv) (j:Z) (i:Z),
  ((i <= j)%Z /\ (0%Z <= i)%Z) -> ((forall (k:Z), ((i <= k)%Z /\
  (k <= j)%Z) -> ((nth b1 k) = (nth b2 k))) -> ((to_nat_sub b1 j
  i) = (to_nat_sub b2 j i))).

Axiom lsr_to_nat_sub : forall (b:bv) (s:Z), ((0%Z <= s)%Z /\
  (s <  32%Z)%Z) -> ((to_nat_sub (lsr b s) (32%Z - 1%Z)%Z
  0%Z) = (to_nat_sub b ((32%Z - 1%Z)%Z - s)%Z 0%Z)).

Parameter from_int: Z -> bv.


Axiom Abs_le : forall (x:Z) (y:Z), ((Zabs x) <= y)%Z <-> (((-y)%Z <= x)%Z /\
  (x <= y)%Z).

Parameter div: Z -> Z -> Z.


Parameter mod1: Z -> Z -> Z.


Axiom Div_mod : forall (x:Z) (y:Z), (~ (y = 0%Z)) -> (x = ((y * (div x
  y))%Z + (mod1 x y))%Z).

Axiom Div_bound : forall (x:Z) (y:Z), ((0%Z <= x)%Z /\ (0%Z <  y)%Z) ->
  ((0%Z <= (div x y))%Z /\ ((div x y) <= x)%Z).

Axiom Mod_bound : forall (x:Z) (y:Z), (~ (y = 0%Z)) -> ((0%Z <= (mod1 x
  y))%Z /\ ((mod1 x y) <  (Zabs y))%Z).

Axiom Mod_1 : forall (x:Z), ((mod1 x 1%Z) = 0%Z).

Axiom Div_1 : forall (x:Z), ((div x 1%Z) = x).

Axiom nth_from_int_high_even : forall (n:Z) (i:Z), (((i <  32%Z)%Z /\
  (0%Z <= i)%Z) /\ ((mod1 (div n (pow2 i)) 2%Z) = 0%Z)) -> ((nth (from_int n)
  i) = false).

Axiom nth_from_int_high_odd : forall (n:Z) (i:Z), (((i <  32%Z)%Z /\
  (0%Z <= i)%Z) /\ ~ ((mod1 (div n (pow2 i)) 2%Z) = 0%Z)) ->
  ((nth (from_int n) i) = true).

Axiom nth_from_int_low_even : forall (n:Z), ((mod1 n 2%Z) = 0%Z) ->
  ((nth (from_int n) 0%Z) = false).

Axiom nth_from_int_low_odd : forall (n:Z), (~ ((mod1 n 2%Z) = 0%Z)) ->
  ((nth (from_int n) 0%Z) = true).

Axiom pow2i : forall (i:Z), (0%Z <= i)%Z -> ~ ((pow2 i) = 0%Z).

Axiom nth_from_int_0 : forall (i:Z), ((i <  32%Z)%Z /\ (0%Z <= i)%Z) ->
  ((nth (from_int 0%Z) i) = false).

Parameter from_int2c: Z -> bv.


Axiom size_from_int2c : (0%Z <  (32%Z - 1%Z)%Z)%Z.

Axiom nth_sign_positive : forall (n:Z), (0%Z <= n)%Z -> ((nth (from_int2c n)
  (32%Z - 1%Z)%Z) = false).

Axiom nth_from_int2c_high_even_positive : forall (n:Z) (i:Z),
  ((0%Z <= n)%Z /\ (((i <  (32%Z - 1%Z)%Z)%Z /\ (0%Z <= i)%Z) /\
  ((mod1 (div n (pow2 i)) 2%Z) = 0%Z))) -> ((nth (from_int2c n) i) = false).

Axiom nth_from_int2c_high_odd_positive : forall (n:Z) (i:Z), ((0%Z <= n)%Z /\
  (((i <  (32%Z - 1%Z)%Z)%Z /\ (0%Z <= i)%Z) /\ ~ ((mod1 (div n (pow2 i))
  2%Z) = 0%Z))) -> ((nth (from_int2c n) i) = true).

Axiom nth_from_int2c_low_even_positive : forall (n:Z), ((0%Z <= n)%Z /\
  ((mod1 n 2%Z) = 0%Z)) -> ((nth (from_int2c n) 0%Z) = false).

Axiom nth_from_int2c_low_odd_positive : forall (n:Z), ((0%Z <= n)%Z /\
  ~ ((mod1 n 2%Z) = 0%Z)) -> ((nth (from_int2c n) 0%Z) = true).

Axiom nth_sign_negative : forall (n:Z), (0%Z <= n)%Z -> ((nth (from_int2c n)
  (32%Z - 1%Z)%Z) = true).

Axiom nth_from_int2c_high_even_negative : forall (n:Z) (i:Z),
  ((n <  0%Z)%Z /\ (((i <  (32%Z - 1%Z)%Z)%Z /\ (0%Z <= i)%Z) /\
  ((mod1 (div n (pow2 i)) 2%Z) = 0%Z))) -> ((nth (from_int2c n) i) = true).

Axiom nth_from_int2c_high_odd_negative : forall (n:Z) (i:Z), ((n <  0%Z)%Z /\
  (((i <  (32%Z - 1%Z)%Z)%Z /\ (0%Z <= i)%Z) /\ ~ ((mod1 (div n (pow2 i))
  2%Z) = 0%Z))) -> ((nth (from_int2c n) i) = false).

Axiom nth_from_int2c_low_even_negative : forall (n:Z), ((n <  0%Z)%Z /\
  ((mod1 n 2%Z) = 0%Z)) -> ((nth (from_int2c n) 0%Z) = true).

Axiom nth_from_int2c_low_odd_negative : forall (n:Z), ((n <  0%Z)%Z /\
  ~ ((mod1 n 2%Z) = 0%Z)) -> ((nth (from_int2c n) 0%Z) = false).

Parameter bv1 : Type.

Axiom size_positive1 : (0%Z <  64%Z)%Z.

Parameter nth1: bv1 -> Z -> bool.


Parameter bvzero1: bv1.


Axiom Nth_zero1 : forall (n:Z), ((0%Z <= n)%Z /\ (n <  64%Z)%Z) ->
  ((nth1 bvzero1 n) = false).

Parameter bvone1: bv1.


Axiom Nth_one1 : forall (n:Z), ((0%Z <= n)%Z /\ (n <  64%Z)%Z) ->
  ((nth1 bvone1 n) = true).

Definition eq1(v1:bv1) (v2:bv1): Prop := forall (n:Z), ((0%Z <= n)%Z /\
  (n <  64%Z)%Z) -> ((nth1 v1 n) = (nth1 v2 n)).

Axiom extensionality1 : forall (v1:bv1) (v2:bv1), (eq1 v1 v2) -> (v1 = v2).

Parameter bw_and1: bv1 -> bv1 -> bv1.


Axiom Nth_bw_and1 : forall (v1:bv1) (v2:bv1) (n:Z), ((0%Z <= n)%Z /\
  (n <  64%Z)%Z) -> ((nth1 (bw_and1 v1 v2) n) = (andb (nth1 v1 n) (nth1 v2
  n))).

Parameter bw_or1: bv1 -> bv1 -> bv1.


Axiom Nth_bw_or1 : forall (v1:bv1) (v2:bv1) (n:Z), ((0%Z <= n)%Z /\
  (n <  64%Z)%Z) -> ((nth1 (bw_or1 v1 v2) n) = (orb (nth1 v1 n) (nth1 v2
  n))).

Parameter bw_xor1: bv1 -> bv1 -> bv1.


Axiom Nth_bw_xor1 : forall (v1:bv1) (v2:bv1) (n:Z), ((0%Z <= n)%Z /\
  (n <  64%Z)%Z) -> ((nth1 (bw_xor1 v1 v2) n) = (xorb (nth1 v1 n) (nth1 v2
  n))).

Axiom Nth_bw_xor_v1true1 : forall (v1:bv1) (v2:bv1) (n:Z), (((0%Z <= n)%Z /\
  (n <  64%Z)%Z) /\ ((nth1 v1 n) = true)) -> ((nth1 (bw_xor1 v1 v2)
  n) = (negb (nth1 v2 n))).

Axiom Nth_bw_xor_v1false1 : forall (v1:bv1) (v2:bv1) (n:Z), (((0%Z <= n)%Z /\
  (n <  64%Z)%Z) /\ ((nth1 v1 n) = false)) -> ((nth1 (bw_xor1 v1 v2)
  n) = (nth1 v2 n)).

Axiom Nth_bw_xor_v2true1 : forall (v1:bv1) (v2:bv1) (n:Z), (((0%Z <= n)%Z /\
  (n <  64%Z)%Z) /\ ((nth1 v2 n) = true)) -> ((nth1 (bw_xor1 v1 v2)
  n) = (negb (nth1 v1 n))).

Axiom Nth_bw_xor_v2false1 : forall (v1:bv1) (v2:bv1) (n:Z), (((0%Z <= n)%Z /\
  (n <  64%Z)%Z) /\ ((nth1 v2 n) = false)) -> ((nth1 (bw_xor1 v1 v2)
  n) = (nth1 v1 n)).

Parameter bw_not1: bv1 -> bv1.


Axiom Nth_bw_not1 : forall (v:bv1) (n:Z), ((0%Z <= n)%Z /\ (n <  64%Z)%Z) ->
  ((nth1 (bw_not1 v) n) = (negb (nth1 v n))).

Parameter lsr1: bv1 -> Z -> bv1.


Axiom lsr_nth_low1 : forall (b:bv1) (n:Z) (s:Z), (((0%Z <= n)%Z /\
  (n <  64%Z)%Z) /\ (((0%Z <= s)%Z /\ (s <  64%Z)%Z) /\
  ((n + s)%Z <  64%Z)%Z)) -> ((nth1 (lsr1 b s) n) = (nth1 b (n + s)%Z)).

Axiom lsr_nth_high1 : forall (b:bv1) (n:Z) (s:Z), (((0%Z <= n)%Z /\
  (n <  64%Z)%Z) /\ (((0%Z <= s)%Z /\ (s <  64%Z)%Z) /\
  (64%Z <= (n + s)%Z)%Z)) -> ((nth1 (lsr1 b s) n) = false).

Parameter asr1: bv1 -> Z -> bv1.


Axiom asr_nth_low1 : forall (b:bv1) (n:Z) (s:Z), ((0%Z <= n)%Z /\
  (n <  64%Z)%Z) -> ((0%Z <= s)%Z -> (((n + s)%Z <  64%Z)%Z -> ((nth1 (asr1 b
  s) n) = (nth1 b (n + s)%Z)))).

Axiom asr_nth_high1 : forall (b:bv1) (n:Z) (s:Z), ((0%Z <= n)%Z /\
  (n <  64%Z)%Z) -> ((0%Z <= s)%Z -> ((64%Z <= (n + s)%Z)%Z -> ((nth1 (asr1 b
  s) n) = (nth1 b (64%Z - 1%Z)%Z)))).

Parameter lsl1: bv1 -> Z -> bv1.


Axiom lsl_nth_high1 : forall (b:bv1) (n:Z) (s:Z), ((0%Z <= n)%Z /\
  (n <  64%Z)%Z) -> ((0%Z <= s)%Z -> ((0%Z <= (n - s)%Z)%Z -> ((nth1 (lsl1 b
  s) n) = (nth1 b (n - s)%Z)))).

Axiom lsl_nth_low1 : forall (b:bv1) (n:Z) (s:Z), ((0%Z <= n)%Z /\
  (n <  64%Z)%Z) -> ((0%Z <= s)%Z -> (((n - s)%Z <  0%Z)%Z -> ((nth1 (lsl1 b
  s) n) = false))).

Parameter to_nat_sub1: bv1 -> Z -> Z -> Z.


Axiom to_nat_sub_zero1 : forall (b:bv1) (j:Z) (i:Z), ((0%Z <= i)%Z /\
  (i <= j)%Z) -> (((nth1 b j) = false) -> ((to_nat_sub1 b j
  i) = (to_nat_sub1 b (j - 1%Z)%Z i))).

Axiom to_nat_sub_one1 : forall (b:bv1) (j:Z) (i:Z), ((0%Z <= i)%Z /\
  (i <= j)%Z) -> (((nth1 b j) = true) -> ((to_nat_sub1 b j
  i) = ((pow2 (j - i)%Z) + (to_nat_sub1 b (j - 1%Z)%Z i))%Z)).

Axiom to_nat_sub_high1 : forall (b:bv1) (j:Z) (i:Z), (j <  i)%Z ->
  ((to_nat_sub1 b j i) = 0%Z).

Axiom to_nat_of_zero21 : forall (b:bv1) (i:Z) (j:Z), ((i <= j)%Z /\
  (0%Z <= i)%Z) -> ((forall (k:Z), ((k <= j)%Z /\ (i <  k)%Z) -> ((nth1 b
  k) = false)) -> ((to_nat_sub1 b j 0%Z) = (to_nat_sub1 b i 0%Z))).

Axiom to_nat_of_zero1 : forall (b:bv1) (i:Z) (j:Z), ((i <= j)%Z /\
  (0%Z <= i)%Z) -> ((forall (k:Z), ((k <= j)%Z /\ (i <= k)%Z) -> ((nth1 b
  k) = false)) -> ((to_nat_sub1 b j i) = 0%Z)).

Axiom to_nat_of_one1 : forall (b:bv1) (i:Z) (j:Z), ((i <= j)%Z /\
  (0%Z <= i)%Z) -> ((forall (k:Z), ((k <= j)%Z /\ (i <= k)%Z) -> ((nth1 b
  k) = true)) -> ((to_nat_sub1 b j
  i) = ((pow2 ((j - i)%Z + 1%Z)%Z) - 1%Z)%Z)).

Axiom to_nat_sub_footprint1 : forall (b1:bv1) (b2:bv1) (j:Z) (i:Z),
  ((i <= j)%Z /\ (0%Z <= i)%Z) -> ((forall (k:Z), ((i <= k)%Z /\
  (k <= j)%Z) -> ((nth1 b1 k) = (nth1 b2 k))) -> ((to_nat_sub1 b1 j
  i) = (to_nat_sub1 b2 j i))).

Axiom lsr_to_nat_sub1 : forall (b:bv1) (s:Z), ((0%Z <= s)%Z /\
  (s <  64%Z)%Z) -> ((to_nat_sub1 (lsr1 b s) (64%Z - 1%Z)%Z
  0%Z) = (to_nat_sub1 b ((64%Z - 1%Z)%Z - s)%Z 0%Z)).

Parameter from_int1: Z -> bv1.


Axiom nth_from_int_high_even1 : forall (n:Z) (i:Z), (((i <  64%Z)%Z /\
  (0%Z <= i)%Z) /\ ((mod1 (div n (pow2 i)) 2%Z) = 0%Z)) ->
  ((nth1 (from_int1 n) i) = false).

Axiom nth_from_int_high_odd1 : forall (n:Z) (i:Z), (((i <  64%Z)%Z /\
  (0%Z <= i)%Z) /\ ~ ((mod1 (div n (pow2 i)) 2%Z) = 0%Z)) ->
  ((nth1 (from_int1 n) i) = true).

Axiom nth_from_int_low_even1 : forall (n:Z), ((mod1 n 2%Z) = 0%Z) ->
  ((nth1 (from_int1 n) 0%Z) = false).

Axiom nth_from_int_low_odd1 : forall (n:Z), (~ ((mod1 n 2%Z) = 0%Z)) ->
  ((nth1 (from_int1 n) 0%Z) = true).

Axiom pow2i1 : forall (i:Z), (0%Z <= i)%Z -> ~ ((pow2 i) = 0%Z).

Axiom nth_from_int_01 : forall (i:Z), ((i <  64%Z)%Z /\ (0%Z <= i)%Z) ->
  ((nth1 (from_int1 0%Z) i) = false).

Parameter from_int2c1: Z -> bv1.


Axiom size_from_int2c1 : (0%Z <  (64%Z - 1%Z)%Z)%Z.

Axiom nth_sign_positive1 : forall (n:Z), (0%Z <= n)%Z ->
  ((nth1 (from_int2c1 n) (64%Z - 1%Z)%Z) = false).

Axiom nth_from_int2c_high_even_positive1 : forall (n:Z) (i:Z),
  ((0%Z <= n)%Z /\ (((i <  (64%Z - 1%Z)%Z)%Z /\ (0%Z <= i)%Z) /\
  ((mod1 (div n (pow2 i)) 2%Z) = 0%Z))) -> ((nth1 (from_int2c1 n)
  i) = false).

Axiom nth_from_int2c_high_odd_positive1 : forall (n:Z) (i:Z),
  ((0%Z <= n)%Z /\ (((i <  (64%Z - 1%Z)%Z)%Z /\ (0%Z <= i)%Z) /\
  ~ ((mod1 (div n (pow2 i)) 2%Z) = 0%Z))) -> ((nth1 (from_int2c1 n)
  i) = true).

Axiom nth_from_int2c_low_even_positive1 : forall (n:Z), ((0%Z <= n)%Z /\
  ((mod1 n 2%Z) = 0%Z)) -> ((nth1 (from_int2c1 n) 0%Z) = false).

Axiom nth_from_int2c_low_odd_positive1 : forall (n:Z), ((0%Z <= n)%Z /\
  ~ ((mod1 n 2%Z) = 0%Z)) -> ((nth1 (from_int2c1 n) 0%Z) = true).

Axiom nth_sign_negative1 : forall (n:Z), (0%Z <= n)%Z ->
  ((nth1 (from_int2c1 n) (64%Z - 1%Z)%Z) = true).

Axiom nth_from_int2c_high_even_negative1 : forall (n:Z) (i:Z),
  ((n <  0%Z)%Z /\ (((i <  (64%Z - 1%Z)%Z)%Z /\ (0%Z <= i)%Z) /\
  ((mod1 (div n (pow2 i)) 2%Z) = 0%Z))) -> ((nth1 (from_int2c1 n) i) = true).

Axiom nth_from_int2c_high_odd_negative1 : forall (n:Z) (i:Z),
  ((n <  0%Z)%Z /\ (((i <  (64%Z - 1%Z)%Z)%Z /\ (0%Z <= i)%Z) /\
  ~ ((mod1 (div n (pow2 i)) 2%Z) = 0%Z))) -> ((nth1 (from_int2c1 n)
  i) = false).

Axiom nth_from_int2c_low_even_negative1 : forall (n:Z), ((n <  0%Z)%Z /\
  ((mod1 n 2%Z) = 0%Z)) -> ((nth1 (from_int2c1 n) 0%Z) = true).

Axiom nth_from_int2c_low_odd_negative1 : forall (n:Z), ((n <  0%Z)%Z /\
  ~ ((mod1 n 2%Z) = 0%Z)) -> ((nth1 (from_int2c1 n) 0%Z) = false).

Parameter concat: bv -> bv -> bv1.


Axiom concat_low : forall (b1:bv) (b2:bv), forall (i:Z), ((0%Z <= i)%Z /\
  (i <  32%Z)%Z) -> ((nth1 (concat b1 b2) i) = (nth b2 i)).

Axiom concat_high : forall (b1:bv) (b2:bv), forall (i:Z), ((32%Z <= i)%Z /\
  (i <  64%Z)%Z) -> ((nth1 (concat b1 b2) i) = (nth b1 (i - 32%Z)%Z)).

Parameter pow21: Z -> R.


Axiom Power_01 : ((pow21 0%Z) = 1%R).

Axiom Power_s1 : forall (n:Z), (0%Z <= n)%Z ->
  ((pow21 (n + 1%Z)%Z) = (2%R * (pow21 n))%R).

Axiom Power_p : forall (n:Z), (n <= 0%Z)%Z ->
  ((pow21 (n - 1%Z)%Z) = ((05 / 10)%R * (pow21 n))%R).

Axiom Power_11 : ((pow21 1%Z) = 2%R).

Axiom Power_neg1 : ((pow21 (-1%Z)%Z) = (05 / 10)%R).

Axiom Power_sum1 : forall (n:Z) (m:Z),
  ((pow21 (n + m)%Z) = ((pow21 n) * (pow21 m))%R).

Axiom Pow2_int_real : forall (x:Z), (0%Z <= x)%Z ->
  ((pow21 x) = (IZR (pow2 x))).

Parameter double_of_bv64: bv1 -> R.


Parameter sign_value: bool -> R.


Axiom sign_value_false : ((sign_value false) = 1%R).

Axiom sign_value_true : ((sign_value true) = (-1%R)%R).

Axiom zero : forall (b:bv1), (((to_nat_sub1 b 62%Z 52%Z) = 0%Z) /\
  ((to_nat_sub1 b 51%Z 0%Z) = 0%Z)) -> ((double_of_bv64 b) = 0%R).

Axiom sign_of_double_positive : forall (b:bv1), ((nth1 b 63%Z) = false) ->
  (0%R <= (double_of_bv64 b))%R.

Axiom sign_of_double_negative : forall (b:bv1), ((nth1 b 63%Z) = true) ->
  ((double_of_bv64 b) <= 0%R)%R.

Axiom double_of_bv64_value : forall (b:bv1), ((0%Z <  (to_nat_sub1 b 62%Z
  52%Z))%Z /\ ((to_nat_sub1 b 62%Z 52%Z) <  2047%Z)%Z) ->
  ((double_of_bv64 b) = (((sign_value (nth1 b 63%Z)) * (pow21 ((to_nat_sub1 b
  62%Z 52%Z) - 1023%Z)%Z))%R * (1%R + ((IZR (to_nat_sub1 b 51%Z
  0%Z)) * (pow21 (-52%Z)%Z))%R)%R)%R).

Axiom nth_const1 : forall (i:Z), ((0%Z <= i)%Z /\ (i <= 30%Z)%Z) ->
  ((nth1 (concat (from_int 1127219200%Z) (from_int 2147483648%Z))
  i) = false).

Axiom nth_const2 : ((nth1 (concat (from_int 1127219200%Z)
  (from_int 2147483648%Z)) 31%Z) = true).

Axiom nth_const3 : forall (i:Z), ((32%Z <= i)%Z /\ (i <= 51%Z)%Z) ->
  ((nth1 (concat (from_int 1127219200%Z) (from_int 2147483648%Z))
  i) = false).

Axiom nth_const4 : forall (i:Z), ((52%Z <= i)%Z /\ (i <= 53%Z)%Z) ->
  ((nth1 (concat (from_int 1127219200%Z) (from_int 2147483648%Z)) i) = true).

Axiom nth_const5 : forall (i:Z), ((54%Z <= i)%Z /\ (i <= 55%Z)%Z) ->
  ((nth1 (concat (from_int 1127219200%Z) (from_int 2147483648%Z))
  i) = false).

Axiom nth_const6 : forall (i:Z), ((56%Z <= i)%Z /\ (i <= 57%Z)%Z) ->
  ((nth1 (concat (from_int 1127219200%Z) (from_int 2147483648%Z)) i) = true).

Axiom nth_const7 : forall (i:Z), ((58%Z <= i)%Z /\ (i <= 61%Z)%Z) ->
  ((nth1 (concat (from_int 1127219200%Z) (from_int 2147483648%Z))
  i) = false).

Axiom nth_const8 : ((nth1 (concat (from_int 1127219200%Z)
  (from_int 2147483648%Z)) 62%Z) = true).

Axiom nth_const9 : ((nth1 (concat (from_int 1127219200%Z)
  (from_int 2147483648%Z)) 63%Z) = false).

Axiom sign_const : ((nth1 (concat (from_int 1127219200%Z)
  (from_int 2147483648%Z)) 63%Z) = false).

(* YOU MAY EDIT THE CONTEXT BELOW *)
Open Scope Z_scope.
(* DO NOT EDIT BELOW *)

Theorem exp_const : ((to_nat_sub1 (concat (from_int 1127219200%Z)
  (from_int 2147483648%Z)) 62%Z 52%Z) = 1075%Z).
(* YOU MAY EDIT THE PROOF BELOW *)
rewrite to_nat_sub_one1; auto with zarith.
  2: apply nth_const8.
replace (62 - 52) with 10 by omega.
 rewrite pow2_10.
rewrite to_nat_sub_zero1; auto with zarith.
  2: apply nth_const7; auto with zarith.
rewrite to_nat_sub_zero1; auto with zarith.
  2: apply nth_const7; auto with zarith.
rewrite to_nat_sub_zero1; auto with zarith.
  2: apply nth_const7; auto with zarith.
rewrite to_nat_sub_zero1; auto with zarith.
  2: apply nth_const7; auto with zarith.
rewrite to_nat_sub_one1; auto with zarith.
  2: apply nth_const6; auto with zarith.
replace (62 - 1 - 1 - 1 - 1 - 1 - 52) with 5 by omega.
 rewrite pow2_5.
rewrite to_nat_sub_one1; auto with zarith.
  2: apply nth_const6; auto with zarith.
replace (62 - 1 - 1 - 1 - 1 - 1 - 1 -  52) with 4 by omega.
 rewrite pow2_4.
rewrite to_nat_sub_zero1; auto with zarith.
  2: apply nth_const5; auto with zarith.
rewrite to_nat_sub_zero1; auto with zarith.
  2: apply nth_const5; auto with zarith.
rewrite to_nat_of_one1; auto with zarith.
replace (62 - 1 - 1 - 1 - 1 - 1 - 1 - 1 - 1 - 1 - 52) with 1 by omega.
replace (1+1) with 2 by omega.
 rewrite pow2_2; auto.
intros.
apply nth_const4; auto with zarith.
Qed.
(* DO NOT EDIT BELOW *)


