#!perl
use Test::WWW::Declare::Tester tests => 3;

ok(1, "successfully got Test::More's exportables");

my @results = run_tests(sub { isnt(2 + 2, 5) } );
is(@results, 2, "successfully got Test::Tester's exportables");

is(_twd_dummy(), "XYZZY", "successfully got Test::WWW::Declare's exportables");

