#!perl
use 5.010;
use strict;
use warnings;
use Config;
BEGIN { if ($Config{useithreads}) { require threads; threads->import } }
use Test::More;

use Time::Keeper;
use Time::Keeper::Business;

my $C = 'Time::Keeper::Business';
sub d { Time::Keeper::Date->parse($_[0]) }
sub ym { Time::Keeper::YearMonth->new(year => $_[0], month => $_[1]) }

my $plain = $C->new;
my $uk = $C->new(holidays => Time::Keeper::Business::Rule->uk, weekend => 'en-GB', zone => 'Europe/London',
                 hours => { default => ['09:00-17:30'], '2026-12-24' => ['09:00-12:00'] });

is($plain->business_days_in(ym(2026, 10)), 22, 'October 2026 has 22 business days');
is($plain->business_days_in(d('2026-10-15')), 22, '  by a date in the month');
is($plain->business_days_in(Time::Keeper->new(year => 2026, month => 10, day => 31, hour => 23, zone => 'Pacific/Auckland')), 22, '  by a Time::Keeper, read in its own zone');
is($plain->business_days_in(Time::Keeper->new(year => 2026, month => 10, day => 31, hour => 23, zone => 'Pacific/Auckland')->in_zone('UTC')), 22, '  (that is still October in UTC too)');
is($plain->business_days_in(Time::Keeper->new(year => 2026, month => 11, day => 1, hour => 1, zone => 'Pacific/Auckland')), 21, '  and 1 November in Auckland is November: 21');
is($plain->business_days_in(year => 2026), 261, '2026 has 261 weekdays');
is($uk->business_days_in(year => 2026), 253, '  and 253 business days in England');
is($uk->business_days_in(ym(2026, 12)), 21, 'December 2026 in England: 23 weekdays less Christmas and the Boxing Day substitute');
is($plain->business_days_in(ym(2028, 2)), 21, 'February of a leap year');

my $dec = $uk->business_hours_in(ym(2026, 12));
isa_ok($dec, 'Time::Keeper::Duration', 'business_hours_in gives a Duration');
is("$dec", 'PT173H', '  December 2026: twenty days of eight and a half and Christmas Eve\'s three');
is($uk->business_hours_in(ym(2026, 12), number => 1), 173, '  or a number');
is($uk->business_hours_in(d('2026-12-24'), number => 1), 3, 'a day');
is($uk->business_hours_in(d('2026-12-25'), number => 1), 0, '  a holiday has none');
is($uk->business_hours_in(year => 2026, number => 1), 252 * 8.5 + 3, 'a year');
my $night = $C->new(zone => 'America/New_York', hours => ['22:00-06:00'], weekend => []);
my $elapsed = $night->with(reckon => 'elapsed');
is($night->business_hours_in(ym(2026, 3), number => 1), 31 * 8, 'March of a night desk on the wall clock');
is($elapsed->business_hours_in(ym(2026, 3), number => 1), 31 * 8 - 1, '  and elapsed: the spring night an hour short');
is($elapsed->business_hours_in(ym(2026, 10), number => 1), 31 * 8 + 1, '  October elapsed: the night into 1 November an hour long, counted on its start day');
ok(!eval { $uk->business_hours_in(Time::Keeper->now); 1 }, 'a Time::Keeper to business_hours_in is refused: give a Date or a YearMonth');
like($@, qr/a value gives its day; give a Time::Keeper::Date for a day/, '  by name');
ok(!eval { $plain->business_hours_in(d('2026-10-15')); 1 }, 'no hours is refused');
like($@, qr/this schedule has no hours/, '  by name');
ok(!eval { $plain->business_days_in; 1 }, 'business_days_in needs a month or a year');
like($@, qr/takes a month/, '  by name');
ok(!eval { $plain->business_days_in(year => 'x'); 1 }, 'a year that is not one');
ok(!eval { $uk->business_hours_in(ym(2026, 12), colour => 1); 1 }, 'an unknown option');
like($@, qr/unknown argument 'colour'/, '  by name');

