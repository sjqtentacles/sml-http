(* Tests for sml-http. *)

structure HttpTests =
struct
  open Harness

  fun run () =
    let
      val () = section "headers (case-insensitive)"
      val h = Headers.fromList [("Host", "x"), ("Set-Cookie", "a=1"), ("Set-Cookie", "b=2")]
      val () = checkBool "get case-insensitive" (true, Headers.get h "host" = SOME "x")
      val () = checkBool "get exact case" (true, Headers.get h "Host" = SOME "x")
      val () = checkBool "missing" (true, Headers.get h "Accept" = NONE)
      val () = checkBool "getAll duplicates" (true, Headers.getAll h "set-cookie" = ["a=1", "b=2"])
      val () = checkBool "getCombined" (true, Headers.getCombined h "set-cookie" = SOME "a=1, b=2")
      val () = checkBool "has" (true, Headers.has h "HOST")
      val () = checkBool "add appends"
                 (true, Headers.getAll (Headers.add h "X" "1") "x" = ["1"])
      val () = checkBool "set replaces"
                 (true, Headers.getAll (Headers.set h "Set-Cookie" "z=9") "set-cookie" = ["z=9"])
      val () = checkBool "remove"
                 (true, Headers.get (Headers.remove h "Host") "host" = NONE)

      val () = section "status table"
      val () = checkString "200" ("OK", Status.reason 200)
      val () = checkString "404" ("Not Found", Status.reason 404)
      val () = checkString "418" ("I'm a teapot", Status.reason 418)
      val () = checkString "unknown" ("Unknown", Status.reason 299)
      val () = checkString "line" ("404 Not Found", Status.line 404)
      val () = checkBool "isSuccess 204" (true, Status.isSuccess 204)
      val () = checkBool "isServerError 503" (true, Status.isServerError 503)
      val () = checkBool "isRedirect 301" (true, Status.isRedirect 301)
      val () = checkBool "isClientError 400" (true, Status.isClientError 400)

      val () = section "request parsing"
      val req = valOf (Http.parseRequest "GET /a?b=c HTTP/1.1\r\nHost: x\r\nAccept: */*\r\n\r\n")
      val () = checkString "method" ("GET", #method req)
      val () = checkString "target" ("/a?b=c", #target req)
      val () = checkString "version" ("HTTP/1.1", #version req)
      val () = checkBool "header host" (true, Headers.get (#headers req) "host" = SOME "x")
      val () = checkBool "uri path" (true, #path (Http.targetUri req) = "/a")
      val () = checkBool "uri query" (true, Uri.queryParams (Http.targetUri req) = [("b","c")])

      val () = section "request with body"
      val req2 = valOf (Http.parseRequest "POST /submit HTTP/1.1\r\nContent-Length: 5\r\n\r\nhello")
      val () = checkString "body" ("hello", #body req2)
      val () = checkBool "decodeBody content-length"
                 (true, Http.decodeBody (#headers req2) (#body req2) = SOME "hello")

      val () = section "request serialize round-trip"
      val msg = "GET / HTTP/1.1\r\nHost: example.com\r\n\r\n"
      val () = checkString "round-trip"
                 (msg, Http.serializeRequest (valOf (Http.parseRequest msg)))

      val () = section "response"
      val resp = Http.text 200 "hi"
      val () = checkString "serialize text response"
                 ("HTTP/1.1 200 OK\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: 2\r\n\r\nhi",
                  Http.serializeResponse resp)
      val respParsed = valOf (Http.parseResponse "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n")
      val () = checkInt "parsed status" (404, #status respParsed)
      val () = checkString "parsed reason" ("Not Found", #reason respParsed)

      val () = section "chunked transfer-coding"
      (* "Wikipedia in\r\n\r\nchunks." style example, simplified *)
      val chunkedMsg = "4\r\nWiki\r\n5\r\npedia\r\n0\r\n\r\n"
      val () = checkBool "decodeChunked" (true, Http.decodeChunked chunkedMsg = SOME "Wikipedia")
      val () = checkBool "decodeChunked empty" (true, Http.decodeChunked "0\r\n\r\n" = SOME "")
      val () = checkBool "encode/decode chunked round-trip"
                 (true, Http.decodeChunked (Http.encodeChunked "Hello, chunked world!") = SOME "Hello, chunked world!")
      val () = checkBool "decodeBody honors Transfer-Encoding chunked"
                 (true, Http.decodeBody (Headers.fromList [("Transfer-Encoding", "chunked")]) chunkedMsg = SOME "Wikipedia")
      (* chunk extension on the size line is ignored *)
      val () = checkBool "chunk extension ignored"
                 (true, Http.decodeChunked "4;ext=1\r\nWiki\r\n0\r\n\r\n" = SOME "Wiki")

      val () = section "malformed input"
      val () = checkBool "bad start line" (true, not (isSome (Http.parseRequest "garbage\r\n\r\n")))
      val () = checkBool "non-numeric status" (true, not (isSome (Http.parseResponse "HTTP/1.1 abc X\r\n\r\n")))
    in
      ()
    end
end
