(* bin/http.sml -- MLton CLI for sml-http.

   Reads a raw HTTP request from stdin and prints its parsed components.
   Usage: http parse-req  < request.txt *)

fun readAll () =
  let
    fun loop acc =
      case TextIO.inputLine TextIO.stdIn of
          NONE => String.concat (List.rev acc)
        | SOME l => loop (l :: acc)
  in
    loop []
  end

fun pr s = print (s ^ "\n")

fun showReq (r : Http.request) =
  ( pr ("method: " ^ #method r)
  ; pr ("target: " ^ #target r)
  ; pr ("version: " ^ #version r)
  ; List.app (fn (k, v) => pr ("header: " ^ k ^ " = " ^ v)) (Headers.toList (#headers r))
  ; pr ("body-bytes: " ^ Int.toString (String.size (#body r))) )

fun main () =
  case CommandLine.arguments () of
      ["parse-req"] =>
        (case Http.parseRequest (readAll ()) of
             SOME r => showReq r
           | NONE => (TextIO.output (TextIO.stdErr, "parse error\n");
                      OS.Process.exit OS.Process.failure))
    | _ =>
        (TextIO.output (TextIO.stdErr, "usage: http parse-req < request.txt\n");
         OS.Process.exit OS.Process.failure)

val () = main ()
