#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Storable ();

use Time::Keeper;
use Time::Keeper::Business;

my $C = 'Time::Keeper::Business';
sub d { Time::Keeper::Date->parse($_[0]) }
sub spans { [map { [ "$_->[0]", "$_->[1]" ] } @_] }
sub L { Time::Keeper->new(year => $_[0], month => $_[1], day => $_[2], hour => $_[3], minute => $_[4] // 0, zone => 'Europe/London') }

my $london = $C->new(zone => 'Europe/London', hours => ['09:00-17:30'], holidays => ['2026-12-28'], name => 'london');
my $ny     = $C->new(zone => 'America/New_York', hours => ['09:00-17:00'], holidays => ['2026-11-26'], name => 'new york');

my %want = (
    both   => [['2026-10-15T14:00:00+01:00', '2026-10-15T17:30:00+01:00']],
    either => [['2026-10-15T09:00:00+01:00', '2026-10-15T22:00:00+01:00']],
    first  => [['2026-10-15T09:00:00+01:00', '2026-10-15T17:30:00+01:00']],
    second => [['2026-10-15T09:00:00-04:00', '2026-10-15T17:00:00-04:00']],
);
for my $mode (sort keys %want) {
    is_deeply(spans($london->join($ny, hours => $mode)->business_hours_on(d('2026-10-15'))), $want{$mode}, "15 October 2026, $mode");
}
my $both = $london->join($ny, hours => 'both');
is_deeply(spans($both->business_hours_on(d('2026-03-02'))), [['2026-03-02T14:00:00+00:00', '2026-03-02T17:30:00+00:00']], 'both, 2 March: neither has changed its clocks');
is_deeply(spans($both->business_hours_on(d('2026-03-09'))), [['2026-03-09T13:00:00+00:00', '2026-03-09T17:30:00+00:00']], '  9 March: New York has, London not, so an hour earlier');
is_deeply(spans($both->business_hours_on(d('2026-03-27'))), [['2026-03-27T13:00:00+00:00', '2026-03-27T17:30:00+00:00']], '  27 March, still');
is_deeply(spans($both->business_hours_on(d('2026-03-30'))), [['2026-03-30T14:00:00+01:00', '2026-03-30T17:30:00+01:00']], '  30 March: both have');
is($both->is_business_hours(L(2026, 10, 15, 13)), 0, 'both: 13:00 London is closed, New York not yet open');
is($both->is_business_hours(L(2026, 10, 15, 15)), 1, '  15:00 is open');
is($both->next_open(L(2026, 10, 15, 10)) . '', '2026-10-15T14:00:00+01:00', '  next_open from 10:00 is 14:00');
is($both->deadline(L(2026, 10, 15, 14), hours => 4) . '', '2026-10-16T14:30:00+01:00', '  a deadline of four hours from Thursday 14:00: 3.5 that day, half an hour on Friday');
is($both->business_hours_between(L(2026, 10, 12, 9), L(2026, 10, 19, 9))->total('hours'), 5 * 3.5, '  a week of both: five days of three and a half hours');
is_deeply(spans($both->business_hours_on(d('2026-11-26'))), [], '  Thanksgiving closes the join (the days join as either)');
is_deeply(spans($both->business_hours_on(d('2026-12-28'))), [], '  and London\'s holiday');
my $eit = $london->join($ny, hours => 'either');
is($eit->business_hours_between(L(2026, 10, 12, 0), L(2026, 10, 17, 0))->total('hours'), 5 * 13, 'either: a week of thirteen-hour days');
is($eit->plus_business_hours(L(2026, 10, 15, 21), hours => 2) . '', '2026-10-16T10:00:00+01:00', '  two hours from 21:00: one to 22:00, then an hour from 09:00');
my $la = $C->new(zone => 'America/Los_Angeles', hours => ['09:00-17:00']);
my $wrap = $london->join($la, hours => 'either');
my $w = spans($wrap->business_hours_on(d('2026-10-15')));
is_deeply($w, [['2026-10-15T00:00:00+01:00', '2026-10-15T01:00:00+01:00'], ['2026-10-15T09:00:00+01:00', '2026-10-16T00:00:00+01:00']],
          'either across midnight: Los Angeles\'s day is cut at London\'s midnight, the overlap merged') or diag explain $w;
is($wrap->business_hours_between(L(2026, 10, 15, 0), L(2026, 10, 16, 0))->total('hours'), 16, '  sixteen hours that day');

my $lunch = $C->new(zone => 'Europe/London', hours => ['09:00-12:30', '13:30-17:30']);
my $paris = $C->new(zone => 'Europe/Paris', hours => ['09:00-17:00']);
is_deeply(spans($lunch->join($paris, hours => 'both')->business_hours_on(d('2026-10-15'))), [['2026-10-15T09:00:00+01:00', '2026-10-15T12:30:00+01:00'], ['2026-10-15T13:30:00+01:00', '2026-10-15T16:00:00+01:00']],
          'both with London\'s lunch break against Paris\'s one span: two pieces');
my $nysplit = $C->new(zone => 'America/New_York', hours => ['08:00-08:30', '09:00-17:00']);
is_deeply(spans($lunch->join($nysplit, hours => 'both')->business_hours_on(d('2026-10-15'))), [['2026-10-15T14:00:00+01:00', '2026-10-15T17:30:00+01:00']],
          'both with two spans each side: London\'s afternoon against New York\'s day');
is($both->business_hours_between(L(2026, 10, 12, 0), L(2026, 11, 2, 0))->total('hours'), 10 * 3.5 + 5 * 4.5, "three weeks of both: ten days of 14:00 to 17:30, then the week of 26 October, when London has gone back and New York not, from 13:00; the join's weeks are never taken as plain");
my $far = $london->join($ny, hours => 'both');
is_deeply(spans($far->business_hours_on(d('2026-03-09'))), [['2026-03-09T13:00:00+00:00', '2026-03-09T17:30:00+00:00']], 'a day in the cache');
is_deeply(spans($far->business_hours_on(d('2026-03-09')->plus(days => 512))), [['2027-08-03T14:00:00+01:00', '2027-08-03T17:30:00+01:00']], '  and the day 512 later, in the same slot, is its own');
my $night = $C->new(zone => 'Europe/London', hours => ['22:00-06:00']);
my $tokyo = $C->new(zone => 'Asia/Tokyo', hours => ['09:00-18:00']);
is_deeply(spans($night->join($tokyo, hours => 'both')->business_hours_on(d('2026-10-16'))), [['2026-10-16T01:00:00+01:00', '2026-10-16T06:00:00+01:00']],
          'both with an overnight part: London\'s Thursday night against Tokyo\'s Friday, 01:00 to 06:00 on Friday');
ok(!eval { $london->join($C->new, hours => 'both'); 1 }, 'both needs both to have hours');
like($@, qr/hours => 'both' needs both schedules to have hours/, '  by name');
ok(!eval { $C->new->join($london, hours => 'first'); 1 }, 'first needs the first');
like($@, qr/hours => 'first' needs the first schedule to have hours/, '  by name');
is_deeply(spans($C->new->join($london, hours => 'second')->business_hours_on(d('2026-10-15'))), [['2026-10-15T09:00:00+01:00', '2026-10-15T17:30:00+01:00']], 'second with only the second\'s hours');
ok(!eval { $london->join($ny, hours => 'sometimes'); 1 }, 'an unknown hours mode is refused');
like($@, qr/hours is 'both', 'either', 'first' or 'second', not 'sometimes'/, '  by name');
ok(!eval { $london->join($ny)->next_open(L(2026, 10, 15, 10)); 1 }, 'a join without hours has none, as in 0.01');
like($@, qr/this schedule has no hours/, '  by name');
ok(!eval { Storable::freeze($both); 1 }, 'a join with hours cannot be frozen');
like($@, qr/cannot freeze a join with hours; freeze its parts and join them again/, '  by name');
is($both->join($ny, hours => 'first')->is_business_hours(L(2026, 10, 15, 15)), 1, 'a join of a join with hours');

my $bad = 0;
for my $day (0 .. 400) {
    my $dd = d('2026-01-01')->plus(days => $day);
    my $got = 0;
    $got += $_->[1]->epoch - $_->[0]->epoch for $both->business_hours_on($dd);
    my $want = 0;
    if ($both->is_business_day($dd)) {
        my ($a0, $a1) = map { $_->epoch } @{ ($london->business_hours_on($dd))[0] || [] };
        my $nd = $dd;
        my @n = map { [ $_->[0]->epoch, $_->[1]->epoch ] } $ny->business_hours_on($nd);
        if (defined $a0 && @n) { my ($lo, $hi) = ($a0 > $n[0][0] ? $a0 : $n[0][0], $a1 < $n[0][1] ? $a1 : $n[0][1]); $want = $hi > $lo ? $hi - $lo : 0 }
    }
    $bad++ if $got != $want;
}
is($bad, 0, 'both, every day of 2026 and early 2027: the overlap of the two days\' spans as instants');

done_testing;
