#!perl
use strict;
use warnings;
use Test::More $ENV{RELEASE_TESTING} ? ()
                                     : (skip_all => "only for raising Kwalitee");

use Test::Pod::Coverage 1.00;
all_pod_coverage_ok();
