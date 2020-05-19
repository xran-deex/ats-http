#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "libats/SATS/stringbuf.sats"
staload "./../SATS/connection.sats" 
staload "./../SATS/headers.sats" 
staload "./../SATS/types.sats" 

assume Conn = conn_

fn{} isnotnewline(ch: char): bool = ch != '\n' && ch != '\r'

fn{} method_from_string(s: strptr): Option_vt(Method) = res where {
    val () = assertloc(strptr_isnot_null(s))
    val res = (if s = "GET" then Some_vt(GET) else None_vt()): Option_vt(Method)
    val () = free(s)
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
    prval() = fold@conn
}

implement{} free_conn(conn) = {
    val+~C(c) = conn
    val () = stringbuf_free(c.req)
    val () = stringbuf_free(c.res)
    val () = option_vt_free(c.meth)
    val () = strptr_free(c.path)
    val () = case+ c.headers of
    | ~Some_vt(headers) => free_headers(headers)
    | ~None_vt() => ()
}

implement{} parse_conn(conn, buf, s) = {
    val+@C(c) = conn
    val sb = stringbuf_make_nil_int(1024)
    datavtype parse_state = | METHOD | PATH | PROTO | HEADERKEY | HEADERVALUE | NEWLINE
    vtypedef state = @{ b=stringbuf, s=parse_state, meth=Option_vt(Method), path=strptr, headerkey=strptr, headers=Headers }
    val h = (case+ c.headers of
    | ~Some_vt(h) => h
    | ~None_vt() => new_headers()): Headers
    var e: state = @{ b=sb, s=METHOD, meth=c.meth, path=c.path, headerkey=copy(""), headers=h }
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
                    val () = ev.s := HEADERVALUE
                    val line = stringbuf_truncout_all(ev.b)
                    val () = free(ev.headerkey)
                    val () = ev.headerkey := line
                } else {
                    val () = ev.s := HEADERKEY
                    val _ = if char1_isneqz(ch) then stringbuf_insert_char(ev.b, ch) else 0
                }
            }
            | ~HEADERVALUE() => {
                val () = if ch = '\r' then {
                    val () = ev.s := NEWLINE
                    val line = stringbuf_truncout_all(ev.b)
                    val key = ev.headerkey
                    // val () = println!("key: ", key, ", value: ", line)
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
        }
    }
    val () = stringbuf_free(e.b)
    val () = case+ e.s of | ~METHOD() => () | ~PATH() => () | ~PROTO() => () | ~HEADERKEY() => () | ~HEADERVALUE() => () | ~NEWLINE() => ()
    val () = c.meth := e.meth
    val () = c.path := e.path
    val () = c.headers := Some_vt(e.headers)
    val () = free(e.headerkey)
    prval () = fold@conn
}