#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "./../SATS/types.sats"
staload "./../SATS/response.sats"
staload H = "./../SATS/headers.sats"

assume Resp = resp_

implement{} make_response() = res where {
    val res = RE(@{
        headers = $H.new_headers(),
        status = 200,
        content_type = "text/html",
        body = copy("")
    })
}

implement{} set_body(resp, body) = {
    val+@RE(r) = resp
    val () = free(r.body)
    val () = r.body := body
    prval() = fold@resp
}

implement{} get_status_code(resp) = res where {
    val+@RE(r) = resp
    val res = r.status
    prval() = fold@resp
}

implement{} set_status_code(resp, code) = {
    val+@RE(r) = resp
    val () = r.status := code
    prval() = fold@resp
}

implement{} get_content_type(resp) = res where {
    val+@RE(r) = resp
    val res = r.content_type
    prval() = fold@resp
}

implement{} set_content_type(resp, rt) = {
    val+@RE(r) = resp
    val () = r.content_type := rt
    prval() = fold@resp
}

implement{} free_response(resp) = {
    val+~RE(r) = resp
    val () = free(r.body)
    val () = $H.free_headers(r.headers)
}