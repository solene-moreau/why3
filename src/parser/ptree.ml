(********************************************************************)
(*                                                                  *)
(*  The Why3 Verification Platform   /   The Why3 Development Team  *)
(*  Copyright 2010-2015   --   INRIA - CNRS - Paris-Sud University  *)
(*                                                                  *)
(*  This software is distributed under the terms of the GNU Lesser  *)
(*  General Public License version 2.1, with the special exception  *)
(*  on linking described in file LICENSE.                           *)
(*                                                                  *)
(********************************************************************)

(*s Parse trees. *)

type loc = Loc.position

(*s Logical terms and formulas *)

type integer_constant = Number.integer_constant
type real_constant = Number.real_constant
type constant = Number.constant

type label =
  | Lstr of Ident.label
  | Lpos of Loc.position

type quant =
  | Tforall | Texists | Tlambda

type binop =
  | Tand | Tand_asym | Tor | Tor_asym | Timplies | Tiff

type unop =
  | Tnot

type ident = {
  id_str : string;
  id_lab : label list;
  id_loc : loc;
}

type qualid =
  | Qident of ident
  | Qdot of qualid * ident

type pty =
  | PTtyvar of ident
  | PTtyapp of qualid * pty list
  | PTtuple of pty list
  | PTarrow of pty * pty
  | PTparen of pty

type ghost = bool

type binder = loc * ident option * ghost * pty option
type param  = loc * ident option * ghost * pty

type pattern = {
  pat_desc : pat_desc;
  pat_loc  : loc;
}

and pat_desc =
  | Pwild
  | Pvar of ident
  | Papp of qualid * pattern list
  | Prec of (qualid * pattern) list
  | Ptuple of pattern list
  | Por of pattern * pattern
  | Pas of pattern * ident
  | Pcast of pattern * pty

type term = {
  term_desc : term_desc;
  term_loc  : loc;
}

and term_desc =
  | Ttrue
  | Tfalse
  | Tconst of constant
  | Tident of qualid
  | Tidapp of qualid * term list
  | Tapply of term * term
  | Tinfix of term * ident * term
  | Tinnfix of term * ident * term
  | Tbinop of term * binop * term
  | Tunop of unop * term
  | Tif of term * term * term
  | Tquant of quant * binder list * term list list * term
  | Tnamed of label * term
  | Tlet of ident * term * term
  | Tmatch of term * (pattern * term) list
  | Tcast of term * pty
  | Ttuple of term list
  | Trecord of (qualid * term) list
  | Tupdate of term * (qualid * term) list
  | Tat of term * ident

(*s Declarations. *)

type use = {
  use_module : qualid;
  use_import : (bool (* import *) * string (* as *)) option;
}

type clone_subst =
  | CSns    of loc * qualid option * qualid option
  | CStsym  of loc * qualid * ident list * pty
  | CSfsym  of loc * qualid * qualid
  | CSpsym  of loc * qualid * qualid
  | CSvsym  of loc * qualid * qualid
  | CSlemma of loc * qualid
  | CSgoal  of loc * qualid

type field = {
  f_loc     : loc;
  f_ident   : ident;
  f_pty     : pty;
  f_mutable : bool;
  f_ghost   : bool
}

type type_def =
  | TDabstract
  | TDalias     of pty
  | TDalgebraic of (loc * ident * param list) list
  | TDrecord    of field list

type visibility = Public | Private | Abstract (* = Private + ghost fields *)

type invariant = term list

type type_decl = {
  td_loc    : loc;
  td_ident  : ident;
  td_params : ident list;
  td_vis    : visibility; (* records only *)
  td_mut    : bool;       (* records or abstract types *)
  td_inv    : invariant;  (* records only *)
  td_def    : type_def;
}

type logic_decl = {
  ld_loc    : loc;
  ld_ident  : ident;
  ld_params : param list;
  ld_type   : pty option;
  ld_def    : term option;
}

type ind_decl = {
  in_loc    : loc;
  in_ident  : ident;
  in_params : param list;
  in_def    : (loc * ident * term) list;
}

type metarg =
  | Mty  of pty
  | Mfs  of qualid
  | Mps  of qualid
  | Max  of qualid
  | Mlm  of qualid
  | Mgl  of qualid
  | Mstr of string
  | Mint of int

type use_clone = use * clone_subst list option

(* program files *)

type variant = (term * qualid option) list

type pre = term
type post = loc * (pattern * term) list
type xpost = loc * (qualid * pattern * term) list

type spec = {
  sp_pre     : pre list;
  sp_post    : post list;
  sp_xpost   : xpost list;
  sp_reads   : qualid list;
  sp_writes  : term list;
  sp_variant : variant;
  sp_checkrw : bool;
  sp_diverge : bool;
}

type expr = {
  expr_desc : expr_desc;
  expr_loc  : loc;
}

and expr_desc =
  | Etrue
  | Efalse
  | Econst of constant
  (* lambda-calculus *)
  | Eident of qualid
  | Eidapp of qualid * expr list
  | Eapply of expr * expr
  | Einfix of expr * ident * expr
  | Einnfix of expr * ident * expr
  | Elet of ident * ghost * Expr.rs_kind * expr * expr
  | Erec of fundef list * expr
  | Efun of binder list * pty option * spec * expr
  | Eany of param list * pty * spec
  | Etuple of expr list
  | Erecord of (qualid * expr) list
  | Eupdate of expr * (qualid * expr) list
  | Eassign of expr * qualid * expr
  (* control *)
  | Esequence of expr * expr
  | Eif of expr * expr * expr
  | Ewhile of expr * invariant * variant * expr
  | Eand of expr * expr
  | Eor of expr * expr
  | Enot of expr
  | Ematch of expr * (pattern * expr) list
  | Eabsurd
  | Eraise of qualid * expr option
  | Etry of expr * (qualid * pattern option * expr) list
  | Efor of ident * expr * Expr.for_direction * expr * invariant * expr
  (* annotations *)
  | Eassert of Expr.assertion_kind * term
  | Emark of ident * expr
  | Ecast of expr * pty
  | Eghost of expr
  | Enamed of label * expr

and fundef =
  ident * ghost * Expr.rs_kind * binder list * pty option * spec * expr

type decl =
  | Dtype of type_decl list
  | Dlogic of logic_decl list
  | Dind of Decl.ind_sign * ind_decl list
  | Dprop of Decl.prop_kind * ident * term
  | Dmeta of ident * metarg list
  | Dlet of ident * ghost * Expr.rs_kind * expr
  | Drec of fundef list
  | Dexn of ident * pty
