#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "ats-epoll/ats-epoll.hats"
#include "hashtable-vt/hashtable_vt.hats"
staload "./../SATS/types.sats" 

fn string_from_bytes{n,m:int | m < n && m > 0}(b: @[byte][n], cnt: int(m)): strnptr(m) = "mac#"
fn string_to_bytes{n,m:int | m > n}(b: string(n), buf: @[byte][m], size_t(n)): void = "mac#"
fn string_to_bytes2{n:int}(b: string(n)): bytes(n) = "mac#"
// fn write_err2{n:int}(fd: int, s: string, size_t(n)): int = "mac#"
fn http_write_err
{n:nat}{l:addr | l > null}
(
   pf: !bytes_v(l,n) | fd: int, buf: ptr(l), ntotal: size_t(n)
): ssizeBtw(~1, n) = "mac#" // end-of-fun

fn http_read_err2{n:nat}(fd: int, s: bytes(n), size_t(n)): [m:int | m <= n] int(m) = "mac#http_read_err"
fn http_read_err
{n:nat}{l:addr | l > null}
(
    pf: !bytes_v(l, n) | fd: int, s: ptr(l), size_t(n)): [m:int | m <= n] int(m) = "mac#"
fn reuseport(fd: int): void = "mac#"


datavtype server_ = S of @{
    router= $HT.hashtbl(strptr, (!Req) -<cloptr1> strptr),
    threadCount= [n:nat] int(n),
    threads= List0_vt(lint),
    server_fd= [n:int | n > 0] int(n)
}

fn{} make_server(port: int): Server
fn{} set_thread_count{n:nat}(server: !Server, threads: int(n)): void
fn{} route(server: !Server, path: string): void
fn{} run_server(server: !Server): void
fn{} free_server(server: Server): void
fn{} add_route(server: !Server, route: string, handler: (!Req) -<cloptr1> strptr): void