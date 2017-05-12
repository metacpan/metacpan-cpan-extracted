#!perl

use strict;
use warnings;
use Test::More tests => 9;
use Test::UnixExit;

can_ok( 'Test::UnixExit', 'exit_is' );
ok( defined(&exit_is), 'exit_ok exported by default' );

system( $^X, qw(-e exit) );
exit_is( $?, 0, "exits ok" );

system( $^X, "-e", "exit 42" );
exit_is( $?, 42, "exits not ok" );

system( $^X, "-e", "exit 298" );
exit_is( $?, 42 );

# Simulate other conditions as putting needless corefiles on smoke test
# boxes isn't very nice, and signal handling can get a bit not portable.
# Add real tests if this simulation turns out to be a problem.
my $status = 0;
$status |= 128;
$status |= 6;
exit_is( $status, { iscore => 1, signal => 6 }, "simulated core" );

$status = 0;
$status |= 2;
exit_is( $status, { signal => 2 }, "simulated INT" );

# And this is where the simulated tests came from
SKIP: {
    skip "author tests", 2 unless $ENV{AUTHOR_TEST_JMATES};
    system( $^X, qw(-e dump) );
    exit_is( $?, { code => 0, iscore => 1, signal => 6 }, "generate core" );

    system( $^X, "-e", q{warn "kill -INT $$"; sleep 999} );
    exit_is( $?, { signal => 2 }, "SIGINT" );
}
