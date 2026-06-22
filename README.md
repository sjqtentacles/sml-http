# sml-http

[![CI](https://github.com/sjqtentacles/sml-http/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-http/actions/workflows/ci.yml)

A pure, I/O-free HTTP/1.1 message model for Standard ML, following
[RFC 9110](https://www.rfc-editor.org/rfc/rfc9110) (semantics) and
[RFC 9112](https://www.rfc-editor.org/rfc/rfc9112) (message syntax). Everything
is a deterministic `input -> output` function over strings; there are no
sockets, threads, or OS calls in the core. That makes the whole thing
reproducible and testable without a network.

Builds and tests identically under **MLton** and **Poly/ML**.

## Features

- **Case-insensitive headers** (`Headers`): order-preserving multimap with
  `get`/`getAll`/`getCombined` (duplicates joined with `, ` per RFC 9110 §5.2),
  plus `add`/`set`/`remove`.
- **Status table** (`Status`): reason phrases and class predicates
  (`isSuccess`, `isRedirect`, `isClientError`, `isServerError`).
- **Request/response records** with parsing and serialization that round-trip
  byte-for-byte.
- **Framing as pure decoders** (`Http`): `Content-Length` and
  `Transfer-Encoding: chunked` decode/encode (RFC 9112 §7.1).
- **URI integration** via vendored [`sml-uri`](https://github.com/sjqtentacles/sml-uri):
  `targetUri` parses a request target into a `Uri.uri`.
- CLI `bin/http` that parses a raw request from stdin.

## API sketch

```sml
type request =
  { method : string, target : string, version : string
  , headers : Headers.headers, body : string }

type response =
  { version : string, status : int, reason : string
  , headers : Headers.headers, body : string }

val parseRequest    : string -> request option
val parseResponse   : string -> response option
val serializeRequest  : request -> string
val serializeResponse : response -> string
val targetUri       : request -> Uri.uri

val text            : int -> string -> response   (* text/plain helper *)
val html            : string -> response          (* 200 text/html *)
val response        : int -> Headers.headers -> string -> response
val redirect        : string -> response          (* 302 Found + Location *)
val redirectWith    : int -> string -> response

(* request builders (version defaults to HTTP/1.1) *)
val get             : string -> request
val delete          : string -> request
val post            : string -> string -> request   (* target body *)
val put             : string -> string -> request   (* target body *)

(* framing *)
val decodeBody      : Headers.headers -> string -> string option
val decodeChunked   : string -> string option
val encodeChunked   : string -> string
```

## Example

```sml
val SOME req = Http.parseRequest "GET /a?b=c HTTP/1.1\r\nHost: x\r\n\r\n"
val "GET"    = #method req
val SOME "x" = Headers.get (#headers req) "host"      (* case-insensitive *)
val [("b","c")] = Uri.queryParams (Http.targetUri req)

val resp = Http.text 200 "hi"
(* "HTTP/1.1 200 OK\r\nContent-Type: text/plain; charset=utf-8\r\n
    Content-Length: 2\r\n\r\nhi" *)
val out  = Http.serializeResponse resp
```

### Request & response builders

Convenience constructors for common messages. Request builders default the
version to `HTTP/1.1`; `post`/`put` set `Content-Length` from the body.
`redirect` produces a `302 Found` with a `Location` header, and `html` a `200`
`text/html` response.

```sml
Http.serializeRequest (Http.get "/a?b=c")          (* "GET /a?b=c HTTP/1.1\r\n\r\n" *)
Http.serializeRequest (Http.post "/submit" "hello")
  (* "POST /submit HTTP/1.1\r\nContent-Length: 5\r\n\r\nhello" *)
Http.serializeResponse (Http.redirect "/new")      (* "...302 Found\r\nLocation: /new\r\n\r\n" *)
Http.serializeResponse (Http.html "<h1>hi</h1>")   (* Content-Type: text/html; charset=utf-8 *)
```

## CLI

```
$ printf 'GET /a?b=c HTTP/1.1\r\nHost: x\r\n\r\n' | ./bin/http parse-req
method: GET
target: /a?b=c
version: HTTP/1.1
header: Host = x
body-bytes: 0
```

## Build

```sh
make test        # MLton
make test-poly   # Poly/ML
make all-tests   # both
make cli         # build bin/http (MLton)
```

**37 deterministic checks**, green under both compilers.

## Installation

Add to your `sml.pkg`:

```
require {
  github.com/sjqtentacles/sml-http
}
```

then `smlpkg sync`, or vendor it under `lib/github.com/sjqtentacles/sml-http/`
and reference its `sml-http.mlb`.

## Layout

```
lib/github.com/sjqtentacles/
  sml-http/
    headers.{sig,sml}   case-insensitive header multimap
    status.{sig,sml}    status codes + reason phrases
    http.{sig,sml}      request/response records, parse/serialize, framing
    sources.mlb sml-http.mlb
  sml-uri/              vendored dependency (committed)
bin/http.{sml,mlb}      CLI
test/                   Harness suite (37 checks)
```

## Vendoring

`sml-uri` is committed under `lib/github.com/sjqtentacles/sml-uri/` so `make`
needs no network. Rebuild the vendored copy with `smlpkg sync` if you bump the
dependency.

## License

MIT. See [LICENSE](LICENSE).
