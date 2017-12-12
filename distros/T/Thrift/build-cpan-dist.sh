#!/bin/bash
#
# This script is intended to be used after tagging the repository and updating
# the version files for a release.  It will create a CPAN archive.  Run this
# from inside a docker image like ubuntu-xenial.
#

cpan install HTTP::Date
cpan install CPAN
cpan install ExtUtils::MakeMaker

perl Makefile.PL
make
make manifest
make dist
