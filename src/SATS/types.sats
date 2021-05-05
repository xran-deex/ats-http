#define ATS_PACKNAME "ats-http"
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

absvtype Server
absvtype Req
absvtype Headers
absvtype Conn
absvtype Resp

datatype Method = 
| GET of ()
| PUT of ()
| POST of () 
| HEAD of () 
| DELETE of () 
