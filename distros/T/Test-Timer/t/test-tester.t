use strict;
use warnings;
use Test::Tester;
use Test::More;

use Test::Timer;

$Test::Timer::alarm = 5;

check_test(
    sub {
        time_ok( sub { sleep(1); }, 2, 'time_ok, passing test' );
    },
    { ok => 1, name => 'time_ok, passing test', depth => 2, diag => ''  }, 'Succeeding test of time_ok'
);

check_test(
    sub {
        time_ok( sub { sleep(2); }, 1, 'time_ok, failing test' );
    },
    { ok => 0, name => 'time_ok, failing test', depth => 2, diag => 'Test ran 2 seconds and exceeded specified threshold of 1 seconds' }, 'Failing test of time_ok'
);

check_test(
    sub {
        time_nok( sub { sleep(1); }, 3, 'time_nok, failing test' );
    },
    { ok => 0, name => 'time_nok, failing test', depth => 1, diag => 'Test ran 1 seconds and did not exceed specified threshold of 3 seconds' }, 'Failing test of time_nok'
);

check_test(
    sub {
        time_nok( sub { sleep(3); }, 1, 'time_nok, passing test' );
    },
    { ok => 1, name => 'time_nok, passing test', depth => 1, diag => '' }, 'Passing test of time_nok'
);

check_test(
    sub {
        time_between( sub { sleep(2); }, 0, 3, 'time_between, passing test' );
    },
    { ok => 1, name => 'time_between, passing test', depth => 1, diag => '' }, 'Passing test of time_between'
);

check_test(
    sub {
        time_between( sub { sleep(3); }, 1, 2, 'time_between, failing test' );
    },
    { ok => 0, name => 'time_between, failing test', depth => 1, diag => 'Test ran 3 seconds and did not execute within specified interval 1 - 2 seconds' }, 'Failing test of time_between'
);

check_test(
    sub {
        time_atmost( sub { sleep(1); }, 2, 'time_atmost, passing test' );
    },
    { ok => 1, name => 'time_atmost, passing test', depth => 1, diag => '' }, 'Succeeding test of time_atmost'
);

check_test(
    sub {
        time_atmost( sub { sleep(2); }, 1, 'time_atmost, failing test' );
    },
    { ok => 0, name => 'time_atmost, failing test', depth => 1, diag => 'Test ran 2 seconds and exceeded specified threshold of 1 seconds' }, 'Failing test of time_atmost'
);

check_test(
    sub {
        time_atleast( sub { sleep(1); }, 3, 'time_atleast, failing test' );
    },
    { ok => 0, name => 'time_atleast, failing test', depth => 1, diag => 'Test ran 1 seconds and did not exceed specified threshold of 3 seconds' }, 'Failing test of time_atleast'
);

check_test(
    sub {
        time_atleast( sub { sleep(3); }, 1, 'time_atleast, passing test' );
    },
    { ok => 1, name => 'time_atleast, passing test', depth => 1, diag => '' }, 'Passing test of time_atleast'
);

check_test(
    sub {
        time_between( sub { sleep(10); }, 1, 5, 'time_between, long running test' );
    },
    { ok => 0, name => 'time_between, long running test', depth => 1, diag => 'Execution ran 10 seconds and did not execute within specified interval 1 - 5 seconds and timed out' }, 'failing long running test of time_between'
);

done_testing();
