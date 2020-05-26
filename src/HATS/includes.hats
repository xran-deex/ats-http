#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "libats/libc/SATS/sys/socket.sats"
staload "libats/libc/SATS/errno.sats"
staload _ = "libats/libc/DATS/sys/socket.dats"
staload "libats/libc/SATS/time.sats"
//
staload "libats/libc/SATS/unistd.sats"
staload "libats/libc/SATS/sys/socket.sats"
staload "libats/libc/SATS/sys/socket_in.sats"
//
staload "libats/libc/SATS/arpa/inet.sats"
staload "libats/libc/SATS/netinet/in.sats"

staload "libats/SATS/stringbuf.sats"
staload _ = "libats/DATS/stringbuf.dats"

#include "ats-pthread-extensions/ats-pthread-ext.hats"
#include "ats-epoll/ats-epoll.hats"
#include "shared_vt/ats-shared-vt.hats"
#include "hashtable-vt/hashtable_vt.hats"
#include "ats-threadpool/ats-threadpool.hats"
#include "ats-libz/ats-libz.hats"

staload $EPOLL

%{#
#include "CATS/ats-http.cats"
#include "zlib.h"
%}

staload "./../SATS/http.sats"
