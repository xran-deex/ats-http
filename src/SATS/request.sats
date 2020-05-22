#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "./../SATS/types.sats"

datavtype req_ = R of @{
    headers=Headers,
    path=strptr,
    method=Method,
    body=strptr
}

fn{} make_req(header: Headers, path: strptr, meth: Method, body: strptr): Req
fn{} get_header_value(req: !Req, key: string): Option_vt(string)
fn{} get_body(req: !Req): Option_vt(string)
fn{} print_request(req: !Req): void

overload print with print_request