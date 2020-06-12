#include "./../HATS/includes.hats"
staload "./../SATS/connection.sats" 
staload "./../SATS/headers.sats" 
staload "./../SATS/response.sats" 
staload REQ = "./../SATS/request.sats" 
staload "./../SATS/types.sats" 
staload _ = "./../DATS/request.dats"
staload _ = "./../DATS/response.dats"
#define ATS_DYNLOADFLAG 0

assume Conn = conn_

#define BUFSZ 2048

fn isnotnewline(ch: char): bool = ch != '\n' && ch != '\r'

fn method_from_string(s: strptr): Method = res where {
    val () = assertloc(strptr_isnot_null(s))
    val ss = $UNSAFE.castvwtp1{string}(s)
    val res = (case+ 0 of
    | _ when s = "GET" => GET
    | _ when s = "POST" => POST
    | _ when s = "HEAD" => HEAD
    | _ when s = "PUT" => PUT
    | _ when s = "DELETE" => DELETE
    | _ => $raise GenerallyExn("Unable to parse method")): Method
    val () = free(s)
}

implement method_to_string(m) = res where {
    val res = case+ m of
    | GET() => "GET"
    | POST() => "POST"
    | PUT() => "PUT"
    | HEAD() => "HEAD"
    | DELETE() => "DELETE"
}

implement make_conn(fd) = conn where {
    val conn = C(_)
    val C(c) = conn
    val () = c.fd := fd
    val () = c.req := stringbuf_make_nil_int(1024)
    val () = c.res := stringbuf_make_nil_int(1024)
    val () = c.request := $REQ.make_empty_req()
    val () = c.status := 200
    val () = c.response := make_response()
    prval() = fold@conn
}

implement set_status(conn, status) = {
    val+@C(c) = conn
    val () = c.status := status
    prval () = fold@conn
}

implement free_conn(conn) = {
    val () = case+ conn of
    | ~Some_vt(conn) => {
        val+~C(c) = conn
        val () = stringbuf_free(c.req)
        val () = stringbuf_free(c.res)
        val () = $REQ.free_request(c.request)
        val () = free_response(c.response)
    }
    | ~None_vt() => ()
}

implement append_data(conn, buf, s, cnt) = {
    val+@C(c) = conn
    vtypedef state = @{ b=stringbuf, i = int }
    var e: state = @{ b=c.req, i = 0 }
    val _ = array_foreach_env<byte><state>(buf, i2sz s, e) where {
        implement array_foreach$fwork<byte><state>(b, ev) = {
            val ch = $UNSAFE.cast{int} b
            val ch = int2char0 ch
            val [n:int] ch = g1ofg0(ch)
            val () = if ev.i < cnt then if char1_isneqz(ch) then {
                val _ = stringbuf_insert_char(ev.b, ch)
            }
            val () = ev.i := ev.i + 1
        }
    }
    val () = c.req := e.b
    prval () = fold@conn
}

