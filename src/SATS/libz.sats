#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

// fn compress{n,m:int}(dest: ptr, destLen: &lint? >> lint, source: ptr, sourceLen: lint): int = "mac#"
// fn compress2{n,m:nat;l,l2:agz}(bytes_v (l, n), bytes_v (l, n) -<lin,prf> void | dest: ptr(l2), destLen: &size_t(0) >> size_t(m), source: ptr(l), sourceLen: lint): (bytes_v (l2, m), bytes_v (l2, m) -<lin,prf> void|int) = "mac#compress"
fn compress(dest: ptr, destLen: &lint >> lint, source: ptr, sourceLen: lint): int = "mac#"
fn uncompress{n,m:int}(dest: ptr, destLen: &lint? >> lint, source: ptr, sourceLen: lint): int = "mac#"