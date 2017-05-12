#!/bin/bash

make clean
rm MANIFEST
rm XML-IODEF*.tar.gz
perl Makefile.PL
make manifest
make dist
