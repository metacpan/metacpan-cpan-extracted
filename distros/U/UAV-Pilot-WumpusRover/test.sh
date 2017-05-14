#!/bin/bash
perl ./Build.PL
./Build && ./Build test
./Build distclean
