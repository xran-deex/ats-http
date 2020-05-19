#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "./../SATS/types.sats" 
staload "./../SATS/http.sats"

datavtype headers_ = H of @{
    map=$HT.hashtbl(strptr,strptr)
}

fn{} parse_headers{n:int}(buf: &(@[byte][n])): Headers
fn{} new_headers(): Headers
fn{} get_header_value(h: !Headers, header: string): Option_vt(string)
fn{} free_headers(h: Headers):<!wrt> void
fn{} put_header_value(h: !Headers, header: strptr, value: strptr): void