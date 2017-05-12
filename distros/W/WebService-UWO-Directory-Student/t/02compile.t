#!/usr/bin/perl -T

# t/02compile.t
#  Check that the module can be compiled and loaded properly.
#
# $Id: 02compile.t 8624 2009-08-18 05:26:06Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings; # 1 test

# Check that we can load the module
BEGIN {
  use_ok('WebService::UWO::Directory::Student');
}
