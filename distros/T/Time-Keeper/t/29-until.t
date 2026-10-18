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
sub units { my ($d, @u) = @_; join ',', $d->in_units(@u) }

my $a = t(year => 2026, month => 1, day => 31, hour => 22);
my $b = t(year => 2026, month => 3, day => 4, hour => 1, minute => 30, second => 15, nanosecond => 500_000_000);

# largest.
{
    is($a->until($b) . '', ($b - $a) . '', 'until with no options is the difference');
    is($a->until($b) . '', 'P1MT3H30M15.5S', 'months, then days, then the clock');
    is($a->until($b, largest => 'years') . '', 'P1MT3H30M15.5S', 'years are months');
    is($a->until($b, largest => 'days') . '', 'P31DT3H30M15.5S', 'days: no months');
    is(units($a->until($b, largest => 'weeks'), 'weeks', 'days'), '4,3', 'weeks are days');
    is(units($a->until($b, largest => 'hours'), 'hours', 'minutes', 'seconds', 'nanoseconds'), '747,30,15,500000000',
       'hours: minutes and seconds');
    is(units($a->until($b, largest => 'minutes'), 'minutes', 'seconds'), '44850,15', 'minutes likewise');
    is(units($a->until($b, largest => 'seconds'), 'minutes', 'seconds', 'nanoseconds'), '0,2691015,500000000',
       'seconds alone: the time that passed');
    is($a->until($b, largest => 'seconds')->total_seconds, 2691015.5, 'as total_seconds says');
    is($b->since($a) . '', $a->until($b) . '', 'since is until with the values swapped');
    is($b->since($a, largest => 'days') . '', 'P31DT3H30M15.5S', 'with options');
    is($b->until($a, largest => 'hours') . '', '-PT747H30M15.5S', 'backwards is negative');
    is($a->until($a) . '', 'PT0S', 'nothing between a value and itself');
    is($a->until($b)->end_of_month, 'wrap', 'the end-of-month rule is the difference\'s');
}

# smallest and the modes.
{
    is($a->until($b, smallest => 'hours') . '', 'P1MT3H', 'smallest hours truncates');
    is($a->until($b, smallest => 'hours', mode => 'half_ceil') . '', 'P1MT4H', 'half_ceil rounds 3:30 up');
    is($a->until($b, smallest => 'hours', mode => 'half_floor') . '', 'P1MT4H', 'and so does half_floor: it is past the half');
    is($a->until($b, smallest => 'hours', mode => 'floor') . '', 'P1MT3H', 'floor');
    is($a->until($b, smallest => 'hours', mode => 'ceil') . '', 'P1MT4H', 'ceil');
    is($a->until($b, smallest => 'hours', mode => 'expand') . '', 'P1MT4H', 'expand is ceil for a positive duration');
    is($a->until($b, smallest => 'days') . '', 'P1M', 'smallest days');
    is($a->until($b, smallest => 'days', mode => 'half_ceil') . '', 'P1M', '3.5 hours of a day is under half');
    is($a->until($b, smallest => 'days', mode => 'ceil') . '', 'P1M1D', 'ceil adds the day');
    is($a->until($b, largest => 'days', smallest => 'days') . '', 'P31D', 'with largest days');
    is($a->until($b, smallest => 'months') . '', 'P1M', 'smallest months');
    is($a->until($b, smallest => 'months', mode => 'ceil') . '', 'P2M', 'ceil to two');
    is($a->until($b, smallest => 'years', mode => 'ceil') . '', 'P1Y', 'ceil to a year');
    is($a->until($b, smallest => 'years') . '', 'PT0S', 'and trunc to none');
    is($a->until($b, smallest => 'minutes', increment => 15) . '', 'P1MT3H30M', 'minutes in 15s, truncated');
    is($a->until($b, smallest => 'minutes', increment => 15, mode => 'ceil') . '', 'P1MT3H45M', 'ceil');
    is($a->until($b, smallest => 'minutes', increment => 15, mode => 'half_ceil') . '', 'P1MT3H30M', '15 s into 15 minutes is under half');
    is($a->until($b, smallest => 'seconds') . '', 'P1MT3H30M15S', 'the half second dropped');
    is($a->until($b, smallest => 'seconds', mode => 'half_ceil') . '', 'P1MT3H30M16S', 'or rounded up');
    is($a->until($b, smallest => 'seconds', mode => 'half_floor') . '', 'P1MT3H30M15S', 'a tie goes down with half_floor');
    is($a->until($b, smallest => 'seconds', mode => 'half_even') . '', 'P1MT3H30M16S', 'half_even: second 12615 of the duration is odd, up');
    is($a->until($b, smallest => 'milliseconds', increment => 250) . '', 'P1MT3H30M15.5S', '500 ms is a multiple of 250');
    is($a->until($b, largest => 'hours', smallest => 'hours') . '', 'PT747H', 'hours alone');
    is($a->until($b, largest => 'seconds', smallest => 'seconds', increment => 10) . '', 'PT2691010S', 'seconds in tens');
    is($a->until($b, largest => 'nanoseconds', smallest => 'nanoseconds') . '', 'PT2691015.5S', 'nanoseconds change nothing');
}

