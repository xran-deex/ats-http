#include "./src/HATS/includes.hats"
staload _ = "./src/DATS/http.dats"
staload _ = "./src/DATS/headers.dats"
staload _ = "./src/DATS/request.dats"
staload _ = "./src/DATS/response.dats"
staload _ = "./src/DATS/connection.dats"
staload HTTP = "./src/SATS/http.sats"
staload REQ = "./src/SATS/request.sats"
staload RESP = "./src/SATS/response.sats"

%{#
#include "CATS/ats-http.cats"
%}