#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "./../SATS/types.sats"
staload "./../SATS/request.sats"
staload H = "./../SATS/headers.sats"

assume Req = req_
assume Headers = $H.headers_

implement{} make_req(headers, path, meth, body) = res where {
    val res = R(@{
        headers = headers,
        path = path,
        method = meth,
        body = body
    })
}

implement{} get_header_value(req, key) = res where {
    val+@R(r) = req
    val res = $H.get_header_value(r.headers, key)
    prval() = fold@req
}

implement{} get_body(req) = res where {
    val+@R(r) = req
    val res = $UNSAFE.castvwtp1{string}(r.body)
    val res = (if res = "" then None_vt() else Some_vt(res)): Option_vt(string)
    prval() = fold@req
}

implement{} print_request(req) = {
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