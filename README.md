[![Build Status](https://cloud.drone.io/api/badges/xran-deex/ats-http/status.svg)](https://cloud.drone.io/xran-deex/ats-http)

# ats-http

## Dependencies

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