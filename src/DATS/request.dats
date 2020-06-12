#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "./../SATS/types.sats"
staload "./../SATS/request.sats"
staload _ = "./../DATS/headers.dats"
staload H = "./../SATS/headers.sats"
#define ATS_DYNLOADFLAG 0

assume Req = req_

implement make_req(headers, path, meth, body) = res where {
    val res = R(@{
        headers = headers,
        path = path,
        method = meth,
        body = body
    })
}

implement make_empty_req() = res where {
    val res = R(@{
        headers = $H.new_headers(),
        path = copy(""),
        method = GET,
        body = copy("")
    })
}

implement add_header_value(req, key, value) = {
    val+@R(r) = req
    val () = $H.put_header_value(r.headers, key, value)
    prval() = fold@req
}

implement set_path(req, path) = {
    val+@R(r) = req
    val () = free(r.path)
    val () = r.path := path
    prval() = fold@req
}

implement set_method(req, method) = {
    val+@R(r) = req
    val () = r.method := method
    prval() = fold@req
}

implement get_method(req) = res where {
    val+@R(r) = req
    val res = r.method
    prval() = fold@req
}

implement get_path(req) = res where {
    val+@R(r) = req
    val res = $UNSAFE.castvwtp1{string}(r.path)
    prval() = fold@req
}

implement set_body(req, body) = {
    val+@R(r) = req
    val () = free(r.body)
    val () = r.body := body
    prval() = fold@req
}

implement get_header_value(req, key) = res where {
    val+@R(r) = req
    val res = $H.get_header_value(r.headers, key)
    prval() = fold@req
}

implement get_body(req) = res where {
    val+@R(r) = req
    val res = $UNSAFE.castvwtp1{string}(r.body)
    val res = (if res = "" then None_vt() else Some_vt(res)): Option_vt(string)
    prval() = fold@req
}

implement print_request(req) = {
    val+@R(r) = req
    val () = case+ r.method of
    | GET() => println!("Method: GET")
    | POST() => println!("Method: POST")
    | HEAD() => println!("Method: HEAD")
    | PUT() => println!("Method: PUT")
    | DELETE() => println!("Method: DELETE")
    val () = println!("Path: ", r.path)
    overload print with $H.print_headers
    val () = println!(r.headers)
    prval() = fold@req
}

implement free_request(req) = {
    val+~R(r) = req
    val () = free(r.path)
    val () = $H.free_headers(r.headers)
    val () = free(r.body)
}