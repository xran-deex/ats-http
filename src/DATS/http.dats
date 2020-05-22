#include "./../HATS/includes.hats"
staload "./../SATS/http.sats"
staload "./../SATS/headers.sats"
staload "./../SATS/types.sats" 
staload "./../SATS/request.sats" 
staload "./../SATS/connection.sats" 
#define ATS_DYNLOADFLAG 0

staload "libats/DATS/stringbuf.dats"
assume stringbuf_vtype = stringbuf

assume Server = shared(server_)
assume Conn = conn_
assume Headers = headers_
assume Req = req_

fn{} get_server(port: int): [n:int|n>= ~1] int(n) = res where {
    val inport = in_port_nbo(port)
    val inaddr = in_addr_hbo2nbo (INADDR_ANY)
    //
    var servaddr: sockaddr_in_struct
    val () = sockaddr_in_init(servaddr, AF_INET, inaddr, inport)
    val (pf | sfd) = socket_AF_type_exn(AF_INET, SOCK_STREAM)
    val () = reuseport(sfd)
    val () = $extfcall(void, "atslib_libats_libc_bind_exn", sfd, addr@servaddr, socklen_in) 
    prval() = __assert(pf) where {
        extern praxi __assert{fd:int}(pf: socket_v(fd,init)): void
    }
    val res = sfd
}

fn{} listen{n:int|n>=0}(sfd: int(n)): void = {
    val _ = setnonblocking(sfd)
    val () = $extfcall(void, "atslib_libats_libc_listen_exn", sfd, SOMAXCONN) 
}

#define BUFSZ 100

fn{} add_content_type(sb: !stringbuf): int =
    stringbuf_insert_string(sb, "Content-Type: text/html\r\n")
fn{} add_keep_alive(sb: !stringbuf): int =
    stringbuf_insert_string(sb, "Connection: Keep-Alive\r\n")
fn{} add_http_1_1(sb: !stringbuf): int =
    stringbuf_insert_string(sb, "HTTP/1.1 ")
fn{} add_200(sb: !stringbuf): int =
    stringbuf_insert_string(sb, "200 OK\r\n")
fn{} add_content_length(sb: !stringbuf, content: !strptr): int = let
    val contentLen = strptr_length(content)
    val _ = stringbuf_insert_string(sb, "Content-Length: ")
    val _ = stringbuf_insert_int(sb, $UNSAFE.cast{int}contentLen)
in
    stringbuf_insert_string(sb, "\r\n")
end
fn{} finish_headers(sb: !stringbuf): int =
    stringbuf_insert_string(sb, "\r\n")
fn{} add_content(sb: !stringbuf, content: strptr): void = let
    val _ = stringbuf_insert_string(sb, $UNSAFE.castvwtp1{string}(content))
in
    free(content)
end
fn{} write_response(sb: !stringbuf, fd: int): int = ret where {
    var size: size_t?
    val (pf, pff | buf) = stringbuf_takeout_strbuf(sb, size)
    val () = assertloc(size >= 0)
    val () = assertloc(ptr_isnot_null buf)
    val ret = http_write_err(pf | fd, buf, size)
    val ret = $UNSAFE.cast{int}ret
    prval () = pff(pf)
}

// HACK - read into an existing stringbuf from a file descriptor
fn
{}(*tmp*)
stringbuf_insert_read
{n:nat}
  (sbf: !stringbuf, inp: int, nb: size_t(n)): int = let
//
val+@STRINGBUF(A, p, m) = sbf
//
val n = $UN.cast{size_t}(p - ptrcast(A))
//
val nb = g1ofg0(nb)
val nb =
(
  if nb > 0 then min(nb, m - n) else (m - n)
) : size_t
val [nb:int] nb = g1ofg0(nb)
//
val
(
  pf, fpf | p1
) = $UN.ptr0_vtake{bytes(nb)}(p)
val () = assertloc(ptr_isnot_null(p1))
val nread = http_read_err(pf | inp, p1, nb)
val ((*void*)) = (p := ptr_add<char>(p, nread))
//
prval () = fpf(pf)
prval () = fold@(sbf)
//
in
  nread
end // end of [stringbuf_insert_fread]