# Negative durations and the modes.
{
    my $b2 = $b->with(second => 0, nanosecond => 0);
    is($b2->until($a, largest => 'hours') . '', '-PT747H30M', 'a tie, backwards');
    is($b2->until($a, largest => 'hours', smallest => 'hours') . '', '-PT747H', 'trunc is towards zero');
    is($b2->until($a, largest => 'hours', smallest => 'hours', mode => 'floor') . '', '-PT748H', 'floor is away from it');
    is($b2->until($a, largest => 'hours', smallest => 'hours', mode => 'ceil') . '', '-PT747H', 'ceil towards it');
    is($b2->until($a, largest => 'hours', smallest => 'hours', mode => 'expand') . '', '-PT748H', 'expand away');
    is($b2->until($a, largest => 'hours', smallest => 'hours', mode => 'half_ceil') . '', '-PT747H', 'half_ceil: the tie goes towards plus infinity');
    is($b2->until($a, largest => 'hours', smallest => 'hours', mode => 'half_floor') . '', '-PT748H', 'half_floor: towards minus');
    is($b2->until($a, largest => 'hours', smallest => 'hours', mode => 'half_even') . '', '-PT748H', 'half_even: 747 is odd, so 748');
    is($b->until($a, largest => 'hours', smallest => 'hours', mode => 'half_ceil') . '', '-PT748H', 'past the half: nearer -748');
    is($b->until($a, largest => 'hours', smallest => 'hours', mode => 'half_floor') . '', '-PT748H', 'for both half modes');
    is($b->until($a, smallest => 'days') . '', '-P1M3D', 'backwards with months: a month back from 4 March 01:30 is 4 February, and three days more reach 1 February');
}

# Carrying: a clock part that rounds up into the unit above is balanced again.
{
    my $s = t(year => 2026, month => 3, day => 1);
    my $e = $s->plus(days => 1, hours => 23, minutes => 59);
    is($s->until($e, largest => 'days', smallest => 'hours') . '', 'P1DT23H', 'truncated, 23 hours stay');
    is($s->until($e, largest => 'days', smallest => 'hours', mode => 'half_ceil') . '', 'P2D', 'rounded up, 24 hours are a day');
    is($s->until($e, largest => 'hours', smallest => 'hours', mode => 'half_ceil') . '', 'PT48H', 'or 48 hours when days are not allowed');
    is($s->until($s->plus(months => 1, days => 27, hours => 23), smallest => 'days', mode => 'half_ceil') . '', 'P1M28D',
       '27 days 23 hours from 1 April is 28 days, not a second month: April has 30');
    is($s->plus(days => 30)->until($s->plus(months => 2)->minus(hours => 1), smallest => 'days', mode => 'half_ceil') . '', 'P31D',
       '30 days 23 hours from 31 March: a month would overshoot 30 April, so it is days, and 23 hours round up to the 31st');
}

