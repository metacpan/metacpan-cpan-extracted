use 5.010001;
use warnings;
use strict;
use utf8;
use Test::More;
use Test::Exception;

use Test::Mock::Time;

BEGIN {
    plan skip_all => 'Time::HiRes not installed' if !eval { require Time::HiRes };
    Time::HiRes->import(qw( time gettimeofday sleep usleep nanosleep ));
    eval { Time::HiRes->import(qw( CLOCK_REALTIME CLOCK_MONOTONIC clock_gettime clock_getres )) };
    eval { Time::HiRes->import(qw( CLOCK_REALTIME CLOCK_MONOTONIC clock_nanosleep )) };
}

my $t = time;
cmp_ok $t, '>', 1455000000, 'time looks like current actual time';
like $t, qr/\A\d+\z/ms, 'time is initially integer';
select undef,undef,undef,1.1;
is time, $t, 'time is same after real 1.1 second delay';
is time(), $t, 'time() is same';

SKIP: {
    skip 'clock_gettime(): unimplemented in this platform', 4 if !exists &clock_gettime;

    is clock_gettime(CLOCK_REALTIME()), $t, 'clock_gettime(CLOCK_REALTIME) is same';
    cmp_ok clock_gettime(CLOCK_MONOTONIC()), '<', $t, 'clock_gettime(CLOCK_MONOTONIC) < time()';
    cmp_ok clock_gettime(CLOCK_MONOTONIC()), '>', 0, 'clock_gettime(CLOCK_MONOTONIC) > 0';
    is clock_gettime(42), -1, 'clock_gettime(42) is not supported';
}

SKIP: {
    skip 'clock_getres(): unimplemented in this platform', 3 if !exists &clock_getres;

    isnt clock_getres(CLOCK_REALTIME()), -1, 'clock_getres(CLOCK_REALTIME) is supported';
    isnt clock_getres(CLOCK_MONOTONIC()), -1, 'clock_getres(CLOCK_MONOTONIC) is supported';
    is clock_getres(42), -1, 'clock_getres(42) is not supported';
}

is scalar gettimeofday(), $t, 'gettimeofday is same as scalar';
is_deeply [gettimeofday()], [$t,0], 'gettimeofday is same as array';

throws_ok { sleep -0.5 } qr/Time::HiRes::sleep\(-0.5\): negative time not invented yet/ms;
throws_ok { sleep } qr/sleep without arg is not supported/ms;
sleep 0.5;
is time, $t+=0.5, 'time is increased by 0.5';
is scalar gettimeofday(), $t, 'gettimeofday is increased by 0.5 as scalar';
is_deeply [gettimeofday()], [$t-0.5,500000], 'gettimeofday is increased by 0.5 as array';

throws_ok { usleep(-1) } qr/Time::HiRes::usleep\(-1\): negative time not invented yet/ms;
usleep(10_000);
is time, $t+=0.01, 'time is increased by 0.01';

throws_ok { nanosleep(-2) } qr/Time::HiRes::nanosleep\(-2\): negative time not invented yet/ms;
nanosleep(2_000_000);
is time, $t+=0.002, 'time is increased by 0.002';

SKIP: {
    skip 'clock_nanosleep(): unimplemented in this platform', 4 if !exists &clock_nanosleep;

    throws_ok { clock_nanosleep(CLOCK_REALTIME(), -3) } qr/Time::HiRes::clock_nanosleep\(..., -3\): negative time not invented yet/ms;
    throws_ok { clock_nanosleep(42, 1) } qr/only CLOCK_REALTIME and CLOCK_MONOTONIC are supported/ms;
    throws_ok { clock_nanosleep(CLOCK_MONOTONIC(), 1, 1) } qr/only flags=0 is supported/ms;
    clock_nanosleep(CLOCK_REALTIME(), 1_500_000);
    clock_nanosleep(CLOCK_MONOTONIC(), 1_500_000, 0);
    is time, $t+=0.003, 'time is increased by 0.003';
}

ff(1000.5);
is time, $t+=1000.5, 'time is increased by 1000.5 after ff(1000.5)';


done_testing();
