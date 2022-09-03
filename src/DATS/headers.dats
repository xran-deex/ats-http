#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "./../SATS/headers.sats"
#include "hashtable_vt.hats"
staload "./../SATS/http.sats"
staload "./../SATS/types.sats" 
#define ATS_DYNLOADFLAG 0

assume Headers = headers_

implement parse_headers(buf) = headers where {
    val h = $HT.hashtbl_make_nil(i2sz 100)
    val-~None_vt() = $HT.hashtbl_insert_opt(h, copy("Connection"), copy("Keep-Alive"))
    val headers = H(@{
        map = h
    })
}

implement new_headers() = headers where {
    val h = $HT.hashtbl_make_nil(i2sz 100)
    val headers = H(@{
        map = h
    })
}

implement free_headers(headers) = {
    val+~H(h) = headers
    val () = $HT.hashtbl_free(h.map) where {
        implement $HT.hashtbl_free$clear<strptr,strptr>(k, v) = {
            val () = free(k)
            val () = free(v)
        }
    }
}

implement get_header_value(headers, header) = value where {
    val+@H(h) = headers
    val key = $UNSAFE.castvwtp1{strptr} header
    val ptr = $HT.hashtbl_search_ref(h.map, key)
    prval() = $UNSAFE.cast2void(key)
    val value = (if ptr != 0 then Some_vt($UNSAFE.castvwtp0{string}($UNSAFE.p2tr_get<strptr>(ptr)))
    else None_vt()): Option_vt(string)
    prval() = fold@headers
}

implement put_header_value(headers, key, value) = {
    val+@H(h) = headers
    val opt = $HT.hashtbl_takeout_opt(h.map, key)
    val () = case+ opt of
    | ~Some_vt(v) => {
        val () = free(v)
        val-~None_vt() = $HT.hashtbl_insert_opt(h.map, key, value)
    }
    | ~None_vt() => {
        val-~None_vt() = $HT.hashtbl_insert_opt(h.map, key, value)
    }
    prval() = fold@headers
}

implement print_headers(headers) = {
    val+@H(h) = headers
    val () = $HT.hashtbl_foreach(h.map) where {
        implement $HT.hashtbl_foreach$fwork<strptr,strptr><void>(k, v, e) = {
            val () = println!(k, ": ", v)
        }
    }
    prval() = fold@headers
}
