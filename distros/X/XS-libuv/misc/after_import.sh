#!/bin/sh

BDIR=$(pwd)/libuv

(cd $BDIR && rm -rf docs img)

# cannot just remove "test" folder because CMake will fail
(cd $BDIR && truncate -s 0 test/*.c test/*.h)