fun{} do_read(e: !Epoll, w: !Watcher, evs: uint): void = () where {
    val fd = watcher_get_fd(w)
    // val () = println!(athread_self())
    // val () = println!("Processing... ", fd)
    val isedge = (evs land EPOLLET) > 0
    val isread = (evs land EPOLLIN) > 0
    val iswrite = (evs land EPOLLOUT) > 0
    val iserr = (evs land EPOLLERR) > 0
    val isclose = (evs land (EPOLLRDHUP lor EPOLLHUP)) > 0
    // val () = println!("read: ", isread, ", write: ", iswrite, ", close: ", isclose, ", edge: ", isedge, ", error: ", iserr)
    val () = if isread && ~iserr then {
        fun loop(e: !Epoll, w: !Watcher): void = {
            // val () = println!("fd: ", fd)
            var buf = @[byte][BUFSZ](int2byte0 0)
            val num_read = http_read_err2(fd, buf, i2sz (BUFSZ))

            val () = if num_read <= 0 then {
                val (pf | opt) = watcher_data_takeout<Conn>(w)
                val-~Some_vt(conn) = opt
                val () = parse_conn(conn)
                // val () = parse_conn_from_buffer(conn, buf, BUFSZ)
                val+C(c) = conn
                val (pf2 | opt) = epoll_data_takeout<Server>(e)
                val-~Some_vt(serve) = opt
                val (pfs | server) = shared_lock(serve)
                val+@S(s) = server
                val+@C(c) = conn
                val req = stringbuf_takeout_all(c.req)
                val () = free(req)
                val-@Some_vt(headers) = c.headers
                var meth = (case+ c.meth of
                | ~Some_vt(meth) => meth
                | ~None_vt() => GET): Method
                val ptr = $HT.hashtbl_search_ref(s.router, c.path)
                val func = (if ptr != 0 then $UNSAFE.castvwtp1{Handler}($UNSAFE.cptr_get<ptr>(ptr)) else (lam req =<cloptr1> copy("error"))): Handler
                val req = make_req(headers, c.path, meth, c.body)
                val res = func(req)
                val () = if ptr = 0 then {
                    val () = cloptr_free($UNSAFE.castvwtp0{cloptr(void)}func)
                } else {
                    prval () = $UNSAFE.cast2void(func)
                }
                val+~R(r) = req
                val () = headers := r.headers
                val () = meth := r.method
                val () = c.meth := Some_vt(meth)
                val () = c.path := r.path
                val () = c.body := r.body
                prval() = fold@(c.headers)

                val _ = add_http_1_1(c.res)
                val _ = add_200(c.res)
                val _ = add_content_type(c.res)
                val _ = add_keep_alive(c.res)
                val _ = add_content_length(c.res, res)
                val _ = finish_headers(c.res)
                val () = add_content(c.res, res)
                prval () = fold@conn
                val () = watcher_data_addback<Conn>(pf | w, conn)
                val () = update_watcher(e, w, EPOLLOUT lor EPOLLET)

                prval () = fold@server

                val () = shared_unlock(pfs | serve, server)
                val () = epoll_data_addback(pf2 | e, serve)
            } else if num_read > 0 then {
                val (pf | opt) = watcher_data_takeout<Conn>(w)
                val-~Some_vt(conn) = opt
                val () = append_data(conn, buf, BUFSZ, num_read)
                val () = watcher_data_addback<Conn>(pf | w, conn)
                val () = loop(e, w)
            }
        }
        val () = loop(e, w)
    }

    val () = if iswrite && ~iserr then { 
        fun loop(e: !Epoll, w: !Watcher): void = {
            var buf = @[byte][1024](int2byte0 0)
            val (pf2 | opt) = watcher_data_takeout<Conn>(w)
            val-~Some_vt(st) = opt
            val+@C(c) = st

            val ret = write_response(c.res, fd)
            val () = free(stringbuf_truncout_all(c.res))

            val () = case+ c.headers of
            | ~Some_vt(h) => (free_headers(h);c.headers := None_vt())
            | @None_vt() => fold@(c.headers)
            val () = case+ c.meth of
            | ~Some_vt(m) => c.meth := None_vt()
            | @None_vt() => fold@(c.meth)
            prval() = fold@st
            val () = watcher_data_addback<Conn>(pf2 | w, st)

            // val () = println!("ret: ", ret, "errno: ", the_errno_get())
            val () = if ret > 0 && the_errno_get() = 0 then loop(e, w) else {
                val () = update_watcher(e, w, EPOLLIN lor EPOLLET)
            }
        }
        val () = loop(e, w)
    }
    val _ = if isclose then {
        val () = unregister_watcher(e, fd)
        val _ = close0_exn(fd)
    }
}

fun{} accept_conn(e: !Epoll, w: !Watcher, evs: uint): void = () where {
    // val () = println! "Accepted"
    val fd = watcher_get_fd(w)
    fun loop(e: !Epoll, w: !Watcher): void = {
        val conn = $extfcall(int, "accept", fd, 0, 0)
        val conn = g1ofg0 conn
        val () = if conn > 0 then () where {
            val _ = setnonblocking(conn)
            val c = make_conn(conn)
            val w2 = make_watcher3<Conn>(conn, do_read, c, free_conn)
            val () = register_watcher(e, w2, EPOLLIN lor EPOLLET)
            val () = loop(e, w)
        }
    }
    val () = loop(e, w)
}

