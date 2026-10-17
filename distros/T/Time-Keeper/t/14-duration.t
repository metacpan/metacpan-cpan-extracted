#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

my $D = 'Time::Keeper::Duration';
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}

my $d = $D->new(years => 1, months => 2, weeks => 3, days => 4, hours => 5, minutes => 6,
                seconds => 7, nanoseconds => 8);
isa_ok($d, $D);
is_deeply({ $d->deltas }, { months => 14, days => 25, minutes => 306, seconds => 7, nanoseconds => 8 },
          'years fold into months, weeks into days, hours into minutes');
is_deeply([map { $d->$_ } qw(years months weeks days hours minutes seconds nanoseconds)],
          [1, 2, 3, 4, 5, 6, 7, 8], 'each unit, as DateTime gives them');
is("$d", 'P1Y2M25DT5H6M7.000000008S', 'its ISO 8601 form');
is($d->end_of_month, 'wrap', 'a positive duration wraps');

# Seconds and nanoseconds, on integers only.
{
    my $x = $D->new(seconds => 662774409, nanoseconds => 999999999);
    is_deeply([$x->in_units('seconds', 'nanoseconds')], [662774409, 999999999],
              'the pair DateTime::Duration rounds up a second stays exact');
    is_deeply([$D->new(nanoseconds => 2_500_000_000)->in_units('seconds', 'nanoseconds')], [2, 500000000],
              'nanoseconds past a second carry into the seconds');
    is_deeply([$D->new(seconds => 1, nanoseconds => -250_000_000)->in_units('seconds', 'nanoseconds')], [0, 750000000],
              'seconds and nanoseconds take one sign');
    is_deeply([$D->new(seconds => -1, nanoseconds => 250_000_000)->in_units('seconds', 'nanoseconds')], [0, -750000000],
              'the other way too');
    is($D->new(seconds => 3, nanoseconds => 5)->in_units('nanoseconds'), 3_000_000_005, 'nanoseconds alone take the seconds');
}

# in_units, as DateTime: each unit from its own part.
{
    my $x = $D->new(months => 30, days => 10, minutes => 135, seconds => 70);
    is_deeply([$x->in_units('years', 'months')], [2, 6], 'years and months');
    is_deeply([$x->in_units('months')], [30], 'months alone');
    is_deeply([$x->in_units('weeks', 'days')], [1, 3], 'weeks and days');
    is_deeply([$x->in_units('hours', 'minutes', 'seconds')], [2, 15, 70], 'seconds are not made minutes');
    is(scalar $x->in_units('days', 'weeks'), 3, 'in scalar context, the first asked for');
    dies_like(sub { $x->in_units('fortnights') }, qr/'fortnights' is not a unit/, 'a unit it does not know');
    my $n = $D->new(months => -14, minutes => -90);
    is_deeply([$n->in_units('years', 'months', 'hours', 'minutes')], [-1, -2, -1, -30], 'in_units keeps the sign');
    is_deeply([map { $n->$_ } qw(years months hours minutes)], [1, 2, 1, 30], 'the accessors do not');
}

ok($D->new(days => 1)->is_positive, 'a day is positive');
ok($D->new(days => -1)->is_negative, 'minus a day is negative');
ok($D->new->is_zero, 'nothing is zero');
my $mixed = $D->new(months => 1, days => -2);
ok(!$mixed->is_positive && !$mixed->is_negative && !$mixed->is_zero, 'a month forward and two days back is none of them');
is("$mixed", 'P1M-2D', 'and has each part signed in its string');
is($D->new . '', 'PT0S', 'nothing is PT0S');
is($D->new(days => -1, hours => -2) . '', '-P1DT2H', 'a negative duration');
is($D->new(nanoseconds => -500_000_000) . '', '-PT0.5S', 'half a second back');
ok(!$D->new, 'nothing is false');
ok($D->new(seconds => 1), 'anything else is true');

