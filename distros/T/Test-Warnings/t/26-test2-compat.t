use strict;
use warnings;

BEGIN {
  $^W = 1;
  eval { +require Test2::V0; 1 } or do { print "1..0 # SKIP Need Test2::V0\n"; exit };
  Test2::V0->import;
}

use Test2::Warnings;

pass('this is a test which does not warn');

# for now, we just visually observe we add a no-warnings test here.
done_testing();
