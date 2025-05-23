#!perl

use v5.14;
use warnings;

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use Test2::V0;

eval "use Test::XS::Check qw( xs_ok )";

plan skip_all => "Test::XS::Check required for testing ppport.h" if $@;


xs_ok("XS.xs");
done_testing;
