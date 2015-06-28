let _ =
  let lexbuf = Lexing.from_channel stdin in
  let program = Parser.program Scanner.token lexbuf in
  (*Translate.translate program*)
  let result = Translate.translate program in 
    (List.iter (fun x -> print_string (Translate.string_of_ccode ("", x) )) result)
 
