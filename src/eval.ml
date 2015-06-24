open Ast

let ary = Array.make 10 "0"
(*let hash = Hashtbl.create 100*)



  let rec eval = function 
      Num(x) -> print_string " NUM "; string_of_float x
    | Str(x) -> print_string " STR "; x 
    | Id(x) -> print_string " ID "; x
    | Int(x) -> print_string " Int "; string_of_int x
    | Neg(x) -> string_of_float (-. float_of_string (eval x) ) 
    | Not(x) -> let v1 = eval x in
                if (float_of_string v1) > 0. then string_of_int 0 else string_of_int 1 
    | Assign(e1, e2) -> 
        let v1 = e1 and v2 = eval e2 in
        v1 ^ " Assigned " ^ v2 (*ary.(v1 - 1) <- v2; ary.(v1-1) *)
    | List(e1) -> List.iter (fun x -> print_string (eval x) ) e1; " list"
    | Mem(e1, e2) -> "Mem"
    | Insert(e1) -> 
        let v1 = eval e1 in
        print_string "inserting "; v1
    | Delete(e1) ->
        let v1 = eval e1 in
        print_string "deleting "; v1
    | Query(e1) ->
        let v1 = eval e1 in
        print_string "querying ";  v1
    | Call(e1, e2) -> "call"
    | Binop(e1, op, e2) ->
        let v1 = eval e1 and v2 = eval e2 in
        match op with
  	      Add -> string_of_float (float_of_string (v1) +. float_of_string (v2))
        | Sub -> string_of_float (float_of_string (v1) -. float_of_string (v2))
        | Mul -> string_of_float (float_of_string (v1) *. float_of_string (v2))
        | Div -> string_of_float (float_of_string (v1) /. float_of_string (v2))
        | Equal -> string_of_int ( if v1 = v2 then 1 else 0 )
        | Neq -> string_of_int ( if v1 = v2 then 0 else 1 )
        | Less -> string_of_int ( if v1 < v2 then 1 else 0 )
        | Leq -> string_of_int ( if v1 <= v2 then 1 else 0 )
        | Greater -> string_of_int ( if v1 > v2 then 1 else 0 )
        | Geq -> string_of_int ( if v1 >= v2 then 1 else 0 )
        | Cancat -> v1 ^ v2    

    let rec exec = function
          Expr(e) -> print_string (eval e); "Expr "
        | Block(stmts) -> List.iter (fun x -> print_string "executing ") stmts; "Block"
        | If(e, s1, s2, s3) -> 
          let v = int_of_string (eval e) in 
          exec (if v != 0 then s1 else s3)
	| While(e, s1) ->
          let v = int_of_string (eval e) in 
          (if v != 0 then exec s1 else "skipped")
        (*| Elseif(e, s1) ->
          let v = int_of_string (eval e) in
          exec (if v != 0 then s1)*)



  let _ =
    let lexbuf = Lexing.from_channel stdin in
    let stmt = Parser.stmt Scanner.token lexbuf in
    let result = exec stmt in
    print_endline (result)
