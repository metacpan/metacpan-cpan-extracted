#!perl
use blib;
use Test::More tests => 2;

use_ok 'TheSchwartz::Moosified';

# I've Test::Harness ignore blib/lib and thus the 'use' above can load the
# *previously* installed version of TheSchwartz::Moosified, so explicitly
# check the version number here.
is $TheSchwartz::Moosified::VERSION, '0.07', "version check"
    or diag "did you forget to update this test after updating Moosified.pm?";