my $it = $uk->iterate_business_days(d('2026-12-24'));
is(ref $it, 'CODE', 'iterate_business_days gives a code ref');
is(join(' ', map { "" . $it->() } 1 .. 5), '2026-12-24 2026-12-29 2026-12-30 2026-12-31 2027-01-04', 'the business days from the start, holidays and the weekend stepped over');
is(ref $it->(), 'Time::Keeper::Date', '  each of the start\'s class');
my $from_sat = $plain->iterate_business_days(d('2026-10-17'));
is($from_sat->() . '', '2026-10-19', 'a start that is not a business day begins at the next');
my $bounded = $plain->iterate_business_days(d('2026-10-16'), d('2026-10-20'));
my @got;
while (my $x = $bounded->()) { push @got, "$x" }
is_deeply(\@got, [qw(2026-10-16 2026-10-19 2026-10-20)], 'with an end, both ends included');
is($bounded->(), undef, '  and undef after, every time');
is($bounded->(), undef, '  every time');
my $empty = $plain->iterate_business_days(d('2026-10-17'), d('2026-10-18'));
is($empty->(), undef, 'a weekend span gives nothing');
my $year = $uk->iterate_business_days(d('2026-01-01'), d('2026-12-31'));
my $n = 0;
$n++ while $year->();
is($n, 253, 'an iterator over 2026 agrees with business_days_in');
is_deeply([ map { "$_" } $uk->business_days(d('2026-03-01'), d('2026-04-30')) ],
          [ do { my $i = $uk->iterate_business_days(d('2026-03-01'), d('2026-04-30')); my @a; while (my $x = $i->()) { push @a, "$x" } @a } ], '  and with business_days');
my $endless = $plain->iterate_business_days(d('2026-01-01'));
my $last;
$last = $endless->() for 1 .. 10_000;
is("$last", $plain->plus_business_days(d('2026-01-01'), 9999) . '', 'an endless iterator stepped ten thousand times lands where plus_business_days says');
my $a = $plain->iterate_business_days(d('2026-10-12'));
my $b = $plain->iterate_business_days(d('2026-10-12'));
$a->() for 1 .. 3;
is($b->() . '', '2026-10-12', 'two iterators are independent');
is($a->() . '', '2026-10-15', '  each keeps its place');
my $t = Time::Keeper->new(year => 2026, month => 10, day => 16, hour => 9, minute => 30, zone => 'Asia/Tokyo');
my $ti = $plain->iterate_business_days($t);
$ti->();
is($ti->() . '', '2026-10-19T09:30:00+09:00', 'a Time::Keeper start gives Time::Keepers with its clock and zone');
my $lazy = $C->new(holidays => sub { ("$_[0]-07-04") });
my $li = $lazy->iterate_business_days(d('2030-07-03'));
is(join(' ', map { "" . $li->() } 1 .. 2), '2030-07-03 2030-07-05', 'an iterator on a lazy schedule materialises as it goes');
ok(!eval { $plain->iterate_business_days(ym(2026, 10)); 1 }, 'a month is not a start');
like($@, qr/a month is not a day/, '  by name');
ok(!eval { Time::Keeper::Business::_iterate_business_days_step(); 1 }, 'the step called bare dies');
like($@, qr/the iterator is not one/, '  by name');
SKIP: {
    skip 'no ithreads', 2 unless $Config{useithreads};
    my $p = $plain->iterate_business_days(d('2026-10-12'));
    $p->();
    my $thr = threads->create(sub { join ' ', map { "" . $p->() } 1 .. 2 });
    is($thr->join, '2026-10-13 2026-10-14', 'a thread\'s copy continues from where the parent was');
    is($p->() . '', '2026-10-13', '  and the parent keeps its own place');
}

done_testing;
