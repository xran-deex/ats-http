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
    headers=Option_vt(Headers)
}

fn{} make_conn(fd: int): Conn
fn{} free_conn(conn: Conn):<!wrt> void
fn{} parse_conn{n:nat | n > 1}(conn: !Conn, buf: &(@[byte][n]), sz: int(n)): void