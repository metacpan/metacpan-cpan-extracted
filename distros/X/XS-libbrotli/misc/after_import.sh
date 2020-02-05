#!/bin/sh

BDIR=$(pwd)/brotli

echo $BDIR

(cd $BDIR && rm -rf js go java tests research python csharp docs)
(cd $BDIR && patch -p0 -i ../misc/CMakeLists.txt.patch)
