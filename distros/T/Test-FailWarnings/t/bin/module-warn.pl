use strict;
use warnings;
use Test::More;
use Test::FailWarnings;
use lib 't/lib';
use Noisy;

ok( 1,              "first test" );
ok( Noisy::do_it(), "call do_it" );

done_testing;
