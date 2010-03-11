(**************************************************************************)
(*                                                                        *)
(*  Copyright (C) 2010-                                                   *)
(*    Francois Bobot                                                      *)
(*    Jean-Christophe Filliatre                                           *)
(*    Johannes Kanig                                                      *)
(*    Andrei Paskevich                                                    *)
(*                                                                        *)
(*  This software is free software; you can redistribute it and/or        *)
(*  modify it under the terms of the GNU Library General Public           *)
(*  License version 2.1, with the special exception on linking            *)
(*  described in file LICENSE.                                            *)
(*                                                                        *)
(*  This software is distributed in the hope that it will be useful,      *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                  *)
(*                                                                        *)
(**************************************************************************)

{
  open Lexing
  open Lexer
  open Term
  open Pgm_parser

  let keywords = Hashtbl.create 97
  let () = 
    List.iter 
      (fun (x,y) -> Hashtbl.add keywords x y)
      [ "absurd", ABSURD;
	"and", AND;
	"as", AS;
	"assert", ASSERT;
	"begin", BEGIN;
        "check", CHECK;
	"do", DO;
	"done", DONE;
        "else", ELSE;
	"end", END;
	"exception", EXCEPTION; 
	"for", FOR;
	"fun", FUN;
	"if", IF;
	"in", IN;
	"invariant", INVARIANT;
	"let", LET;
	"match", MATCH;
	"not", NOT;
	"raise", RAISE;
	"raises", RAISES;
	"reads", READS;
	"rec", REC;
	"ref", REF;
	"returns", RETURNS;
	"then", THEN;
	"try", TRY;
	"type", TYPE;
	"variant", VARIANT;
	"void", VOID;
	"while", WHILE;
	"with", WITH;
        "writes", WRITES;
      ]
	
  let update_loc lexbuf file line chars =
    let pos = lexbuf.lex_curr_p in
    let new_file = match file with None -> pos.pos_fname | Some s -> s in
    lexbuf.lex_curr_p <- 
      { pos with
	  pos_fname = new_file;
	  pos_lnum = int_of_string line;
	  pos_bol = pos.pos_cnum - int_of_string chars;
      }

}

let newline = '\n'
let space = [' ' '\t' '\r']
let lalpha = ['a'-'z' '_']
let ualpha = ['A'-'Z']
let alpha = lalpha | ualpha
let digit = ['0'-'9']
let lident = lalpha (alpha | digit | '\'')*
let uident = ualpha (alpha | digit | '\'')*
let decimal_literal =
  ['0'-'9'] ['0'-'9' '_']*
let hex_literal =
  '0' ['x' 'X'] ['0'-'9' 'A'-'F' 'a'-'f']['0'-'9' 'A'-'F' 'a'-'f' '_']*
let oct_literal =
  '0' ['o' 'O'] ['0'-'7'] ['0'-'7' '_']*
let bin_literal =
  '0' ['b' 'B'] ['0'-'1'] ['0'-'1' '_']*
let int_literal =
  decimal_literal | hex_literal | oct_literal | bin_literal
let hexadigit = ['0'-'9' 'a'-'f' 'A'-'F']

rule token = parse
  | "#" space* ("\"" ([^ '\010' '\013' '"' ]* as file) "\"")?
    space* (digit+ as line) space* (digit+ as char) space* "#"
      { update_loc lexbuf file line char; token lexbuf }
  | newline 
      { newline lexbuf; token lexbuf }
  | space+  
      { token lexbuf }
  | '_'
      { UNDERSCORE }
  | lident as id  
      { try Hashtbl.find keywords id with Not_found -> LIDENT id }
  | uident as id  
      { UIDENT id }
  | int_literal as s
      { INTEGER s }
  | (digit+ as i) ("" as f) ['e' 'E'] (['-' '+']? digit+ as e)
  | (digit+ as i) '.' (digit* as f) (['e' 'E'] (['-' '+']? digit+ as e))?
  | (digit* as i) '.' (digit+ as f) (['e' 'E'] (['-' '+']? digit+ as e))?
      { FLOAT (RConstDecimal (i, f, Util.option_map remove_leading_plus e)) }
  | '0' ['x' 'X'] ((hexadigit* as i) '.' (hexadigit+ as f) 
                  |(hexadigit+ as i) '.' (hexadigit* as f)
		  |(hexadigit+ as i) ("" as f))
    ['p' 'P'] (['-' '+']? digit+ as e)
      { FLOAT (RConstHexa (i, f, remove_leading_plus e)) }
  | "(*"
      { comment lexbuf; token lexbuf }
  | "'"
      { QUOTE }
  | ","
      { COMMA }
  | "("
      { LEFTPAR }
  | ")"
      { RIGHTPAR }
  | "!"
      { BANG }
  | ":"
      { COLON }
  | ";"
      { SEMICOLON }
  | ":="
      { COLONEQUAL }
  | "->"
      { ARROW }
  | "="
      { EQUAL }
  | "<>" | "<" | "<=" | ">" | ">=" as s
      { OP0 s }
  | "+" | "-" as c
      { OP2 (String.make 1 c) }
  | "*" | "/" | "%" as c
      { OP3 (String.make 1 c) }
  | "@"
      { AT }
  | "."
      { DOT }
  | "["
      { LEFTSQ }
  | "]"
      { RIGHTSQ }
  | "{"
      { LEFTB }
  | "}"
      { RIGHTB }
  | "{{"
      { LEFTBLEFTB }
  | "}}"
      { RIGHTBRIGHTB }
  | "|"
      { BAR }
  | "||"
      { BARBAR }
  | "&&" 
      { AMPAMP }
  | "=>"
      { BIGARROW }
  | "\""
      { STRING (string lexbuf) }
  | eof 
      { EOF }
  | _ as c
      { raise (Error (IllegalCharacter c)) }

(* and logic = parse *)
(*   | "\"" *)
(*       { let s = Buffer.contents string_buf in *)
(* 	Buffer.clear string_buf;  *)
(* 	s } *)
(*   | "\\" (_ as c) *)
(*       { Buffer.add_char string_buf (char_for_backslash c); string lexbuf } *)
(*   | newline  *)
(*       { newline lexbuf; Buffer.add_char string_buf '\n'; string lexbuf } *)
(*   | eof *)
(*       { raise (Error UnterminatedString) } *)
(*   | _ as c *)
(*       { Buffer.add_char string_buf c; string lexbuf } *)



{

  let loc lb = (lexeme_start_p lb, lexeme_end_p lb)

  let with_location f lb =
    try f lb with e -> raise (Loc.Located (loc lb, e))

  let parse_file = with_location (file token)

}

(*
Local Variables: 
compile-command: "unset LANG; make -C ../.. test"
End: 
*)

