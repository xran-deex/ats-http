#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "./../SATS/types.sats" 
staload "libats/SATS/stringbuf.sats"

datavtype conn_ = C of @{
    fd= int,
    req=stringbuf,
    res=stringbuf,
    meth=Option_vt(Method),
    path=strptr,
    headers=Option_vt(Headers),
    body=strptr,
    status=int,
    response=Resp
}

fn{} make_conn(fd: int): Conn
fn{} free_conn(conn: Conn):<!wrt> void
fn{} parse_conn_from_buffer{n:nat | n > 1}(conn: !Conn, buf: &(@[byte][n]), sz: int(n)): void
fn{} parse_conn(conn: !Conn): void
fn{} append_data{n, x:nat | n > 1 && x <= n}(conn: !Conn, buf: &(@[byte][n]), sz: int(n), cnt: int(x)): void
fn{} method_to_string(m: Method): string
fn{} set_status(conn: !Conn, status: int): void
fn{} set_response(conn: !Conn, body: strptr): void