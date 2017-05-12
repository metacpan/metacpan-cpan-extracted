
use strict;
use Test::Tester;
use Test::More tests => 60;

use Test::Timer;
$Test::Timer::alarm = 20;

#test 1-6
check_test(
    sub {
        time_ok( sub { sleep(1); }, 2, 'Passing test' );
    },
    { ok => 1, name => 'Passing test', depth => 2 }, 'Succeeding test of time_ok'
);

#test 7-12
check_test(
    sub {
        time_ok( sub { sleep(2); }, 1, 'Failing test' );
    },
    { ok => 0, name => 'Failing test', depth => 2 }, 'Failing test of time_ok'
);

#test 13-18
check_test(
    sub {
        time_nok( sub { sleep(1); }, 3, 'Failing test' );
    },
    { ok => 0, name => 'Failing test', depth => 1 }, 'Failing test of time_nok'
);

#test 19-24
check_test(
    sub {
        time_nok( sub { sleep(3); }, 1, 'Passing test' );
    },
    { ok => 1, name => 'Passing test', depth => 1 }, 'Passing test of time_nok'
);

#test 25-30
check_test(
    sub {
        time_between( sub { sleep(2); }, 0, 3, 'Passing test' );
    },
    { ok => 1, name => 'Passing test', depth => 1 }, 'Passing test of time_between'
);

#test 31-36
check_test(
    sub {
        time_between( sub { sleep(3); }, 1, 2, 'Failing test' );
    },
    { ok => 0, name => 'Failing test', depth => 1 }, 'Failing test of time_between'
);

#test 
check_test(
    sub {
        time_atmost( sub { sleep(1); }, 2, 'Passing test' );
    },
    { ok => 1, name => 'Passing test', depth => 1 }, 'Succeeding test of time_atmost'
);

#test 
check_test(
    sub {
        time_atmost( sub { sleep(2); }, 1, 'Failing test' );
    },
    { ok => 0, name => 'Failing test', depth => 1 }, 'Failing test of time_atmost'
);

#test
check_test(
    sub {
        time_atleast( sub { sleep(1); }, 3, 'Failing test' );
    },
    { ok => 0, name => 'Failing test', depth => 1 }, 'Failing test of time_atleast'
);

#test
check_test(
    sub {
        time_atleast( sub { sleep(3); }, 1, 'Passing test' );
    },
    { ok => 1, name => 'Passing test', depth => 1 }, 'Passing test of time_atleast'
);