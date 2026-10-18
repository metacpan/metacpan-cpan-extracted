#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;

use Time::Keeper;

my $K = 'Time::Keeper';
my $D = 'Time::Keeper::Duration';
sub tk { $K->parse(shift) }
sub isos { join ' ', map { $_->iso8601 } @_ }

my ($oct1, $oct31) = (tk('2026-10-01T00:00:00Z'), tk('2026-10-31T00:00:00Z'));
my @days = $oct1->range($oct31, by => 'day');
is(scalar(@days), 31, 'the days of October, end included');
is($days[0]->iso8601, '2026-10-01T00:00:00Z', 'the first is the start');
is($days[-1]->iso8601, '2026-10-31T00:00:00Z', 'the last is the end');
is(scalar(my @ex = $oct1->range($oct31, by => 'days', inclusive => 0)), 30, 'inclusive => 0 drops the end (and the unit may be plural)');
is(isos($oct1->range($oct31, by => 'week')), '2026-10-01T00:00:00Z 2026-10-08T00:00:00Z 2026-10-15T00:00:00Z 2026-10-22T00:00:00Z 2026-10-29T00:00:00Z', 'weeks');
is(scalar(my @h = $oct1->range(tk('2026-10-02T00:00:00Z'), by => 'hour', step => 2, inclusive => 0)), 12, 'step => 2 doubles the unit');
is($h[1]->iso8601, '2026-10-01T02:00:00Z', 'two hours apart');
is(isos($oct1->range($oct1, by => 'day')), '2026-10-01T00:00:00Z', 'start equal to end: one value');
is(scalar(my @none = $oct1->range($oct1, by => 'day', inclusive => 0)), 0, 'and none exclusive');
isa_ok($days[3], 'Time::Keeper', 'a value');

my ($jan31, $may31) = (tk('2026-01-31T12:00:00Z'), tk('2026-05-31T12:00:00Z'));
is(isos($jan31->range($may31, by => 'month')), '2026-01-31T12:00:00Z 2026-03-03T12:00:00Z 2026-03-31T12:00:00Z 2026-05-01T12:00:00Z 2026-05-31T12:00:00Z',
    'months from the 31st wrap as plus does, from the start each time');
is(isos($jan31->range($may31, by => 'month', end_of_month => 'limit')), '2026-01-31T12:00:00Z 2026-02-28T12:00:00Z 2026-03-31T12:00:00Z 2026-04-30T12:00:00Z 2026-05-31T12:00:00Z',
    'end_of_month => limit gives the last day of the short months');
is(isos(tk('2026-01-01T00:00:00Z')->range(tk('2026-05-01T00:00:00Z'), by => $D->new(months => 1, days => 2))), '2026-01-01T00:00:00Z 2026-02-03T00:00:00Z 2026-03-05T00:00:00Z 2026-04-07T00:00:00Z',
    'a duration step of P1M2D');
is(scalar(my @q = tk('2026-01-01T00:00:00Z')->range(tk('2027-01-01T00:00:00Z'), by => 'quarter')), 5, 'quarters');
is(scalar(my @y = tk('2020-02-29T00:00:00Z')->range(tk('2028-02-29T00:00:00Z'), by => 'year')), 9, 'years from 29 February, wrapping');
is($y[1]->iso8601, '2021-03-01T00:00:00Z', 'through 1 March in a common year');

my $ny = 'America/New_York';
my @spring = $K->new(year => 2026, month => 3, day => 8, zone => $ny)->range($K->new(year => 2026, month => 3, day => 9, zone => $ny), by => 'hour', inclusive => 0);
is(scalar(@spring), 23, '23 hours on the day the clocks go forward');
is($spring[2]->strftime('%H:%M %Z'), '03:00 EDT', 'with 02:00 missing');
my @fall = $K->new(year => 2026, month => 11, day => 1, zone => $ny)->range($K->new(year => 2026, month => 11, day => 2, zone => $ny), by => 'hour', inclusive => 0);
is(scalar(@fall), 25, '25 hours on the day they go back');
is(scalar(my @d1 = $K->new(year => 2026, month => 3, day => 8, zone => $ny)->range($K->new(year => 2026, month => 3, day => 9, zone => $ny), by => 'day', inclusive => 0)), 1, 'but one day');
my $gap_start = $K->new(year => 2026, month => 3, day => 7, hour => 2, minute => 30, zone => $ny);
my $gap_end = $K->new(year => 2026, month => 3, day => 9, hour => 12, zone => $ny);
ok(!eval { $gap_start->range($gap_end, by => 'day'); 1 }, 'a day step onto a skipped time dies');
like($@, qr/did not happen|gap/, 'as plus does');
is(isos($gap_start->range($gap_end, by => 'day', gap => 'forward')), '2026-03-07T02:30:00-05:00 2026-03-08T03:30:00-04:00 2026-03-09T02:30:00-04:00', 'gap => forward carries it over');

my @back = $oct31->range($oct1, by => $D->new(days => -1));
is(scalar(@back), 31, 'a negative step walks back');
is($back[1]->iso8601, '2026-10-30T00:00:00Z', 'a day at a time');
is(scalar(my @b2 = $oct31->range($oct1, by => $D->new(hours => -12), step => 2)), 31, 'step multiplies a negative step too');