implement parse_conn_from_buffer(conn, buf, s) = {
    val+@C(c) = conn
    val sb = stringbuf_make_nil_int(1024)
    datavtype parse_state = | METHOD | PATH | PROTO | HEADERKEY | HEADERVALUE | HEADERSPACE | NEWLINE | BODY | DONE
    vtypedef state = @{ b=stringbuf, s=parse_state, request=Req, headerkey=strptr }
    var e: state = @{ b=sb, s=METHOD, request=c.request, headerkey=copy("") }
    val _ = array_foreach_env<byte><state>(buf, i2sz s, e) where {
        implement array_foreach$fwork<byte><state>(b, ev) = {
            val ch = $UNSAFE.cast{int} b
            val ch = int2char0 ch
            val [n:int] ch = g1ofg0(ch)
            val () = case+ ev.s of
            | ~METHOD() => {
                val () = if isspace(ch) then {
                    val () = $REQ.set_method(ev.request, method_from_string(stringbuf_truncout_all(ev.b)))
                    val () = ev.s := PATH
                } else {
                    val () = ev.s := METHOD
                    val _ = if char1_isneqz(ch) then stringbuf_insert_char(ev.b, ch) else 0
                }

            }
            | ~PATH() => {
                val () = if isspace(ch) then {
                    val () = $REQ.set_path(ev.request, stringbuf_truncout_all(ev.b))
                    val () = ev.s := PROTO
                } else {
                    val () = ev.s := PATH
                    val _ = if char1_isneqz(ch) then stringbuf_insert_char(ev.b, ch) else 0
                }
            }
            | ~PROTO() => {
                val () = if ch = '\r' then {
                    val () = free(stringbuf_truncout_all(ev.b))
                    val () = ev.s := NEWLINE
                } else {
                    val () = ev.s := PROTO
                    val _ = if char1_isneqz(ch) then stringbuf_insert_char(ev.b, ch) else 0
                }
            }
            | ~HEADERKEY() => {
                val () = if ch = ':' then {
                    val () = ev.s := HEADERSPACE
                    val line = stringbuf_truncout_all(ev.b)
                    val () = free(ev.headerkey)
                    val () = ev.headerkey := line
                } else if ch = '\r' then {
                    val () = ev.s := BODY
                } else {
                    val () = ev.s := HEADERKEY
                    val _ = if char1_isneqz(ch) then stringbuf_insert_char(ev.b, ch) else 0
                }
            }
            | ~HEADERSPACE() => {
                val () = ev.s := HEADERVALUE
            }
            | ~HEADERVALUE() => {
                val () = if ch = '\r' then {
                    val () = ev.s := NEWLINE
                    val line = stringbuf_truncout_all(ev.b)
                    val key = ev.headerkey
                    val () = $REQ.add_header_value(ev.request, key, line)
                    val () = ev.headerkey := copy("")
                } else {
                    val () = ev.s := HEADERVALUE
                    val _ = if char1_isneqz(ch) then stringbuf_insert_char(ev.b, ch) else 0
                }
            }
            | ~NEWLINE() => {
                val () = ev.s := HEADERKEY
            }
            | ~BODY() => {
                val () = if ch = '\n' then {
                    val () = ev.s := BODY
                } else if char1_iseqz(ch) then {
                    val () = ev.s := DONE
                    val () = $REQ.set_body(ev.request, stringbuf_truncout_all(ev.b))
                } else {
                    val () = ev.s := BODY
                    val _ = if char1_isneqz(ch) then stringbuf_insert_char(ev.b, ch) else 0
                }
            }
            | ~DONE() => {
                val () = ev.s := DONE
            }
        }
    }
    val () = stringbuf_free(e.b)
    val () = case+ e.s of | ~METHOD() => () | ~PATH() => () | ~PROTO() => () | ~HEADERKEY() => () | ~HEADERVALUE() => () | ~HEADERSPACE() => () | ~NEWLINE() => () | ~BODY() => () | ~DONE() => ()
    val () = c.request := e.request
    val () = free(e.headerkey)
    prval () = fold@conn
}

