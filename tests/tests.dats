#include "../ats-http.hats"

staload $REQ

implement main(argc, argv) = 0 where {
    val server = make_server(8888)
    val () = set_thread_count(server, 6)

    val () = add_route(server, "/", lam req =<cloptr1> res where {
        // val () = println!(req)
        // val h = get_header_value(req, "Host")
        // val () = case+ h of
        // | ~Some_vt(header) => println!("Host: ", header)
        // | ~None_vt() => ()
        val res = copy("Hello world")
    })

    val () = add_route(server, "/goodbye", lam req =<cloptr1> res where {
        // val () = println!(req)
        // val h = get_header_value(req, "Host")
        // val () = case+ h of
        // | ~Some_vt(header) => println!("Host: ", header)
        // | ~None_vt() => ()
        val res = copy("Goodbye world")
    })
    val () = run_server(server)
    val () = free_server(server)
}