my $float = $K->new(year => 2026, month => 1, day => 1, zone => 'floating');
is(scalar(my @f = $float->range($K->new(year => 2026, month => 1, day => 10, zone => 'floating'), by => 'day')), 10, 'floating values range');

ok(!eval { $oct1->range($oct31); 1 }, 'by is required');
like($@, qr/by is required/, 'and says so');
ok(!eval { $oct1->range($oct31, by => 'fortnight'); 1 }, 'an unknown unit dies');
ok(!eval { $oct1->range($oct31, by => 'day', step => 0); 1 }, 'step 0 dies');
ok(!eval { $oct1->range($oct31, by => 'day', step => -1); 1 }, 'a negative step dies: the sign is the duration\'s');
ok(!eval { $oct1->range($oct31, by => $D->new); 1 }, 'a zero duration dies');
like($@, qr/the step is zero/, 'naming it');
ok(!eval { $oct1->range($oct31, by => $D->new(months => 1, days => -1)); 1 }, 'a step of both signs dies');
like($@, qr/parts of both signs/, 'naming it');
ok(!eval { $oct31->range($oct1, by => 'day'); 1 }, 'an end before the start with a forward step dies');
like($@, qr/does not move toward the end/, 'naming it');
ok(!eval { $oct1->range($oct31, by => $D->new(days => -1)); 1 }, 'and an end after the start with a backward step');
ok(!eval { $oct1->range($oct31, by => 'day', foo => 1); 1 }, 'an unknown argument dies');
ok(!eval { $oct1->range('2026-10-31', by => 'day'); 1 }, 'a string end dies');
ok(!eval { $oct1->range(tk('2026-10-01T00:00:01Z'), by => 'nanosecond'); 1 }, 'a billion values are refused');
like($@, qr/more than 10000000 values; use iterate/, 'pointing at iterate');
ok(!eval { $jan31->range(tk('2200-01-01T00:00:00Z'), by => 'second'); 1 }, 'and so are 5 billion seconds');
is(scalar(my @ok = $oct1->range(tk('2026-10-01T00:00:00.009Z'), by => 'microsecond')), 9001, 'nine thousand microseconds are not');

for my $case (['month', 10_000_000, 1.11], ['year', 800_000, 1.11], ['week', 10_000_000, 1.001], ['day', 10_000_000, 1.001], ['hour', 10_000_000, 1.001]) {
    my ($unit, $count, $slack) = @$case;
    my $start = tk('2026-01-01T00:00:00Z');
    my $end = $start->plus("${unit}s" => $count - 1);
    my $est = Time::Keeper::_range_estimate($start, $end, by => $unit);
    cmp_ok($est, '>=', $count, "the guard's estimate of $count ${unit}s is never below the truth");
    cmp_ok($est, '<=', $count * $slack, "and not far above it");
}

my $it = $jan31->iterate($may31, by => 'month', end_of_month => 'limit');
is(ref $it, 'CODE', 'iterate gives a code ref');
my @from_it;
while (my $t = $it->()) { push @from_it, $t }
is(isos(@from_it), isos($jan31->range($may31, by => 'month', end_of_month => 'limit')), 'and yields what range lists');
is($it->(), undef, 'undef after the last');
is($it->(), undef, 'and again');
my $a = $oct1->iterate($oct31, by => 'day');
my $b = $oct1->iterate($oct31, by => 'week');
$a->() for 1 .. 3;
is($b->()->iso8601, '2026-10-01T00:00:00Z', 'two iterators keep their own places');
is($a->()->iso8601, '2026-10-04T00:00:00Z', 'the fourth day after three readings');
my $long = $oct1->iterate(tk('2026-10-01T00:00:01Z'), by => 'nanosecond');
is($long->()->nanosecond, 0, 'iterate has no limit');
is($long->()->nanosecond, 1, 'a nanosecond on');
ok(!eval { Time::Keeper::_iterate_step(); 1 }, 'the step called as a plain sub dies');
like($@, qr/not an iterator/, 'naming the fault');
ok(!eval { $oct31->iterate($oct1, by => 'day'); 1 }, 'iterate checks the direction too');

{
    package Time::Keeper::Sub;
    our @ISA = ('Time::Keeper');
}
my $sub = Time::Keeper::Sub->parse('2026-10-01T00:00:00Z');
is(ref +($sub->range($oct31, by => 'week'))[1], 'Time::Keeper::Sub', 'range keeps a subclass');
is(ref $sub->iterate($oct31, by => 'week')->(), 'Time::Keeper::Sub', 'as does iterate');

SKIP: {
    skip 'no ithreads', 2 unless $Config{useithreads} && eval { require threads; 1 };
    my $i = $oct1->iterate($oct31, by => 'day');
    $i->();
    my $got = threads->create(sub { join ' ', map { $i->()->day } 1 .. 2 })->join;
    is($got, '2 3', 'a thread continues its copy of an iterator');
    is($i->()->day, 2, 'and the parent its own');
}

done_testing;