# Round trips (K12 holds for every largest).
{
    srand(20261017);
    my $bad = 0;
    my @zones = ('UTC', 'Europe/London', 'America/New_York', 'Australia/Lord_Howe');
    for (1 .. 1000) {
        my $z = $zones[int(rand(@zones))];
        my $x = $K->from_epoch(int(rand(3e9)) - 1e9, zone => $z)->plus(nanoseconds => int(rand(1e9)));
        my $y = $K->from_epoch(int(rand(3e9)) - 1e9, zone => $z)->plus(nanoseconds => int(rand(1e9)));
        for my $largest (qw(years months weeks days hours minutes seconds milliseconds)) {
            my $d = $x->until($y, largest => $largest);
            my $back = eval { $x->plus($d) };
            next if $back && $back == $y;
            $bad++;
            diag("$x until $y largest $largest gives $d, back " . ($back // "death: $@"));
        }
        last if $bad > 10;
    }
    is($bad, 0, '1000 random pairs in four zones round-trip for every largest');
}

# Leap seconds: the time that passed counts them (R3).
{
    my $x = t(year => 2016, month => 12, day => 31, hour => 23, minute => 59);
    my $y = t(year => 2017, month => 1, day => 1, hour => 0, minute => 0, second => 30);
    is(units($x->until($y, largest => 'seconds'), 'seconds'), '91', '90 seconds of clock and the leap second');
    is(units($x->until($y, largest => 'minutes'), 'minutes', 'seconds'), '1,30', 'as minutes: one 60-second minute, then 30 seconds');
    is($x->plus($x->until($y, largest => 'seconds')) . '', "$y", 'both add back');
    is($x->plus($x->until($y, largest => 'minutes')) . '', "$y", 'to the same instant');
    is($x->until($y, largest => 'seconds')->total('minutes'), 91 / 60, 'total counts it');
}

# Across a change of the clocks.
{
    my $ny = t(year => 2026, month => 3, day => 7, hour => 12, zone => 'America/New_York');
    my $next = $ny->plus(days => 1);
    is($ny->until($next, largest => 'hours') . '', 'PT23H', 'a 23-hour day in hours');
    is($ny->until($next, largest => 'days') . '', 'P1D', 'and in days');
    is($ny->until($next, largest => 'days', smallest => 'days', mode => 'half_ceil') . '', 'P1D', 'rounded to days: exactly one');
    is($ny->until($next->plus(hours => 11), largest => 'days', smallest => 'days', mode => 'half_ceil') . '', 'P1D',
       '11 hours into a 24-hour day is under half');
    is($ny->until($next->plus(hours => 13), largest => 'days', smallest => 'days', mode => 'half_ceil') . '', 'P2D', '13 is over');
    is($ny->until($next->plus(hours => 12), largest => 'days', smallest => 'days', mode => 'half_ceil') . '', 'P2D', 'and 12 is the tie, later');
}

# Bad arguments.
{
    dies_like(sub { $a->until($b, largest => 'hours', smallest => 'days') }, qr/smallest \(days\) is a larger unit than largest \(hours\)/,
              'smallest above largest');
    dies_like(sub { $a->until($b, largest => 'quarters') }, qr/largest cannot be quarters: a duration has none/, 'quarters');
    dies_like(sub { $a->until($b, smallest => 'fortnights') }, qr/'fortnights' is not year, quarter/, 'a unit it does not know');
    dies_like(sub { $a->until($b, smallest => 'minutes', increment => 7) }, qr/increment 7 does not divide the 60 minutes/, 'a bad increment');
    dies_like(sub { $a->until($b, smallest => 'days', increment => 2) }, qr/increment 2 is out of range/, 'no increments of days');
    dies_like(sub { $a->until($b, mode => 'round') }, qr/mode is 'floor'.*not 'round'/, 'a bad mode');
    dies_like(sub { $a->until(3) }, qr/not a Time::Keeper value/, 'until wants a value');
    dies_like(sub { $a->until($b, 'hours') }, qr/name => value pairs/, 'pairs');
    dies_like(sub { $a->until($b, to => 'hours') }, qr/unknown argument 'to'/, 'not round\'s key');
}

# Duration->total.
{
    is($D->new(hours => 49, minutes => 30)->total('hours'), 49.5, '49 hours 30 minutes in hours');
    is($D->new(hours => 49, minutes => 30)->total('minutes'), 2970, 'in minutes, an integer');
    is($D->new(hours => 49, minutes => 30)->total('seconds'), 178200, 'in seconds');
    is($D->new(seconds => 1, nanoseconds => 500_000_000)->total('milliseconds'), 1500, 'in milliseconds');
    is($D->new(hours => 36)->total('days'), 1.5, '36 hours is a day and a half, with no start given');
    cmp_ok(abs($D->new(days => 10)->total('weeks') - 10 / 7), '<', 1e-12, '10 days in weeks');
    is($D->new(days => 10)->total('days'), 10, 'days in days need no start');
    is($D->new(hours => -36)->total('days'), -1.5, 'negative');
    my $jan31 = t(year => 2026, month => 1, day => 31);
    is($D->new(months => 1)->total('days', relative_to => $jan31), 31, 'a month from 31 January is 31 days (it lands on 3 March)');
    is($D->new(months => 1)->total('days', relative_to => t(year => 2026, month => 2, day => 1)), 28, 'and 28 from 1 February');
    is($D->new(days => 45)->total('months', relative_to => t(year => 2026)), 1.5, '45 days from 1 January 2026 is a month and half of February');
    is($D->new(days => 45)->total('years', relative_to => t(year => 2026)), 45 / 365, 'or 45/365 of the year');
    is($D->new(months => -1)->total('days', relative_to => t(year => 2026, month => 3, day => 3)), -28, 'a month back from 3 March is 28 days back');
    is($D->new(days => 1)->total('hours', relative_to => t(year => 2026, month => 3, day => 7, hour => 12, zone => 'America/New_York')), 23,
       'a day from noon on 7 March in New York is 23 hours');
    is($D->new(hours => 23)->total('days', relative_to => t(year => 2026, month => 3, day => 7, hour => 12, zone => 'America/New_York')), 1,
       'and 23 hours from there is a day');
    is($D->new(months => 1, days => 2)->total('weeks', relative_to => $jan31), 33 / 7, 'a month and two days from 31 January in weeks');
    dies_like(sub { $D->new(days => 1, hours => 12)->total('hours') }, qr/a day is not always 24 hours; give relative_to/, 'days need a start for hours');
    dies_like(sub { $D->new(months => 1)->total('days') }, qr/months have no fixed length; give relative_to/, 'months need a start');
    dies_like(sub { $D->new(hours => 1)->total('months') }, qr/months have no fixed length; give relative_to/, 'as does a total in months');
    dies_like(sub { $D->new(hours => 1)->total('quarters') }, qr/the unit cannot be quarters/, 'quarters');
    dies_like(sub { $D->new(hours => 1)->total('hours', relative_to => 'now') }, qr/not a Time::Keeper value/, 'relative_to is a value');
}

# Duration->balance.
{
    my $jan31 = t(year => 2026, month => 1, day => 31);
    is($D->new(months => 1, days => 2)->balance(largest => 'days', relative_to => $jan31) . '', 'P33D', 'a month and two days from 31 January is 33 days');
    is(units($D->new(months => 1, days => 2)->balance(largest => 'weeks', relative_to => $jan31), 'weeks', 'days'), '4,5', 'or 4 weeks 5 days');
    is($D->new(days => 33)->balance(relative_to => $jan31) . '', 'P1M2D', 'and back');
    is($D->new(days => 33)->balance(largest => 'months', relative_to => t(year => 2026, month => 2, day => 1)) . '', 'P1M5D', 'from 1 February, a month is 28 days');
    is(units($D->new(minutes => 90)->balance(largest => 'hours'), 'hours', 'minutes'), '1,30', '90 minutes is an hour and a half, from nowhere');
    is($D->new(hours => 36)->balance(largest => 'days') . '', 'P1DT12H', '36 hours is a day and a half');
    is($D->new(days => 1, hours => 12)->balance(largest => 'hours', relative_to => $jan31) . '', 'PT36H', 'and back, from a start');
    is($D->new(seconds => 3661)->balance(largest => 'hours') . '', 'PT1H1M1S', 'seconds into hours, minutes and seconds');
    is($D->new(seconds => 3661)->balance(largest => 'seconds') . '', 'PT3661S', 'or left alone');
    dies_like(sub { $D->new(months => 1)->balance(largest => 'days') }, qr/months and days have no fixed length; give relative_to/, 'months need a start');
    dies_like(sub { $D->new(hours => 1)->balance(largest => 'quarters') }, qr/largest cannot be quarters/, 'quarters');
}

# Duration->round with relative_to.
{
    my $jan1 = t(year => 2026);
    is($D->new(months => 1, days => 15)->round(to => 'months', relative_to => $jan1) . '', 'P2M', '16 February is past the middle of February');
    is($D->new(months => 1, days => 10)->round(to => 'months', relative_to => $jan1) . '', 'P1M', '11 February is not');
    is($D->new(months => 1, days => 14)->round(to => 'months', relative_to => $jan1) . '', 'P2M', '15 February is the midpoint of a 28-day month: later');
    is($D->new(months => 1, days => 14)->round(to => 'months', mode => 'half_floor', relative_to => $jan1) . '', 'P1M', 'or earlier');
    is($D->new(months => 1, days => 14)->round(to => 'months', mode => 'trunc', relative_to => $jan1) . '', 'P1M', 'trunc');
    is($D->new(hours => 36)->round(to => 'days', relative_to => $jan1) . '', 'P2D', '36 hours to the day is 2 days');
    is($D->new(days => 1, hours => 11)->round(to => 'days', relative_to => $jan1) . '', 'P1D', 'a day and 11 hours is a day');
    is($D->new(days => 1, hours => 11)->round(to => 'hours', increment => 6, relative_to => $jan1) . '', 'P1DT12H', 'to 6 hours');
    is($D->new(months => 1, days => 15)->round(to => 'years', relative_to => $jan1) . '', 'PT0S', 'to the year: under half');
    is($D->new(months => 7)->round(to => 'years', relative_to => $jan1) . '', 'P1Y', '7 months is over half a year');
    is($D->new(hours => 1, minutes => 30)->round(to => 'hours', relative_to => $jan1) . '', 'PT2H', 'the clock rounding agrees with the start-free one');
    is($D->new(hours => 1, minutes => 30)->round(to => 'hours') . '', 'PT2H', 'which is this');
    dies_like(sub { $D->new(days => 1)->round(to => 'hours') }, qr/months or days has no fixed length to round; give relative_to/, 'days need a start');
    dies_like(sub { $D->new(hours => 1)->round(to => 'days') }, qr/days have no fixed length in a duration; give relative_to/, 'to days too');
}

done_testing;
