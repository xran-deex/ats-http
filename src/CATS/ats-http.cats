#ifndef ATS_HTTP
#define ATS_HTTP

char* string_from_bytes(void* p, int n) {
    char* temp = (char*)ATS_CALLOC(n + 1, sizeof(char));
    strncpy(temp, (char*)p, n);
    temp[n] = '\0';
    return temp;
}
void string_to_bytes(char* p, void* buf, size_t n) {
    memcpy(buf, p, n);
}
void* string_to_bytes2(char* p) {
    return p;
}
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