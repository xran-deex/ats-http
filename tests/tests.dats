#include "../ats-http.hats"
staload "libats/libc/SATS/string.sats"

staload $REQ
staload $RESP

implement main(argc, argv) = 0 where {
    val server = make_server(8888)
    val () = set_thread_count(server, 6)
    // val () = enable_gzip(server)

    val () = get(server, "/", lam (req,resp) =<cloptr1> res where {
        val in_opt = fileref_open_opt("index.html", file_mode_r)
        val res = (case+ in_opt of
                | ~Some_vt(inp) => res where {
                    val () = set_status_code(resp, 200)
                    val res = fileref_get_file_string(inp)
                    val _ = fileref_close(inp)
                }
                | ~None_vt () => res where {
                    val () = set_status_code(resp, 404)
                    val () = println!("file not found")
                    val res = copy("not found")
                }): strptr
    })

    val () = get(server, "/hello", lam (req,resp) =<cloptr1> res where {
        val () = set_status_code(resp, 200)
        val () = set_content_type(resp, "text/plain")
        val res = copy("Hello world")
    })

    val () = post(server, "/goodbye", lam (req,resp) =<cloptr1> res where {
        val () = println!(req)
        val h = get_header_value(req, "Host")
        val () = case+ h of
        | ~Some_vt(header) => println!("Host: ", header)
        | ~None_vt() => ()
        val body = get_body(req)
        val () = case+ body of
        | ~Some_vt(b) => println!("Body: ", b)
        | ~None_vt() => ()
        val () = set_status_code(resp, 200)
        val res = copy("Goodbye world")
    })
    val () = run_server(server)
    val () = free_server(server)
}

