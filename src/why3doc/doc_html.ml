(********************************************************************)
(*                                                                  *)
(*  The Why3 Verification Platform   /   The Why3 Development Team  *)
(*  Copyright 2010-2013   --   INRIA - CNRS - Paris-Sud University  *)
(*                                                                  *)
(*  This software is distributed under the terms of the GNU Lesser  *)
(*  General Public License version 2.1, with the special exception  *)
(*  on linking described in file LICENSE.                           *)
(*                                                                  *)
(********************************************************************)

open Format

let print_header fmt ?(title="") ?css () =
  fprintf fmt "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\"@\n\"http://www.w3.org/TR/html4/strict.dtd\">@\n<html>@\n<head>@\n<meta http-equiv=\"Content-Type\" content=\"text/html;charset=utf-8\">@\n";
  begin match css with
    | None -> ()
    | Some f -> fprintf fmt
        "<link rel=\"stylesheet\" href=\"%s\" type=\"text/css\">@\n" f
  end;
  fprintf fmt "<title>%s</title>@\n" title;
  fprintf fmt "</head>@\n<body>@\n"

let print_footer fmt () =
  fprintf fmt "<hr>@\n<p>Generated by why3doc %s</p>@\n</body>@\n</html>@."
    Why3.Config.version

let style_css fname =
  let c = open_out fname in
  output_string c
"
.why3doc a:visited {color : #416DFF; text-decoration : none; }
.why3doc a:link {color : #416DFF; text-decoration : none;}
.why3doc a:hover {color : Red; text-decoration : none; background-color: #5FFF88}
.why3doc a:active {color : Red; text-decoration : underline; }
.why3doc .comment { color : #990000 }
.why3doc .keyword1 { color : purple; font-weight : bold }
.why3doc .keyword2 { color : blue; font-weight : bold }
.why3doc .superscript { font-size : 4 }
.why3doc .subscript { font-size : 4 }
.why3doc .warning { color : Red ; font-weight : bold }
.why3doc .info { margin-left : 3em; margin-right : 3em }
.why3doc .code { color : #465F91 ; }
.why3doc h1 { font-size : 20pt ; border: 1px solid #000000; margin-top: 10px; margin-bottom: 10px;text-align: center; background-color: #90BDFF ;padding: 10px; }
.why3doc h2 { font-size : 18pt ; border: 1px solid #000000; margin-top: 8px; margin-bottom: 8px;text-align: left; background-color: #90DDFF ;padding: 8px; }
.why3doc h3 { font-size : 16pt ; border: 1px solid #000000; margin-top: 6px; margin-bottom: 6px;text-align: left; background-color: #90EDFF ;padding: 6px; }
.why3doc h4 { font-size : 14pt ; border: 1px solid #000000; margin-top: 4px; margin-bottom: 4px;text-align: left; background-color: #90FDFF ;padding: 4px; }
.why3doc h5 { font-size : 12pt ; border: 1px solid #000000; margin-top: 2px; margin-bottom: 2px;text-align: left; background-color: #90BDFF ; padding: 2px; }
.why3doc h6 { font-size : 10pt ; border: 1px solid #000000; margin-top: 0px; margin-bottom: 0px;text-align: left; background-color: #90BDFF ; padding: 0px; }
.why3doc .typetable { border-style : hidden }
.why3doc .indextable { border-style : hidden }
.why3doc .paramstable { border-style : hidden ; padding: 5pt 5pt}
.why3doc body { background-color : White }
.why3doc tr { background-color : White }
.why3doc td.typefieldcomment { background-color : #FFFFFF }
.why3doc pre { margin-top: 1px ; margin-bottom: 2px; }
.why3doc div.sig_block {margin-left: 2em}";
  close_out c

