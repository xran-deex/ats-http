#include "../ats-http.hats"
staload "libats/libc/SATS/string.sats"

staload $REQ

implement main(argc, argv) = 0 where {
    val server = make_server(8888)
    val () = set_thread_count(server, 6)

    val () = add_route(server, "/", lam req =<cloptr1> res where {
        // val () = println!(req)
        val in_opt = fileref_open_opt("index.html", file_mode_r)
        val res = (case+ in_opt of
                | ~Some_vt(inp) => res where {
                    val res = fileref_get_file_string(inp)
                    val _ = fileref_close(inp)
                }
                | ~None_vt () => (println!("file not found");copy("not found"))): strptr
        // val res = copy("Hello world")
    })

    val () = add_route(server, "/hello", lam req =<cloptr1> res where {
        // val () = println!(req)
        val res = copy("Hello world")
    })

    val () = add_route(server, "/goodbye", lam req =<cloptr1> res where {
        val () = println!(req)
        val h = get_header_value(req, "Host")
        val () = case+ h of
        | ~Some_vt(header) => println!("Host: ", header)
        | ~None_vt() => ()
        val body = get_body(req)
        val () = case+ body of
        | ~Some_vt(b) => println!("Body: ", b)
        | ~None_vt() => ()
        val res = copy("Goodbye world")
    })
    val () = run_server(server)
    val () = free_server(server)
}

