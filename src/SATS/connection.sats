#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "./../SATS/types.sats" 
staload "./../SATS/http.sats" 
staload "libats/SATS/stringbuf.sats"

datavtype conn_ = C of @{
    fd= int,
    req=stringbuf,
    res=stringbuf,
    status=int,
    request=Req,
    response=Resp
}

fn make_conn(fd: int): Conn
fn free_conn(conn: Option_vt(Conn)):<!wrt> void
fn parse_conn_from_buffer{n:nat | n > 1}(conn: !Conn, buf: &(@[byte][n]), sz: int(n)): void
fn parse_conn(conn: !Conn): void
fn append_data{n, x:nat | n > 1 && x <= n}(conn: !Conn, buf: &(@[byte][n]), sz: int(n), cnt: int(x)): void
fn method_to_string(m: Method): string
fn set_status(conn: !Conn, status: int): void
fn set_response(conn: !Conn, body: strptr): void
fn clear_request_buffer(conn: !Conn): void
fn clear_response_buffer(conn: !Conn): void
fn call_handler(conn: !Conn, handler: Handler): strptr
fn get_routing_key(conn: !Conn): strptr
fn create_response(conn: !Conn, content: strptr): void
fn create_response_gzip(conn: !Conn, content: strptr): void
fn get_buffer(conn: !Conn, s: &size_t? >> size_t(n)):<!wrt> #[l:addr;n:nat] (bytes_v(l,n), bytes_v(l, n) -<lin,prf> void | ptr(l))