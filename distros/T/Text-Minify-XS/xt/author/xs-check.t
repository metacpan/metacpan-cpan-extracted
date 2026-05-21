#!perl

use v5.14;
use warnings;

use Test2::Require::AuthorTesting;

use Test2::V0;

eval "use Test::XS::Check qw( xs_ok )";

plan skip_all => "Test::XS::Check required for testing ppport.h" if $@;


xs_ok("XS.xs");
done_testing;
