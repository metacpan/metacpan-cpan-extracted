#!/bin/bash

make clean
rm MANIFEST
rm *.tar.gz
perl Makefile.PL
make manifest
make dist
