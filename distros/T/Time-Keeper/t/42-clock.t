#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;

use Time::Keeper;

my $K = 'Time::Keeper';
my $pin = $K->parse('2026-10-15T09:00:00.25Z', locale => 'fr');

{
    local $Time::Keeper::CLOCK = $pin;
    my $t = $K->now;
    is($t->epoch, $pin->epoch, 'now reads a pinned value');
    is($t->nanosecond, 250_000_000, 'to the nanosecond');
    is($t->locale, 'en', 'the pinned locale is not taken');
    is($K->now(zone => 'Asia/Tokyo')->iso8601, '2026-10-15T18:00:00.250+09:00', 'now applies its own zone');
    is($K->now(locale => 'de')->locale, 'de', 'and its own locale');
    is($K->today(zone => 'Asia/Tokyo')->iso8601, '2026-10-15T00:00:00+09:00', 'today in a zone from the pinned clock');
    is($K->today->iso8601, '2026-10-15T00:00:00Z', 'today in UTC');
    my ($sec, $nsec) = Time::Keeper::_now();
    is("$sec.$nsec", $pin->epoch . '.250000000', 'the raw clock door sees it');
    is($K->parse('2026-10-15T06:00:00Z')->format_relative, '3 hours ago', 'format_relative measures from the pinned clock');
    is($K->parse('2026-10-16T09:00:00Z')->format_relative, 'tomorrow', 'in either direction');
    my $d = Time::Keeper::Duration->new(months => 1);
    my $e = Time::Keeper::Duration->new(days => 31);
    is(Time::Keeper::Duration->compare($d, $e), 0, 'Duration->compare starts from the pinned clock (October has 31 days)');
    {
        local $Time::Keeper::CLOCK = $K->parse('2026-02-01T00:00:00Z');
        is($K->now->iso8601, '2026-02-01T00:00:00Z', 'a nested local pins again');
        is(Time::Keeper::Duration->compare($d, $e), -1, 'and compare follows (February is shorter)');
    }
    is($K->now->epoch, $pin->epoch, 'the outer pin is back after the block');
    {
        local $Time::Keeper::CLOCK;
        my $real = time;
        cmp_ok(abs($K->now->epoch - $real), '<', 5, 'undef inside the block restores the system clock');
    }
    is($K->now->epoch, $pin->epoch, 'and the pin after that');
}
cmp_ok(abs($K->now->epoch - time), '<', 5, 'the system clock after the block');

{
    local $Time::Keeper::CLOCK = 1_760_000_000;
    is($K->now->iso8601, '2025-10-09T08:53:20Z', 'an integer epoch pins the clock');
    local $Time::Keeper::CLOCK = '1760000000.5';
    is($K->now->iso8601, '2025-10-09T08:53:20.500Z', 'an epoch string with a fraction');
    local $Time::Keeper::CLOCK = '-1';
    is($K->now->iso8601, '1969-12-31T23:59:59Z', 'a negative epoch');
}

{
    my $t = $K->parse('2026-01-01T00:00:00Z');
    local $Time::Keeper::CLOCK = sub { $t = $t->plus(seconds => 1) };
    is($K->now->iso8601, '2026-01-01T00:00:01Z', 'a code ref is called for the reading');
    is($K->now->iso8601, '2026-01-01T00:00:02Z', 'and again for the next');
    is($K->today->iso8601, '2026-01-01T00:00:00Z', 'today calls it too');
    is($t->iso8601, '2026-01-01T00:00:03Z', 'three readings, three calls');
}

{
    local $Time::Keeper::CLOCK = sub { '1760000000' };
    is($K->now->epoch, 1_760_000_000, 'a code ref may return an epoch');
    local $Time::Keeper::CLOCK = sub { $K->now->plus(hours => 1) };
    my $skew = $K->now->epoch - time;
    ok($skew >= 3598 && $skew <= 3602, "a code ref reading now reads the system clock: an hour fast ($skew s)");
}

{
    local $Time::Keeper::CLOCK = {};
    ok(!eval { $K->now; 1 }, 'a hash ref dies');
    like($@, qr/\$Time::Keeper::CLOCK must be a Time::Keeper value, an epoch or a code ref/, 'naming the variable');
    local $Time::Keeper::CLOCK = 'soon';
    ok(!eval { $K->now; 1 }, 'a word dies');
    like($@, qr/CLOCK/, 'naming the variable');
    local $Time::Keeper::CLOCK = sub { undef };
    ok(!eval { $K->now; 1 }, 'a code ref returning undef dies');
    like($@, qr/the code ref in \$Time::Keeper::CLOCK must be/, 'naming the code ref');
    local $Time::Keeper::CLOCK = sub { return };
    ok(!eval { $K->now; 1 }, 'a code ref returning nothing dies (undef in scalar context)');
    local $Time::Keeper::CLOCK = sub { [] };
    ok(!eval { $K->now; 1 }, 'a code ref returning an array ref dies');
    local $Time::Keeper::CLOCK = '99999999999999999999';
    ok(!eval { $K->now; 1 }, 'an epoch out of range dies');
    local $Time::Keeper::CLOCK = '9223372036854775807';
    ok(!eval { $K->now; 1 }, 'an epoch that fits an integer but not a value dies');
    like($@, qr/out of range/, 'saying so');
    local $Time::Keeper::CLOCK = sub { die "the test's own error\n" };
    ok(!eval { $K->now; 1 }, 'a die inside the code ref propagates');
    is($@, "the test's own error\n", 'as it was thrown');
    local $Time::Keeper::CLOCK = $pin;
    is($K->now->epoch, $pin->epoch, 'the clock is read again after the code ref died');
    local $Time::Keeper::CLOCK = sub { $K->now };
    cmp_ok(abs($K->now->epoch - time), '<', 5, 'a code ref calling now reads the system clock, not the pin');
}

{
    local $Time::Keeper::CLOCK = $K->parse('2030-01-01T00:00:00Z');
    $@ = '';
    my ($step) = Time::Keeper::_abi_selftest(Time::Keeper::_abi_ptr());
    is($step, 0, 'the C ABI selftest passes on a pinned clock in 2030');
    local $Time::Keeper::CLOCK = $K->parse('1970-01-02T00:00:00Z');
    ($step) = Time::Keeper::_abi_selftest(Time::Keeper::_abi_ptr());
    isnt($step, 0, 'and fails its "now is after 2025" check pinned to 1970: the ABI reads the pin');
}

SKIP: {
    skip 'no ithreads', 2 unless $Config{useithreads} && eval { require threads; 1 };
    local $Time::Keeper::CLOCK = $pin;
    my $got = threads->create(sub { Time::Keeper->now->epoch })->join;
    is($got, $pin->epoch, 'a new thread reads the pinned clock');
    my $got2 = threads->create(sub { local $Time::Keeper::CLOCK = 5; Time::Keeper->now->epoch })->join;
    is($got2, 5, 'and its own local');
}

done_testing;
