#define ATS_PACKNAME "ats-http-response"
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "./../SATS/types.sats"

datavtype resp_ = RE of @{
    headers=Headers,
    status=int,
    content_type=string,
    body=strptr
}

fn make_response(): Resp
fn set_body(req: !Resp, body: strptr): void
fn free_response(req: Resp):<!wrt> void
fn print_request(req: !Resp): void
fn set_status_code(res: !Resp, code: int): void
fn get_status_code(res: !Resp): int
fn set_content_type(res: !Resp, code: string): void
fn get_content_type(res: !Resp): string

overload print with print_request
