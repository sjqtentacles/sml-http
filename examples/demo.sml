(* demo.sml - build, serialize and parse fixed HTTP/1.1 messages (RFC
   9110/9112) as pure values. Everything is string processing, so the output is
   identical on every run and on both compilers. Wire form uses CRLF line
   endings; for readable, stable output the demo strips the CR before printing
   (the bytes themselves are still proper CRLF). No reals are involved. *)

(* Show wire text with CR removed so each CRLF renders as a single newline. *)
fun wire s = String.translate (fn #"\r" => "" | c => String.str c) s

val getReq =
  { method = "GET", target = "/search?q=ml&lang=sml", version = "HTTP/1.1"
  , headers = Headers.fromList [("Host", "example.com"), ("Accept", "text/html")]
  , body = "" }
val () = print "GET request:\n"
val () = print (wire (Http.serializeRequest getReq))

val postReq = Http.post "/submit" "name=ml&year=2026"
val () = print "\nPOST request (Content-Length set by Http.post):\n"
val () = print (wire (Http.serializeRequest postReq))

val resp = Http.text 200 "Hello, world\n"
val () = print "\n200 response (Http.text):\n"
val () = print (wire (Http.serializeResponse resp))

val () = print "\nParse a request from the wire:\n"
val () =
  case Http.parseRequest "GET /a/b?x=1 HTTP/1.1\r\nHost: h.example\r\n\r\n" of
      SOME r =>
        let val u = Http.targetUri r
        in print ("  method=" ^ #method r ^ " target=" ^ #target r
                  ^ " path=" ^ #path u
                  ^ " query=" ^ (case #query u of SOME q => q | NONE => "")
                  ^ " Host=" ^ (case Headers.get (#headers r) "host" of SOME h => h | NONE => "?")
                  ^ "\n")
        end
    | NONE => print "  <malformed>\n"

val () = print "\nencodeChunked \"Hello, world\":\n"
val () = print (wire (Http.encodeChunked "Hello, world"))
