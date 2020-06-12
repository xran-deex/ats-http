#ifndef ATS_HTTP
#define ATS_HTTP

int http_write_err(int fd, void* buf, size_t n) {
    return write(fd, buf, n);
}
int http_read_err(int fd, void* buf, size_t n) {
    return read(fd, buf, n);
}
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
void reuseport(int fd) {
    int enable = 1;
    if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &enable, sizeof(int)) < 0)
        printf("setsockopt(SO_REUSEADDR) failed\n");
    setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &enable, sizeof(int));
    setsockopt(fd, SOL_SOCKET, SO_KEEPALIVE, &enable, sizeof(int));
}
#endif