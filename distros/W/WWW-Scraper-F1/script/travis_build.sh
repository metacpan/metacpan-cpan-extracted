#!/usr/bin/env sh

echo "****** Begin travis_build script. *******"
cd WWW-Scraper-F1*
perl Makefile.PL 
make test
