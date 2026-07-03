use strict;
use warnings;
use Test::More;

use Time::Nanos;

# $CLOCK defaults to 'monotonic'
is($Time::Nanos::CLOCK, 'realtime', '$CLOCK defaults to realtime');

# nanos() basic tests
ok(defined &nanos, 'nanos is exported');

my $ns = nanos();
ok(defined $ns, 'nanos() returns a value');
ok($ns > 0    , 'nanoseconds value is positive');

my ($sec                , $nsec) = nanos(1);
ok(defined $sec         , 'seconds component defined');
ok(defined $nsec        , 'nanoseconds component defined');
ok($sec > 0             , 'seconds is positive');
ok($nsec >= 0           , 'nanoseconds component is non-negative');
ok($nsec < 1_000_000_000, 'nanoseconds component < 1e9');

my $combined = $sec * 1_000_000_000 + $nsec;
ok(abs($combined - $ns) < 1_000_000, 'combined and scalar values are consistent');

my $ns2 = nanos();
ok($ns2 >= $ns, 'monotonic: second call >= first call');

# explicit monotonic via $CLOCK
{
    local $Time::Nanos::CLOCK = 'monotonic';
    my $mono_explicit = nanos();
    ok(defined $mono_explicit, 'nanos() with explicit monotonic returns a value');
    ok($mono_explicit > 0, 'explicit monotonic is positive');
    ok(abs($mono_explicit - nanos()) < 10_000_000, 'explicit monotonic matches default');
}

# realtime clock via $CLOCK
{
    local $Time::Nanos::CLOCK = 'realtime';

    my $rt_ns = nanos();
    ok(defined $rt_ns, 'realtime nanos() returns a value');
    ok($rt_ns > 0, 'realtime nanoseconds is positive');

    my ($rt_sec                , $rt_nsec) = nanos(1);
    ok(defined $rt_sec         , 'realtime seconds defined');
    ok(defined $rt_nsec        , 'realtime nanoseconds component defined');
    ok($rt_sec > 0             , 'realtime seconds is positive');
    ok($rt_nsec >= 0           , 'realtime nsec component is non-negative');
    ok($rt_nsec < 1_000_000_000, 'realtime nsec component < 1e9');

    my $rt_combined = $rt_sec * 1_000_000_000 + $rt_nsec;
    ok(abs($rt_combined - $rt_ns) < 1_000_000, 'realtime combined and scalar values are consistent');

    my $rt_us = micros();
    ok(defined $rt_us, 'realtime micros() returns a value');
    ok($rt_us > 0, 'realtime microseconds is positive');

    my $rt_ms = millis();
    ok(defined $rt_ms, 'realtime millis() returns a value');
    ok($rt_ms > 0, 'realtime milliseconds is positive');
}

# unknown clock source croaks
{
    local $Time::Nanos::CLOCK = 'invalid';
    eval { nanos() };
    ok($@  , 'unknown clock source croaks');
    like($@, qr/unknown clock source/, 'error mentions unknown clock source');
}

# micros and millis are exported
ok(defined &micros, 'micros is exported');
ok(defined &millis, 'millis is exported');

my $us = micros();
ok(defined $us, 'micros() returns a value');
ok($us > 0    , 'microseconds value is positive');

my $ms = millis();
ok(defined $ms, 'millis() returns a value');
ok($ms > 0    , 'milliseconds value is positive');

# micros(1) list context
my ($us_sec, $us_usec) = micros(1);

ok(defined $us_sec     , 'micros(1) seconds defined');
ok(defined $us_usec    , 'micros(1) microseconds defined');
ok($us_sec > 0         , 'micros(1) seconds is positive');
ok($us_usec >= 0       , 'micros(1) microseconds is non-negative');
ok($us_usec < 1_000_000, 'micros(1) microseconds < 1e6');

# millis(1) list context
my ($ms_sec, $ms_msec) = millis(1);

ok(defined $ms_sec,  'millis(1) seconds defined');
ok(defined $ms_msec, 'millis(1) milliseconds defined');
ok($ms_sec > 0,      'millis(1) seconds is positive');
ok($ms_msec >= 0,    'millis(1) milliseconds is non-negative');
ok($ms_msec < 1_000, 'millis(1) milliseconds < 1000');

done_testing();
