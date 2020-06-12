#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "ats-epoll/ats-epoll.hats"
#include "hashtable-vt/hashtable_vt.hats"
#include "ats-threadpool/ats-threadpool.hats"
staload "./../SATS/types.sats" 

fn http_write_err
{n:nat}{l:addr | l > null}
(
   pf: !bytes_v(l,n) | fd: int, buf: ptr(l), ntotal: size_t(n)
): ssizeBtw(~1, n) = "ext#"

fn http_read_err
{n:nat}{l:addr | l > null}
(
    pf: !bytes_v(l, n) | fd: int, s: ptr(l), size_t(n)
): [m:int | m <= n] int(m) = "ext#"

fn reuseport(fd: int): void = "ext#"

vtypedef Handler = (!Req,!Resp) -<cloptr1> strptr

datavtype server_ = S of @{
    router= $HT.hashtbl(strptr, ptr),
    threadCount= [n:nat] int(n),
    threads= List0_vt(lint),
    server_fd= [n:int | n > 0] int(n),
    enable_gzip=bool
    // thread_pool=$POOL.Pool
}

fn make_server(port: int): Server
fn set_thread_count{n:nat}(server: !Server, threads: int(n)): void
fn enable_gzip(server: !Server): void
fn route(server: !Server, path: string): void
fn run_server(server: &Server): void
fn free_server(server: Server):<!wrt> void
// fn free_server_(server: Option_vt(server_)):<!wrt> void
fn add_route(server: !Server, method: string, route: string, handler: Handler): void
fn get(server: !Server, route: string, handler: Handler): void
fn post(server: !Server, route: string, handler: Handler): void
fn put(server: !Server, route: string, handler: Handler): void
fn delete(server: !Server, route: string, handler: Handler): void
fn head(server: !Server, route: string, handler: Handler): void