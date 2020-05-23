#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "libats/SATS/stringbuf.sats"
staload "./../SATS/connection.sats" 
staload "./../SATS/headers.sats" 
staload "./../SATS/response.sats" 
staload "./../SATS/types.sats" 
// staload _ = "prelude/DATS/integer.dats" 

assume Conn = conn_

fn{} isnotnewline(ch: char): bool = ch != '\n' && ch != '\r'

fn{} method_from_string(s: strptr): Option_vt(Method) = res where {
    val () = assertloc(strptr_isnot_null(s))
    val ss = $UNSAFE.castvwtp1{string}(s)
    val res = (case+ 0 of
    | _ when s = "GET" => Some_vt(GET)
    | _ when s = "POST" => Some_vt(POST)
    | _ when s = "HEAD" => Some_vt(HEAD)
    | _ when s = "PUT" => Some_vt(PUT)
    | _ when s = "DELETE" => Some_vt(DELETE)
    | _ => None_vt()): Option_vt(Method)
    val () = free(s)
}

implement{} method_to_string(m) = res where {
    val res = case+ m of
    | GET() => "GET"
    | POST() => "POST"
    | PUT() => "PUT"
    | HEAD() => "HEAD"
    | DELETE() => "DELETE"
}

implement{} make_conn(fd) = conn where {
    val conn = C(_)
    val C(c) = conn
    val () = c.fd := fd
    val () = c.req := stringbuf_make_nil_int(1024)
    val () = c.res := stringbuf_make_nil_int(1024)
    val () = c.path := copy("")
    val () = c.meth := None_vt()
    val () = c.headers := None_vt()
    val () = c.body := copy("")
    val () = c.status := 200
    val () = c.response := make_response()
    prval() = fold@conn
}

implement{} set_status(conn, status) = {
    val+@C(c) = conn
    val () = c.status := status
    prval () = fold@conn
}

implement{} free_conn(conn) = {
    val+~C(c) = conn
    val () = stringbuf_free(c.req)
    val () = stringbuf_free(c.res)
    val () = option_vt_free(c.meth)
    val () = strptr_free(c.path)
    val () = strptr_free(c.body)
    val () = free_response(c.response)
    val () = case+ c.headers of
    | ~Some_vt(headers) => free_headers(headers)
    | ~None_vt() => ()
}

implement{} append_data(conn, buf, s, cnt) = {
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

implement{} parse_conn_from_buffer(conn, buf, s) = {
    val+@C(c) = conn
    val sb = stringbuf_make_nil_int(1024)
    datavtype parse_state = | METHOD | PATH | PROTO | HEADERKEY | HEADERVALUE | HEADERSPACE | NEWLINE | BODY | DONE
    vtypedef state = @{ b=stringbuf, s=parse_state, meth=Option_vt(Method), path=strptr, headerkey=strptr, headers=Headers, body=strptr }
    val h = (case+ c.headers of
    | ~Some_vt(h) => h
    | ~None_vt() => new_headers()): Headers
    var e: state = @{ b=sb, s=METHOD, meth=c.meth, path=c.path, headerkey=copy(""), headers=h, body=c.body }
    val _ = array_foreach_env<byte><state>(buf, i2sz s, e) where {
        implement array_foreach$fwork<byte><state>(b, ev) = {
            val ch = $UNSAFE.cast{int} b
            val ch = int2char0 ch
            val [n:int] ch = g1ofg0(ch)
            val () = case+ ev.s of
            | ~METHOD() => {
                val () = if isspace(ch) then {
                    val-~None_vt() = ev.meth
                    val () = ev.meth := method_from_string(stringbuf_truncout_all(ev.b))
                    val () = ev.s := PATH
                } else {
                    val () = ev.s := METHOD
                    val _ = if char1_isneqz(ch) then stringbuf_insert_char(ev.b, ch) else 0
                }

            }
            | ~PATH() => {
                val () = if isspace(ch) then {
                    val () = free(ev.path)
                    val () = ev.path := stringbuf_truncout_all(ev.b)
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
                    val () = put_header_value(ev.headers, key, line)
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
                    val () = free(ev.body)
                    val () = ev.body := stringbuf_truncout_all(ev.b)
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
    val () = c.meth := e.meth
    val () = c.path := e.path
    val () = c.body := e.body
    val () = c.headers := Some_vt(e.headers)
    val () = free(e.headerkey)
    prval () = fold@conn
}

implement{} parse_conn(conn) = {
    val+@C(c) = conn
    val req = stringbuf_truncout_all(c.req)
    val req = strptr2strnptr(req)
    val () = assertloc(strnptr_length(req) >= 0)
    val sb = stringbuf_make_nil_int(1024)
    datavtype parse_state = | METHOD | PATH | PROTO | HEADERKEY | HEADERVALUE | HEADERSPACE | NEWLINE | BODY | DONE
    vtypedef state = @{ b=stringbuf, s=parse_state, meth=Option_vt(Method), path=strptr, headerkey=strptr, headers=Headers, body=strptr, body_cnt=int, content_length=int0 }
    val h = (case+ c.headers of
    | ~Some_vt(h) => h
    | ~None_vt() => new_headers()): Headers
    var e: state = @{ b=sb, s=METHOD, meth=c.meth, path=c.path, headerkey=copy(""), headers=h, body=c.body, body_cnt=0, content_length=0 }
    val _ = strnptr_foreach_env<state>(req, e) where {
        implement strnptr_foreach$fwork<state>(ch, ev) = {
            val [n:int] ch = g1ofg0(ch)
            val () = case+ ev.s of
            | ~METHOD() => {
                val () = if isspace(ch) then {
                    val-~None_vt() = ev.meth
                    val () = ev.meth := method_from_string(stringbuf_truncout_all(ev.b))
                    val () = ev.s := PATH
                } else {
                    val () = ev.s := METHOD
                    val _ = if char1_isneqz(ch) then stringbuf_insert_char(ev.b, ch) else 0
                }

            }
            | ~PATH() => {
                val () = if isspace(ch) then {
                    val () = free(ev.path)
                    val () = ev.path := stringbuf_truncout_all(ev.b)
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
                    val () = if $UNSAFE.castvwtp1{string}(ev.headerkey) = "Content-Length" then {
                        val () = ev.content_length := $UNSAFE.cast{int}(g0string2int_int($UNSAFE.castvwtp1{string}(line)))
                    }
                    val key = ev.headerkey
                    val () = put_header_value(ev.headers, key, line)
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
                } else {
                    val () = ev.s := BODY
                    val () = ev.body_cnt := ev.body_cnt + 1
                    val _ = if char1_isneqz(ch) then stringbuf_insert_char(ev.b, ch) else 0
                    val () = if ev.content_length = ev.body_cnt then {
                        val-~BODY() = ev.s 
                        val () = ev.s := DONE
                        val () = free(ev.body)
                        val () = ev.body := stringbuf_truncout_all(ev.b)
                    }
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
    val () = c.meth := e.meth
    val () = c.path := e.path
    val () = c.body := e.body
    val () = c.headers := Some_vt(e.headers)
    val () = free(e.headerkey)
    prval () = fold@conn
}