implement parse_conn(conn) = {
    val+@C(c) = conn
    val req = stringbuf_truncout_all(c.req)
    val req = strptr2strnptr(req)
    val () = assertloc(strnptr_length(req) >= 0)
    val sb = stringbuf_make_nil_int(1024)
    datavtype parse_state = | METHOD | PATH | PROTO | HEADERKEY | HEADERVALUE | HEADERSPACE | NEWLINE | BODY | DONE
    vtypedef state = @{ b=stringbuf, s=parse_state, request=Req, headerkey=strptr }
    var e: state = @{ b=sb, s=METHOD, request=c.request, headerkey=copy("") }
    val _ = strnptr_foreach_env<state>(req, e) where {
        implement strnptr_foreach$fwork<state>(ch, ev) = {
            val [n:int] ch = g1ofg0(ch)
            val () = case+ ev.s of
            | ~METHOD() => {
                val () = if isspace(ch) then {
                    val () = $REQ.set_method(ev.request, method_from_string(stringbuf_truncout_all(ev.b)))
                    val () = ev.s := PATH
                } else {
                    val () = ev.s := METHOD
                    val _ = if char1_isneqz(ch) then stringbuf_insert_char(ev.b, ch) else 0
                }

            }
            | ~PATH() => {
                val () = if isspace(ch) then {
                    val () = $REQ.set_path(ev.request, stringbuf_truncout_all(ev.b))
                    val () = ev.s := PROTO
                } else {
                    val () = ev.s := PATH
                    val _ = if char1_isneqz(ch) then stringbuf_insert_char(ev.b, ch) else 0
                }
            }
            | ~PROTO() => {
                val () = if ch = '\r' then {
                    val () = free(stringbuf_truncout_all(ev.b))
                    val () = ev.s := NEWLINE
                } else {
                    val () = ev.s := PROTO
                    val _ = if char1_isneqz(ch) then stringbuf_insert_char(ev.b, ch) else 0
                }
            }
            | ~HEADERKEY() => {
                val () = if ch = ':' then {
                    val () = ev.s := HEADERSPACE
                    val line = stringbuf_truncout_all(ev.b)
                    val () = free(ev.headerkey)
                    val () = ev.headerkey := line
                } else if ch = '\r' then {
                    val () = ev.s := BODY
                } else {
                    val () = ev.s := HEADERKEY
                    val _ = if char1_isneqz(ch) then stringbuf_insert_char(ev.b, ch) else 0
                }
            }
            | ~HEADERSPACE() => {
                val () = ev.s := HEADERVALUE
            }
            | ~HEADERVALUE() => {
                val () = if ch = '\r' then {
                    val () = ev.s := NEWLINE
                    val line = stringbuf_truncout_all(ev.b)
                    val key = ev.headerkey
                    val () = $REQ.add_header_value(ev.request, key, line)
                    val () = ev.headerkey := copy("")
                } else {
                    val () = ev.s := HEADERVALUE
                    val _ = if char1_isneqz(ch) then stringbuf_insert_char(ev.b, ch) else 0
                }
            }
            | ~NEWLINE() => {
                val () = ev.s := HEADERKEY
            }
            | ~BODY() => {
                val () = if ch = '\n' then {
                    val () = ev.s := BODY
                } else if char1_iseqz(ch) then {
                    val () = ev.s := DONE
                    val () = $REQ.set_body(ev.request, stringbuf_truncout_all(ev.b))
                } else {
                    val () = ev.s := BODY
                    val _ = if char1_isneqz(ch) then stringbuf_insert_char(ev.b, ch) else 0
                }
            }
            | ~DONE() => {
                val () = ev.s := DONE
            }
        }
    }
    val () = free(req)
    val () = stringbuf_free(e.b)
    val () = case+ e.s of | ~METHOD() => () | ~PATH() => () | ~PROTO() => () | ~HEADERKEY() => () | ~HEADERVALUE() => () | ~HEADERSPACE() => () | ~NEWLINE() => () | ~BODY() => () | ~DONE() => ()
    val () = c.request := e.request
    val () = free(e.headerkey)
    prval () = fold@conn
}

implement clear_request_buffer(conn) = {
    val+@C(c) = conn
    val () = free(stringbuf_takeout_all(c.req))
    prval () = fold@conn
}

implement clear_response_buffer(conn) = {
    val+@C(c) = conn
    val () = free(stringbuf_takeout_all(c.res))
    prval () = fold@conn
}

implement call_handler(conn, func) = res where {
    val+@C(c) = conn
    val res = func(c.request, c.response)
    prval () = $UNSAFE.cast2void(func)
    prval () = fold@conn
}

implement get_routing_key(conn) = key where {
    val+@C(c) = conn
    val key = string0_append(method_to_string($REQ.get_method(c.request)), $REQ.get_path(c.request))
    prval () = fold@conn
}

fn add_content_type(sb: !stringbuf, ty: string): int = let
    val _ = stringbuf_insert_string(sb, "Content-Type: ")
    val _ = stringbuf_insert_string(sb, ty)
in
    stringbuf_insert_string(sb, "\r\n")
end

fn add_keep_alive(sb: !stringbuf): int =
    stringbuf_insert_string(sb, "Connection: Keep-Alive\r\n")

