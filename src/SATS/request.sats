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
fn{} make_empty_req(): Req
fn{} add_header_value(req: !Req, key: strptr, value: strptr): void
fn{} set_path(req: !Req, path: strptr): void
fn{} set_method(req: !Req, method: Method): void
fn{} get_method(req: !Req): Method
fn{} get_path(req: !Req): string
fn{} set_body(req: !Req, body: strptr): void
fn{} get_header_value(req: !Req, key: string): Option_vt(string)
fn{} get_body(req: !Req): Option_vt(string)
fn{} print_request(req: !Req): void
fn{} free_request(req: Req):<!wrt> void

overload print with print_request