fn{} make_threads(server: !Server): void = {
    // val+@S(s) = server
    // val fd = s.server_fd
    // prval () = fold@server
    // val watcher = make_watcher2<Server>(fd, accept_conn, server)
    // val+@S(s) = server
    // val () = register_watcher(s.epoll, watcher, EPOLLIN lor EPOLLET)
    // val () = run(s.epoll)
    // val () = free_epoll(s.epoll)
    // prval () = fold@server
}

implement{} make_server(port) = sh where {
    val s = get_server(port)
    val () = assertloc(s > 0)
    val () = println!("Server running at http://localhost:", port)
    val server = S(_)
    val S(se) = server
    val () = se.threadCount := 1
    val () = se.threads := list_vt_nil()
    val () = se.router := $HT.hashtbl_make_nil(i2sz 10)
    val () = se.server_fd := s
    // val () = se.thread_pool := $POOL.make_pool(10)
    // val () = $POOL.init_pool(se.thread_pool)
    prval () = fold@server
    val sh = shared_make(server)
}

implement gclear_ref<ptr>(x) = $UNSAFE.cast2void(x)

fn{} free_server_(server: server_): void = {
    val+~S(s) = server
    // val () = $POOL.stop_pool(s.thread_pool)
    val () = list_vt_free(s.threads)
    val () = $HT.hashtbl_free(s.router) where {
        implement $HT.hashtbl_free$clear<strptr,ptr>(k, v) = {
            val () = free(k)
            val () = cloptr_free($UNSAFE.castvwtp0{cloptr(void)}(v))
        }
    }
}

implement{} run_server(serve) = {
    val (pf | server) = shared_lock(serve)
    val+@S(s) = server
    val fd = s.server_fd
    val threadCount = s.threadCount
    prval () = fold@server
    val () = shared_unlock(pf | serve, server)
    fun loop(i: int, ls: &List_vt(tid) >> _, sh0: !Server): void = {
        val () = if i > 0 then {
            val server_ref = shared_ref(sh0)
            val tid = athread_create_cloptr_join_exn(llam() => {
                val e = make_epoll2<Server>(server_ref)
                val () = listen(fd)
                val watcher = make_watcher2<Server>(fd, accept_conn, server_ref)
                val () = register_watcher(e, watcher, EPOLLIN lor EPOLLET)
                val () = run(e)
                val () = free_epoll(e)
                val () = free_server(server_ref)
            })
            val () = assertloc(list_vt_length(ls) >= 0)
            val () = ls := list_vt_cons(tid, ls)
            val () = loop(i-1, ls, sh0)
        }
    }
    var threads = list_vt_nil()
    val () = loop(threadCount - 1, threads, serve)
    val e = make_epoll2<Server>(serve)
    val () = list_vt_foreach(threads) where {
        implement list_vt_foreach$fwork<tid><void>(t, e) = {
            val () = athread_join(t)
        }
    }
    val () = list_vt_free(threads)
    val () = if threadCount = 1 then {
        val () = listen(fd)
        val watcher = make_watcher2<Server>(fd, accept_conn, serve)
        val () = register_watcher(e, watcher, EPOLLIN lor EPOLLET)
        val () = run(e)
    }
    val () = free_epoll(e)
}

implement{} free_server(server) = {
    val opt = shared_unref(server)
    val () = case+ opt of
    | ~Some_vt(s) => free_server_(s)
    | ~None_vt() => ()
}

implement{} set_thread_count(serve, cnt) = {
    val (pf | server) = shared_lock(serve)
    val+@S(s) = server
    val () = s.threadCount := cnt
    prval() = fold@(server)
    val () = shared_unlock(pf | serve, server)
}

implement{} add_route(serve, route, handler) = {
    val (pf | server) = shared_lock(serve)
    val+@S(s) = server
    val key = copy(route)
    val opt = $HT.hashtbl_takeout_opt(s.router, key)
    val () = case+ opt of
    | ~Some_vt(func) => {
        val () = cloptr_free($UNSAFE.castvwtp0{cloptr(void)}func)
    }
    | ~None_vt() => ()
    val-~None_vt() = $HT.hashtbl_insert_opt(s.router, key, $UNSAFE.castvwtp0{ptr}(handler))
    prval() = fold@(server)
    val () = shared_unlock(pf | serve, server)
}