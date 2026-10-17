#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

my $K = 'Time::Keeper';
my $D = 'Time::Keeper::Duration';
sub t { $K->new(@_) }
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}

# The end of the month.
{
    my $j31 = t(year => 2026, month => 1, day => 31);
    is($j31->plus(months => 1) . '', '2026-03-03T00:00:00Z', '31 January and a month wraps to 3 March');
    is(t(year => 2028, month => 1, day => 31)->plus(months => 1) . '', '2028-03-02T00:00:00Z', 'or 2 March in a leap year');
    is($j31->plus(months => 1, end_of_month => 'limit') . '', '2026-02-28T00:00:00Z', 'limit stops at 28 February');
    is($j31->plus(months => 1, end_of_month => 'preserve') . '', '2026-02-28T00:00:00Z', 'preserve: the last day to the last day');
    is(t(year => 2026, month => 2, day => 28)->plus(months => 1, end_of_month => 'preserve') . '',
       '2026-03-31T00:00:00Z', 'the last of February to the last of March');
    is(t(year => 2026, month => 2, day => 28)->plus(months => 1) . '', '2026-03-28T00:00:00Z', 'but wrap keeps the 28th');
    is(t(year => 2026, month => 3, day => 30)->plus(months => -1) . '', '2026-02-28T00:00:00Z',
       '30 March less a month: preserve, and the 30th is not the last, so it is limited');
    is(t(year => 2026, month => 3, day => 31)->minus(months => 1) . '', '2026-02-28T00:00:00Z', 'minus a month preserves');
    is(t(year => 2024, month => 2, day => 29)->plus(years => 1) . '', '2025-03-01T00:00:00Z', '29 February and a year wraps');
    is(t(year => 2024, month => 2, day => 29)->plus(years => 1, end_of_month => 'limit') . '', '2025-02-28T00:00:00Z', 'or limits');
    is(t(year => 2026, month => 12, day => 15)->plus(months => 14) . '', '2028-02-15T00:00:00Z', 'over the end of a year');
    is(t(year => 2026, month => 1, day => 15)->plus(months => -13) . '', '2024-12-15T00:00:00Z', 'and back over it');
}

# Months before days (K12).
is(t(year => 2026, month => 1, day => 31)->plus(months => 1, days => 1) . '', '2026-03-04T00:00:00Z',
   'months first: 3 March, then a day');

# The clocks changing.
{
    my $ny = t(year => 2026, month => 3, day => 7, hour => 12, zone => 'America/New_York');
    is($ny->plus(days => 1) . '', '2026-03-08T12:00:00-04:00', 'a day across spring forward keeps noon');
    is($ny->plus(hours => 24) . '', '2026-03-08T13:00:00-04:00', '24 hours does not');
    my $lh = t(year => 2026, month => 10, day => 3, hour => 12, zone => 'Australia/Lord_Howe');
    is($lh->plus(days => 1) . '', '2026-10-04T12:00:00+11:00', 'Lord Howe: a day keeps noon over its half-hour change');
    is($lh->plus(hours => 24) . '', '2026-10-04T12:30:00+11:00', 'and 24 hours is half an hour more');
    my $before = t(year => 2026, month => 3, day => 7, hour => 2, minute => 30, zone => 'America/New_York');
    dies_like(sub { $before->plus(days => 1) }, qr/did not happen in America\/New_York/, 'a day on into the gap croaks');
    is($before->plus(days => 1, gap => 'forward') . '', '2026-03-08T03:30:00-04:00', 'unless told what to do');
    is($before->plus($D->new(days => 1), gap => 'backward') . '', '2026-03-08T01:30:00-05:00', 'with a duration too');
    my $lon = t(year => 2026, month => 10, day => 24, hour => 1, minute => 30, zone => 'Europe/London');
    is($lon->plus(days => 1) . '', '2026-10-25T01:30:00+01:00', 'a day on into an overlap: the earlier');
    is($lon->plus(days => 1, overlap => 'later') . '', '2026-10-25T01:30:00+00:00', 'or the later');
}

# Leap seconds, and nanoseconds carried.
{
    my $l = t(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 59);
    is($l->plus(seconds => 1) . '', '2016-12-31T23:59:60Z', 'a second on is the leap second');
    is($l->plus(seconds => 2) . '', '2017-01-01T00:00:00Z', 'two is midnight');
    is($l->plus(minutes => 1) . '', '2017-01-01T00:00:59Z', 'a minute is 60 seconds of clock time');
    is($l->plus(seconds => 1)->plus(minutes => 1) . '', '2017-01-01T00:01:00Z', 'a minute after the leap second');
    is(t(year => 2017)->minus(seconds => 1) . '', '2016-12-31T23:59:60Z', 'and back');
    is(t(year => 2026, nanosecond => 999_999_999)->plus(nanoseconds => 2) . '', '2026-01-01T00:00:01.000000001Z', 'nanoseconds carry');
    is(t(year => 2026)->minus(nanoseconds => 1) . '', '2025-12-31T23:59:59.999999999Z', 'and borrow');
    my $f = t(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 59, zone => 'floating');
    is($f->plus(seconds => 1) . '', '2017-01-01T00:00:00', 'floating time has no leap seconds');
}

