#!/bin/bash
perl Makefile.PL
make
cover -test
#TODO prove -lv t