fn add_http_1_1(sb: !stringbuf): int =
    stringbuf_insert_string(sb, "HTTP/1.1 ")

fn add_200(sb: !stringbuf): int =
    stringbuf_insert_string(sb, "200 OK\r\n")

fn add_status_code(sb: !stringbuf, code: int): int = res where {
    val res = stringbuf_insert_int(sb, code)
    val res = case+ code of
    | 200 => stringbuf_insert_string(sb, " OK\r\n")
    | 404 => stringbuf_insert_string(sb, " NOT FOUND\r\n")
    | 500 => stringbuf_insert_string(sb, " INTERNAL SERVER ERROR\r\n")
    | _ => stringbuf_insert_string(sb, " UNKNOWN\r\n")
}

fn add_gzip(sb: !stringbuf): int =
    stringbuf_insert_string(sb, "Content-Encoding: deflate\r\n")

fn add_content_length(sb: !stringbuf, content: !strptr): int = let
    val contentLen = strptr_length(content)
    val _ = stringbuf_insert_string(sb, "Content-Length: ")
    val _ = stringbuf_insert_int(sb, $UNSAFE.cast{int}contentLen)
in
    stringbuf_insert_string(sb, "\r\n")
end

fn add_content_length_from_int(sb: !stringbuf, contentLen: int): int = let
    val _ = stringbuf_insert_string(sb, "Content-Length: ")
    val _ = stringbuf_insert_int(sb, contentLen)
in
    stringbuf_insert_string(sb, "\r\n")
end

fn finish_headers(sb: !stringbuf): int =
    stringbuf_insert_string(sb, "\r\n")

fn add_content(sb: !stringbuf, content: strptr): void = let
    val _ = stringbuf_insert_string(sb, $UNSAFE.castvwtp1{string}(content))
in
    free(content)
end

fn add_content_gzip(sb: !stringbuf, content: !strptr, sz: int): void = {
    val [n:int] size = $UNSAFE.cast{[n:int]size_t(n)}(sz)
    val c = $UNSAFE.castvwtp1{string(n)}(content)
    val _ = stringbuf_insert_strlen(sb, c, size)
}

fn compress_content(content: strptr, compressed: !ptr, sz: int): int = res where {
    var destLen: lint = g0int2int_int_lint BUFSZ
    val result = $LIBZ.compress(compressed, destLen, $UNSAFE.castvwtp1{ptr}content, g0int2int_int_lint sz)
    val () = free(content)
    val res = $UNSAFE.cast{int}destLen
}

implement create_response(conn, res) = {
    val+@C(c) = conn
    val _ = add_http_1_1(c.res)
    val _ = add_status_code(c.res, get_status_code(c.response))
    val _ = add_content_type(c.res, get_content_type(c.response))
    val _ = add_keep_alive(c.res)
    val _ = add_content_length(c.res, res)
    val _ = finish_headers(c.res)
    val () = add_content(c.res, res)
    prval () = fold@conn
}

implement create_response_gzip(conn, res) = {
    val+@C(c) = conn
    val _ = add_http_1_1(c.res)
    val _ = add_status_code(c.res, get_status_code(c.response))
    val _ = add_content_type(c.res, get_content_type(c.response))
    val _ = add_keep_alive(c.res)
    val _ = add_gzip(c.res)
    var bufs = @[byte][1024](int2byte0 0)
    val cnt = compress_content(res, $UNSAFE.cast{ptr}bufs, $UNSAFE.cast{int}(strptr_length(res)))
    val str = $UNSAFE.castvwtp1{strptr}(bufs)
    val _ = add_content_length_from_int(c.res, cnt)
    val _ = finish_headers(c.res)
    val () = add_content_gzip(c.res, str, cnt)
    // stack allocated byte array
    prval() = $UNSAFE.cast2void(str)
    prval () = fold@conn
}

implement get_buffer(conn, size) = res where {
    val+@C(c) = conn
    val res = stringbuf_takeout_strbuf(c.res, size)
    prval () = fold@conn
}