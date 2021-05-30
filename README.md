[![Build Status](https://cloud.drone.io/api/badges/xran-deex/ats-http/status.svg)](https://cloud.drone.io/xran-deex/ats-http)

# ats-http

## Quick start (Docker)
```bash
docker run -v `pwd`:/src --net=host -it --rm -e CONAN_REMOTE=<conan_package_url> xrandeex/ats2:0.4.2 "conan install . -if build && conan build . -if build"
```

## Dependencies
Dependencies are handled using conan (which depends on Python)
Conan https://conan.io

A simple conan helper file needs to be installed to add the correct include paths to the makefile. (https://github.com/xran-deex/atsconan)

## Example
``` ats
#include "../ats-http.hats"
staload "libats/libc/SATS/string.sats"

staload $REQ
staload $RESP

implement main(argc, argv) = 0 where {
    // make the server
    var server = make_server(8888)
    // use 6 threads
    val () = set_thread_count(server, 6)

    // setup a get response handler
    val () = get(server, "/hello", lam (req,resp) =<cloptr1> copy("Hello World") where {
        val () = set_status_code(resp, 200)
        val () = set_content_type(resp, "text/plain")
    })

    // run the server
    val () = run_server(server)
    val () = free_server(server)
}
```
## Install dependencies
``` bash
conan install . --install-folder build
```

## Build
``` bash
conan build . --install-folder build
```

## Build and run test app
``` bash

cd tests
conan install . --install-folder build
conan build . --install-folder build
./tests

```
