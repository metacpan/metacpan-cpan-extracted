use strict;
use warnings;
use Test::More;
use Test::FailWarnings;
use lib 't/lib';
use Noisy;

ok( 1,                     "first test" );
ok( Noisy::with_newline(), "call with_newline" );

done_testing;
