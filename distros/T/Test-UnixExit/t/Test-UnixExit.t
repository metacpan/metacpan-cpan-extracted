#!perl
use Test::Most tests => 0x14;
use Test::UnixExit;

can_ok( 'Test::UnixExit' => qw/exit_is exit_is_nonzero/ );

ok( defined(&exit_is),          'exit_ok exported by default' );
ok( !defined(&exit_is_nonzero), 'exit_is_nonzero not exported by default' );

for my $code (qw/0 42/) {
    system $^X, '-e', "exit $code";
    exit_is( $?, $code );
}

for my $failure (qw/1 99/) {
    my $expr = "exit $failure";
    system $^X, '-e', $expr;
    exit_is( Test::UnixExit::exit_is_nonzero($?), 1, $expr );
}

SKIP: {
    skip 'something unusual', 1 unless $ENV{AUTHOR_TEST_JMATES};
    # because 298 % 256 = 42. maybe?
    system $^X, '-e', 'exit 298';
    exit_is( $?, 42 );
}

# simulate some other conditions: generating core files on smoke test
# boxes isn't very nice, and signal handling can get a bit not portable
my $status = 0;
$status |= 128;
$status |= 6;
exit_is(
    Test::UnixExit::exit_is_nonzero($status),
    { iscore => 1, signal => 6 },
    'simulated core is not mangled'
);
ok( exit_is( $status, { iscore => 1, signal => 6 }, 'simulated core' ) );

$status = 0;
$status |= 2;
exit_is( $status, { signal => 2 }, 'simulated INT' );

exit_is(
    Test::UnixExit::exit_is_nonzero(65535),
    { code => 1, signal => 127, iscore => 1 }
);

# this is where the simulated tests came from
SKIP: {
    skip "non-simulated tests", 2 unless $ENV{AUTHOR_TEST_JMATES};
    # NOTE need CORE::dump as of Perl 5.30 and not just dump
    system $^X, qw(-e CORE::dump);
    #diag(sprintf "CORE %016b", $?);
    exit_is( $?, { iscore => 1, signal => 6 }, 'generate core' );

    system $^X, '-e', 'kill INT => $$; sleep 99';
    #diag(sprintf "SIGINT %016b", $?);
    exit_is( $?, { signal => 2 }, 'SIGINT' );
}

# failure is an option
throws_ok { exit_is } qr/status expected-value/;
throws_ok { exit_is(42) } qr/status expected-value/;
throws_ok { exit_is( 42, \"invalid argument" ) } qr/hash reference/;
throws_ok { exit_is( 42, 'fourty two' ) } qr/must be integer/;

# TODO is there a better way to do code coverage of failure branches in
# test routines?
TODO: {
    local $TODO = "code coverage" if 1;
    exit_is( 0, 1 );
}
