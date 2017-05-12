# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl YAMC.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

#use Test::More;
 use Test::More skip_all => "no test need at this version";
BEGIN { use_ok('YAMC') };
#########################
