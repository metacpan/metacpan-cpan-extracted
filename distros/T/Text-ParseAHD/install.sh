#!/bin/sh
perl Makefile.PL

make install

make clean

rm -f Makefile.old