# Differences round-trip (K12).
{
    srand(12);
    my @zones = ('UTC', 'floating', '+05:30', 'America/New_York', 'Europe/London', 'Australia/Lord_Howe',
                 'Asia/Kathmandu', 'Pacific/Apia', 'Europe/Dublin', 'America/Santiago');
    my ($n, $bad, $signs) = (0, 0, 0);
    for (1 .. 6000) {
        my $zone = $zones[int rand @zones];
        my $a = $K->from_epoch(1_000_000_000 + int(rand(1_000_000_000)) . '.' . int(rand(1e9)), zone => $zone);
        my $b = $K->from_epoch(1_000_000_000 + int(rand(1_000_000_000)) . '.' . int(rand(1e9)), zone => $zone);
        $a = $a->as_floating->in_zone('floating') if $zone eq 'floating';
        my $d = $b - $a;
        my $back = eval { $a + $d };
        $n++;
        if (!$back || $back != $b) {
            diag("$zone: $a + $d = " . ($back // "died: $@") . ", wanted $b") if $bad < 5;
            $bad++;
        }
        my %p = $d->deltas;
        my @s = grep { $_ } map { $_ <=> 0 } values %p;
        $signs++ if grep { $_ != $s[0] } @s;
    }
    is($bad, 0, "$n random differences in ten zones and floating time all add back exactly");
    is($signs, 0, 'and every part of each has the one sign');
}
{
    my $a = t(year => 2022, month => 12, day => 7, hour => 23, minute => 34, second => 50);
    my $b = t(year => 2024, month => 3, day => 1, hour => 7, minute => 41, second => 59);
    is(($b - $a) . '', 'P1Y2M22DT8H7M9S', 'the pair DateTime does not round-trip');
    ok($a + ($b - $a) == $b, 'does here');
    is(($a - $b) . '', '-P1Y2M24DT8H7M9S', 'backwards, all negative, and not simply the negation: 1 March less 14 months is 1 January, then 24 days back to 8 December');
    ok($b + ($a - $b) == $a, 'and adds back');
    is($b->minus($a) . '', 'P1Y2M22DT8H7M9S', 'minus with a value is the difference');
    my $ny1 = t(year => 2026, month => 3, day => 7, hour => 12, zone => 'America/New_York');
    my $ny2 = t(year => 2026, month => 3, day => 8, hour => 12, zone => 'America/New_York');
    is(($ny2 - $ny1) . '', 'P1D', 'noon to noon over spring forward is a day');
    is($ny2->minus_absolute($ny1) . '', 'PT82800S', 'and 23 hours passed');
    my $l1 = t(year => 2016, month => 12, day => 31, hour => 23, minute => 59);
    is(t(year => 2017)->minus_absolute($l1)->total_seconds, 61, 'a minute with a leap second in it is 61 seconds');
}

# Corners of the difference.
{
    my $a = t(year => 2026, month => 1, day => 15, nanosecond => 750_000_000);
    my $b = t(year => 2026, month => 2, day => 15, nanosecond => 250_000_000);
    is(($b - $a) . '', 'P30DT23H59M59.5S', 'a month on would overshoot by half a second: 30 days and the rest');
    my $c = t(year => 2026, month => 1, day => 31, hour => 12);
    my $e = t(year => 2026, month => 2, day => 1, hour => 6);
    is(($e - $c) . '', 'PT18H', 'over a month end in less than a day: no months, no days');
    ok($c + ($e - $c) == $e, 'and it adds back');
    my $g1 = t(year => 2009, month => 11, day => 1, hour => 0, minute => 0, second => 30, zone => 'America/Goose_Bay');
    my $g2 = $g1->plus(minutes => 2);
    is($g2 . '', '2009-10-31T23:02:30-04:00', 'Goose Bay went back over midnight into October');
    is(($g2 - $g1) . '', 'PT2M', 'two minutes later, though a month earlier on the clock');
    ok($g1 + ($g2 - $g1) == $g2, 'and it adds back');
    is(t(year => 0, month => 1)->minus(months => 1) . '', '-000001-12-01T00:00:00Z', 'a month back from year 0');
    is(t(year => -1, month => 12, day => 15)->plus(months => 13) . '', '0001-01-15T00:00:00Z', 'and on over it');
    is(t(year => 0, month => 1, day => 31)->minus(months => 2, end_of_month => 'limit') . '', '-000001-11-30T00:00:00Z',
       'two months back from 31 January of year 0, limited to 30 November');
    is(t(year => 0, month => 3, day => 31)->minus(months => 15) . '', '-000002-12-31T00:00:00Z', 'and 15 back, preserved: three months is December of -1, fifteen December of -2');
    my $second = t(year => 2026, month => 11, day => 1, hour => 1, minute => 30, zone => 'America/New_York', overlap => 'later');
    my $next = t(year => 2026, month => 11, day => 2, hour => 1, zone => 'America/New_York');
    is(($next - $second) . '', 'PT23H30M', 'from the second 01:30 of an overlap to 01:00 the next day');
    ok($second + ($next - $second) == $next, 'adds back, from the second reading and not the first');
    is(t(year => 2026, hour => 1, nanosecond => 900_000_000)->delta_ms(t(year => 2026, nanosecond => 100_000_000)) . '',
       'PT1H', 'delta_ms has no fractions of a second');
}

is(t(year => 2026, month => 3, day => 15)->delta_days(t(year => 2026, month => 1, day => 1)) . '', 'P73D', 'delta_days');
is(t(year => 2026, month => 1, day => 1)->delta_days(t(year => 2026, month => 3, day => 15)) . '', 'P73D', 'never negative');
is(t(year => 2026, month => 3, day => 15)->delta_md(t(year => 2026, month => 1, day => 31)) . '', 'P1M12D', 'delta_md');
is(t(year => 2026, month => 1, day => 1, hour => 2)->delta_ms(t(year => 2025, month => 12, day => 31, hour => 23, minute => 30)) . '',
   'PT2H30M', 'delta_ms');

# truncate and round.
{
    my $t = t(year => 2026, month => 10, day => 15, hour => 9, minute => 41, second => 17, nanosecond => 5);
    my %want = (year => '2026-01-01T00:00:00Z', quarter => '2026-10-01T00:00:00Z', month => '2026-10-01T00:00:00Z',
                week => '2026-10-12T00:00:00Z', day => '2026-10-15T00:00:00Z', hour => '2026-10-15T09:00:00Z',
                minute => '2026-10-15T09:41:00Z', second => '2026-10-15T09:41:17Z');
    is($t->truncate(to => $_) . '', $want{$_}, "truncate to $_") for sort keys %want;
    is(t(year => 2026, month => 9, day => 6, hour => 12, zone => 'America/Santiago')->truncate(to => 'day') . '',
       '2026-09-06T01:00:00-03:00', 'a day whose midnight did not happen starts at 01:00');
    my $second = t(year => 2026, month => 11, day => 1, hour => 1, minute => 30, zone => 'America/New_York', overlap => 'later');
    is($second->truncate(to => 'hour') . '', '2026-11-01T01:00:00-05:00', 'the second 01:30 truncates to the second 01:00');
    is(t(year => 2026, month => 11, day => 1, hour => 1, minute => 30, zone => 'America/New_York')->truncate(to => 'hour') . '',
       '2026-11-01T01:00:00-04:00', 'and the first to the first');
    is($t->round(to => 'hour') . '', '2026-10-15T10:00:00Z', 'round to the hour');
    is($t->round(to => 'minute') . '', '2026-10-15T09:41:00Z', 'to the minute');
    is(t(year => 2026, minute => 30)->round(to => 'hour') . '', '2026-01-01T01:00:00Z', 'half way rounds up');
    is($t->round(to => 'month') . '', '2026-10-01T00:00:00Z', 'to the month');
    dies_like(sub { $t->truncate(to => 'fortnight') }, qr/'fortnight' is not year, quarter/, 'a unit it does not know');
    dies_like(sub { $t->truncate('day') }, qr/say to =>/, 'truncate wants to =>');
}

dies_like(sub { my $x = t(year => 2026) + 5 }, qr/takes a Time::Keeper::Duration/, 'a value plus a number');
dies_like(sub { my $x = $D->new(days => 1) - t(year => 2026) }, qr/a duration minus a value means nothing/, 'a duration minus a value');
is(($D->new(days => 1) + t(year => 2026)) . '', '2026-01-02T00:00:00Z', 'a duration plus a value');
dies_like(sub { t(year => 999_999_999, month => 12, day => 31)->plus(days => 1) }, qr/out of range/, 'past the last day');

done_testing;
