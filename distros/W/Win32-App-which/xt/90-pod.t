#!perl
# This test is only for raising Kwalitee
# because testing POD is done with Module::Build using "Build testpod".
use strict;
use warnings;
use Test::More $ENV{RELEASE_TESTING} ? ()
                                     : (skip_all => "only for release testing");
use Test::Pod 1.00;
all_pod_files_ok();
