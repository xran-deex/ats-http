#include "./HATS/includes.hats"
staload _ = "./DATS/http.dats"
staload _ = "./DATS/headers.dats"
staload _ = "./DATS/request.dats"
staload _ = "./DATS/response.dats"
staload _ = "./DATS/connection.dats"
staload HTTP = "./SATS/http.sats"
staload REQ = "./SATS/request.sats"
staload RESP = "./SATS/response.sats"

%{#
#include "CATS/ats-http.cats"
%}
