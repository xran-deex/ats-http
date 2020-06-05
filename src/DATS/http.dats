#include "./../HATS/includes.hats"
staload "./../SATS/http.sats"
staload "./../SATS/headers.sats"
staload "./../SATS/types.sats" 
staload "./../SATS/request.sats" 
staload "./../SATS/response.sats" 
staload "./../SATS/connection.sats"
staload _ = "./../DATS/connection.dats"
#define ATS_DYNLOADFLAG 0

assume Server = shared(server_)

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

#define BUFSZ 1024

fn{} write_response(conn: !Conn, fd: int): int = ret where {
    var size: size_t?
    val (pf, pff | buf) = get_buffer(conn, size)
    val () = assertloc(size >= 0)
    val () = assertloc(ptr_isnot_null buf)
    val ret = http_write_err(pf | fd, buf, size)
    val ret = $UNSAFE.cast{int}ret
    prval () = pff(pf)
}

fn{} get_handler(serve: !Server, conn: !Conn): Handler = handler where {
    val (pfs | server) = shared_lock(serve)
    val+@S(s) = server
    val key = get_routing_key(conn)
    val ptr = $HT.hashtbl_search_ref(s.router, key)
    val () = free(key)
    val handler = (if ptr != 0 then 
        $UNSAFE.castvwtp1{Handler}($UNSAFE.cptr_get<ptr>(ptr))
        else res where {
            // no handler for this path/method combo, so return 404
            val key = copy("NOTFOUND")
            val ptr = $HT.hashtbl_search_ref(s.router, key)
            val () = free(key)
            val res = (if ptr != 0 then $UNSAFE.castvwtp1{Handler}($UNSAFE.cptr_get<ptr>(ptr)) else $raise NotFoundExn): Handler
        }
    ): Handler
    prval () = fold@server

    val () = shared_unlock(pfs | serve, server)
}

fn{} set_response(serve: !Server, conn: !Conn, content: strptr): void = {
    val (pfs | server) = shared_lock(serve)
    val+@S(s) = server
    val () = if s.enable_gzip 
            then
            create_response_gzip(conn, content)
            else
            create_response(conn, content)
    prval () = fold@server
    val () = shared_unlock(pfs | serve, server)
}

fun{} do_read(e: !Epoll, w: !Watcher, evs: uint): void = () where {
    val fd = watcher_get_fd(w)
    val isedge = (evs land EPOLLET) > 0
    val isread = (evs land EPOLLIN) > 0
    val iswrite = (evs land EPOLLOUT) > 0
    val iserr = (evs land EPOLLERR) > 0
    val isclose = (evs land (EPOLLRDHUP lor EPOLLHUP)) > 0
    val () = if isread && ~iserr then {
        fun loop(e: !Epoll, w: !Watcher): void = {
            var buf with pf = @[byte][BUFSZ](int2byte0 0)
            val num_read = http_read_err(pf | fd, addr@buf, i2sz (BUFSZ))

            // TODO - handle requests larger than the buffer size
            val () = if num_read >= 0 then {
                val (pf | opt) = watcher_data_takeout<Conn>(w)
                val-~Some_vt(conn) = opt
                val () = parse_conn_from_buffer(conn, buf, BUFSZ)

                val (pf2 | opt) = epoll_data_takeout<Server>(e)
                val-~Some_vt(serve) = opt

                val () = clear_request_buffer(conn)

                val handler = get_handler(serve, conn)

                val res = call_handler(conn, handler)

                val () = set_response(serve, conn, res)

                val () = watcher_data_addback<Conn>(pf | w, conn)
                val () = update_watcher(e, w, EPOLLOUT lor EPOLLET)
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

            val ret = write_response(st, fd)
            val () = clear_response_buffer(st)

            val () = watcher_data_addback<Conn>(pf2 | w, st)

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
    val () = se.enable_gzip := false
    // val () = se.thread_pool := $POOL.make_pool(10)
    // val () = $POOL.init_pool(se.thread_pool)
    prval () = fold@server
    val sh = shared_make(server)
    val () = add_route(sh, "", "NOTFOUND", lam (req,resp) =<cloptr1> (set_status_code(resp,404);copy("<h2>404 not found</h2>")))
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

// handles the SIGPIPE signal so we don't crash
fn{} ignore_sigpipe(e: !Epoll): void = {
    fn handle_signal(e: !Epoll, w: !Watcher, evs: uint): void = () where {
        // just ignore it
    }
    var s: sigset_t?
    val i = sigemptyset(s)
    val () = if i = 0 then {
        prval() = opt_unsome(s)
        val i = sigaddset(s, SIGPIPE)
        val _ = sigprocmask(SIG_BLOCK, s, 0)
        val fd = signalfd(~1, s, 0)
        val () = if fd > 0 then {
            val _ = setnonblocking(fd)
            val w = make_watcher(fd, handle_signal)
            val () = register_watcher(e, w, EPOLLIN)
        }
    } else {
        prval() = opt_unnone(s)
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
                val () = ignore_sigpipe(e)
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
    // ignore broken pipes
    val () = ignore_sigpipe(e)
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

implement{} enable_gzip(serve) = {
    val (pf | server) = shared_lock(serve)
    val+@S(s) = server
    val () = s.enable_gzip := true
    prval() = fold@(server)
    val () = shared_unlock(pf | serve, server)
}

implement{} add_route(serve, method, route, handler) = {
    val (pf | server) = shared_lock(serve)
    val+@S(s) = server
    val key = string0_append(method, route)
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

implement{} get(serve, route, handler) = add_route(serve, "GET", route, handler)
implement{} post(serve, route, handler) = add_route(serve, "POST", route, handler)
implement{} put(serve, route, handler) = add_route(serve, "PUT", route, handler)
implement{} head(serve, route, handler) = add_route(serve, "HEAD", route, handler)
implement{} delete(serve, route, handler) = add_route(serve, "DELETE", route, handler)