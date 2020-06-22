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
``` ats
val () = get(server, "/hello", lam (req,resp) =<cloptr1> copy("Hello World") where {
    val () = set_status_code(resp, 200)
    val () = set_content_type(resp, "text/plain")
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

Run the test app
```bash
./tests/target/tests

or

STATICLIB=1 make runtest
```