is($D->new(months => -1)->end_of_month, 'preserve', 'a negative number of months preserves');
is($D->new(months => 1, end_of_month => 'limit')->end_of_month, 'limit', 'or what it is told');
is($D->new(months => 1)->inverse->end_of_month, 'preserve', 'the inverse of a month preserves');
is($D->new(months => 1)->inverse(end_of_month => 'limit')->end_of_month, 'limit', 'unless told');
is($D->new(months => 1, days => -2)->inverse . '', 'P-1M2D', 'inverse turns each sign');
is($d->calendar_duration . '', 'P1Y2M25D', 'calendar_duration');
is($d->clock_duration . '', 'PT5H6M7.000000008S', 'clock_duration');

is($D->new(days => 1)->plus($D->new(hours => 1)) . '', 'P1DT1H', 'plus');
is(($D->new(days => 1) + $D->new(hours => 1)) . '', 'P1DT1H', '+');
is(($D->new(days => 1) - $D->new(days => 3)) . '', '-P2D', '-');
is($D->new(days => 1)->minus($D->new(days => 3)) . '', '-P2D', 'minus');
is((-$D->new(days => 1)) . '', '-P1D', 'unary minus');
is(($D->new(seconds => 1, nanoseconds => 600_000_000) * 3) . '', 'PT4.8S', '*, carrying nanoseconds');
is($D->new(days => 2)->multiply(-3) . '', '-P6D', 'multiply');
dies_like(sub { my $x = $D->new(days => 1) * 1.5 }, qr/multiplied only by an integer/, 'by a fraction');

is($D->new(hours => 1) <=> $D->new(minutes => 60), 0, 'an hour is 60 minutes');
ok($D->new(seconds => 61) > $D->new(minutes => 1), '61 seconds is longer than a minute');
dies_like(sub { my $x = $D->new(days => 1) <=> $D->new(hours => 24) }, qr/compare only from a starting point/,
          'a day against 24 hours needs a starting point');
{
    my $jan = Time::Keeper->new(year => 2026, month => 1, day => 1);
    my $feb = Time::Keeper->new(year => 2026, month => 2, day => 1);
    is($D->compare($D->new(months => 1), $D->new(days => 30), $jan), 1, 'a month from 1 January is longer than 30 days');
    is($D->compare($D->new(months => 1), $D->new(days => 30), $feb), -1, 'and from 1 February shorter');
}

is($D->from_seconds(90)->total_seconds, 90, 'from_seconds and total_seconds');
is_deeply([$D->from_seconds('1.000000001')->in_units('seconds', 'nanoseconds')], [1, 1], 'a string to the nanosecond');
is_deeply([$D->from_seconds('-1.5')->in_units('seconds', 'nanoseconds')], [-1, -500000000], 'a negative string');
is($D->new(hours => 1, seconds => 1)->total_seconds, 3601, 'total_seconds counts the minutes');
dies_like(sub { $D->new(days => 1)->total_seconds }, qr/not a number of seconds/, 'not for a duration with days');

dies_like(sub { $D->new(days => 1.5) }, qr/days is not an integer/, 'a fraction of a day');
dies_like(sub { $D->new(fortnights => 1) }, qr/unknown argument 'fortnights'/, 'a unit it does not know');
dies_like(sub { $D->new(days => 1, days => 2) }, qr/days given twice/, 'twice');
dies_like(sub { $D->new(end_of_month => 'wobble') }, qr/end_of_month is 'wrap', 'limit' or 'preserve'/, 'an end_of_month it does not know');
dies_like(sub { $D->new(years => 2**60) }, qr/out of range/, 'too many years');
dies_like(sub { Time::Keeper::Duration::days('x') }, qr/not a Time::Keeper::Duration/, 'a method on something that is not one');
dies_like(sub { my $x = $D->new(days => 1) + 3 }, qr/takes another duration/, 'a duration plus a number');

done_testing;
