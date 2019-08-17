#!/bin/bash
perl Makefile.PL
make realclean && ./scripts/coverage.sh