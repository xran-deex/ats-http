[![Build Status](https://cloud.drone.io/api/badges/xran-deex/ats-http/status.svg)](https://cloud.drone.io/xran-deex/ats-http)

# ats-http

## Quick start (Docker)
```bash
docker run -it --rm -v $PWD:/code -p 8888:8888 -e "STATICLIB=1" xrandeex/ats2-libz:0.4.0 make -C /code runtest
```

## Dependencies
Until optional dependencies are working, you will need libz installed.
```bash
sudo apt install zlib1g-dev
```
To run the examples, you will need sqlite3 as well.
```bash
sudo apt install libsqlite3-dev
```

## Example
``` java
val () = get(server, "/hello", lam (req,resp) =<cloptr1> res where {
    val () = set_status_code(resp, 200)
    val () = set_content_type(resp, "text/plain")
    val res = copy("Hello world")
})
```

## Build
Build a shared library
``` bash
make
```
Build a static library
``` bash
STATICLIB=1 make
```
Build an arm64 static library
``` bash
ARMLIBS=path_to_arm_libs CC=aarch64-linux-gnu-gcc STATICLIB=1 make
```
Build the test app
``` bash
STATICLIB=1 make test
```
Run the test app
```bash
./tests/target/tests
```