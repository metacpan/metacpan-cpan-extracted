#!/bin/sh
# BUILD.sh - preconfigure libapreq (for distribution)

libtoolize --automake -c -f
aclocal
autoconf
automake -a -c
