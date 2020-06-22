#include "../ats-http.hats"
staload "libats/libc/SATS/string.sats"
#include "ats-sqlite3/ats-sqlite3.hats"

staload $REQ
staload $RESP
staload $SQLITE

implement main(argc, argv) = 0 where {
    var server = make_server(8888)
    val () = set_thread_count(server, 6)
    // val () = enable_gzip(server)

    val () = get(server, "/", lam (req,resp) =<cloptr1> res where {
        val in_opt = fileref_open_opt("index.html", file_mode_r)
        val () = set_content_type(resp, "text/html")
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

    val () = get(server, "/hello", lam (req,resp) =<cloptr1> copy("Hello World") where {
        val () = set_status_code(resp, 200)
        val () = set_content_type(resp, "text/plain")
    })

    val () = get(server, "/database", lam (req, resp) =<cloptr1> res where {
        val () = set_status_code(resp, 200)
        val () = set_content_type(resp, "text/plain")
        var db: sqlite3_ptr0?
        val res = open("test.db", db)
        // yes, what follows is ugly, but hey, it works
        val str = (if res = SQLITE_OK then retu where {
            var stmt: sqlite3_stmt0?
            val sql = "select * from Thing where age > ?1 and name = ?2"
            val res = prepare(db, sql, sz2i(length(sql)), stmt, the_null_ptr)
            val retu = (if res = SQLITE_OK then retu where {
                val _ = bind_int(stmt, 1, 20)
                val _ = bind_text(stmt, 2, "Joe", ~1, the_null_ptr)
                val ret = step(stmt)
                val retu = (if ret = SQLITE_ROW then ret where {
                    val sb = stringbuf_make_nil_int(100)
                    val ret = constchar2string(column_text(stmt, 0))
                    val _ = stringbuf_insert_string(sb, ret)
                    val _ = stringbuf_insert_string(sb, " is ")
                    val ret = constchar2string(column_text(stmt, 1))
                    val _ = stringbuf_insert_string(sb, ret)
                    val _ = stringbuf_insert_string(sb, " years old.")
                    var size: size_t?
                    val ret = stringbuf_getfree_strnptr(sb, size)
                    val _ = finalize(stmt)
                } else ret where {
                    val _ = finalize(stmt)
                    val ret = string1_copy ""
                }): [n:int] strnptr(n)
            } else ret where {
                val _ = finalize(stmt)
                val ret = string1_copy ""
            }): [n:int] strnptr(n)
            val _ = $SQLITE.close(db)
        } else ret where {
            val _ = $SQLITE.close(db)
            val ret = string1_copy ""
        }): [n:int] strnptr(n)
        val res = strnptr2strptr str
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

