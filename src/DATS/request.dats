#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "./../SATS/types.sats"
staload "./../SATS/request.sats"
staload H = "./../SATS/headers.sats"

assume Req = req_
assume Headers = $H.headers_

implement{} make_req(headers, path, meth) = res where {
    val res = R(@{
        headers = headers,
        path = path,
        method = meth
    })
}

implement{} get_header_value(req, key) = res where {
    val+@R(r) = req
    val res = $H.get_header_value(r.headers, key)
    prval() = fold@req
}

implement{} print_request(req) = {
    val+@R(r) = req
    val () = println!("Path: ", r.path)
    prval() = fold@req
}