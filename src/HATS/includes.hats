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

#include "ats-pthread-ext.hats"
#include "ats-epoll.hats"
#include "ats-shared-vt.hats"
#include "hashtable_vt.hats"
#include "ats-threadpool.hats"
#include "ats-libz.hats"
#include "ats-shared-vt.hats"

staload $EPOLL

%{#
#include "zlib.h"
%}

staload "./../SATS/http.sats"
