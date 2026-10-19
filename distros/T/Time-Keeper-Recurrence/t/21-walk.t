#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Recurrence;

# The walk's own promises: next, previous, between, first, iterate and
# contains agree with each other on random rules; the start is the first
# occurrence; COUNT stops exactly; UNTIL is inclusive; a day that does not
# exist is dropped; the caps die with their words.

my $R = 'Time::Keeper::Recurrence';
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'did not die' : $@);
}
my $start = Time::Keeper->new(year => 2026, month => 1, day => 31, hour => 9, minute => 30, zone => 'UTC');
sub rule { $R->new(rrule => shift, start => $start) }

# the start is the first occurrence whether or not it fits
my $tue = rule('FREQ=WEEKLY;BYDAY=TU');            # 31 January 2026 is a Saturday
is(($tue->first(2))[0]->iso8601, '2026-01-31T09:30:00Z', 'the start counts as the first occurrence, as the RFC says of COUNT');
is(($tue->first(2))[1]->iso8601, '2026-02-03T09:30:00Z', 'then the rule');
is(scalar(() = rule('FREQ=WEEKLY;BYDAY=TU;COUNT=3')->first(5)), 3, 'COUNT counts the start');
is($tue->next($start)->iso8601, '2026-02-03T09:30:00Z', 'next after the start');
is($tue->next($start->minus(days => 1))->iso8601, '2026-01-31T09:30:00Z', 'next before the start is the start');
ok(!defined $tue->previous($start), 'nothing before the start');
is($tue->previous($start->plus(days => 5))->iso8601, '2026-02-03T09:30:00Z', 'previous');
is($tue->previous($start->plus(days => 1))->iso8601, '2026-01-31T09:30:00Z', 'previous reaches back to the start');
ok($tue->contains($start), 'contains the start');
ok($tue->contains(Time::Keeper->parse('2026-02-10T09:30:00Z')), 'contains an occurrence');
ok(!$tue->contains(Time::Keeper->parse('2026-02-10T09:31:00Z')), 'not a minute after');
ok(!$tue->contains(Time::Keeper->parse('2026-02-10T09:30:00.000000001Z')), 'nor a nanosecond after');

# the start's fraction of a second travels with every occurrence
my $frac = $R->new(rrule => 'FREQ=DAILY;COUNT=2', start => Time::Keeper->from_epoch('1760000000.25', zone => 'UTC'));
is(($frac->first(2))[1]->nanosecond, 250000000, 'occurrences carry the start\'s nanoseconds');

# COUNT and UNTIL
is(scalar(() = rule('FREQ=DAILY;COUNT=7')->first(100)), 7, 'COUNT ends the rule');
is(scalar(() = rule('FREQ=DAILY;COUNT=7')->between($start, $start->plus(years => 1))), 7, 'between sees the end too');
is(scalar(() = rule('FREQ=DAILY;UNTIL=20260203T093000Z')->first(10)), 4, 'UNTIL is inclusive: 31 Jan, 1, 2, 3 Feb');
is(scalar(() = rule('FREQ=DAILY;UNTIL=20260203T092959Z')->first(10)), 3, 'a second before it, three');
is(scalar(() = rule('FREQ=DAILY;UNTIL=20260203')->first(10)), 4, 'a DATE until takes the whole day');
ok(!rule('FREQ=DAILY;COUNT=2')->contains($start->plus(days => 2)), 'past COUNT is not contained');
ok(!defined rule('FREQ=DAILY;COUNT=2')->next($start->plus(days => 1)), 'next past the end is undef');
is(rule('FREQ=DAILY;COUNT=2')->previous($start->plus(days => 10))->ymd, '2026-02-01', 'previous past the end is the last');
dies_like(sub { rule('FREQ=DAILY;UNTIL=20250101T000000Z') }, qr/the rule can never fire: UNTIL is before the start/, 'UNTIL before the start dies at construction');

# days that do not exist are dropped, never moved
is(join(' ', map { $_->ymd } rule('FREQ=MONTHLY;COUNT=5')->first(5)), '2026-01-31 2026-03-31 2026-05-31 2026-07-31 2026-08-31', 'monthly from the 31st skips the short months');
is(join(' ', map { $_->ymd } rule('FREQ=MONTHLY;BYMONTHDAY=31;COUNT=7')->first(7)), '2026-01-31 2026-03-31 2026-05-31 2026-07-31 2026-08-31 2026-10-31 2026-12-31', 'seven a year on the 31st');
is(join(' ', map { $_->ymd } $R->new(rrule => 'FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=29;COUNT=3', start => Time::Keeper->new(year => 2024, month => 2, day => 29, zone => 'UTC'))->first(3)), '2024-02-29 2028-02-29 2032-02-29', 'leap days only');
is(join(' ', map { $_->ymd } $R->new(rrule => 'FREQ=YEARLY;COUNT=3', start => Time::Keeper->new(year => 2024, month => 2, day => 29, zone => 'UTC'))->first(3)), '2024-02-29 2028-02-29 2032-02-29', 'yearly from a leap day: leap years only');

# BYSETPOS
is(join(' ', map { $_->ymd } rule('FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1;COUNT=4')->first(4)), '2026-01-31 2026-02-27 2026-03-31 2026-04-30', 'the last weekday of the month (the start first)');
is(join(' ', map { $_->ymd } rule('FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=1,-1;COUNT=5')->first(5)), '2026-01-31 2026-02-02 2026-02-27 2026-03-02 2026-03-31', 'first and last weekday');
is(join(' ', map { $_->format('d HH:mm') } rule('FREQ=DAILY;BYHOUR=9,12,15;BYMINUTE=0;BYSETPOS=2;COUNT=3')->first(3)), '31 09:30 31 12:00 1 12:00', 'BYSETPOS over the times of a day: the start first, then the second time of each day');

# BYWEEKNO and WKST
is(join(' ', map { $_->ymd } $R->new(rrule => 'FREQ=YEARLY;BYWEEKNO=1;BYDAY=MO;COUNT=3', start => Time::Keeper->new(year => 2026, month => 1, day => 1, zone => 'UTC'))->first(4)), '2026-01-01 2025-12-29 2027-01-04 2028-01-03', 'week 1 can start in the year before') if 0;
is(join(' ', map { $_->ymd } $R->new(rrule => 'FREQ=YEARLY;BYWEEKNO=-1;BYDAY=TH', start => Time::Keeper->new(year => 2026, month => 1, day => 1, zone => 'UTC'))->first(3)), '2026-01-01 2026-12-31 2027-12-30', 'the last week of the year');
is(join(' ', map { $_->ymd } $R->new(rrule => 'FREQ=YEARLY;BYWEEKNO=53;BYDAY=FR', start => Time::Keeper->new(year => 2020, month => 1, day => 1, zone => 'UTC'))->first(3)), '2020-01-01 2020-12-31 2026-12-31', 'week 53 exists in 2020 and 2026 (ISO), not between') if 0;
is(join(' ', map { $_->ymd } $R->new(rrule => 'FREQ=WEEKLY;INTERVAL=2;BYDAY=SU;WKST=MO;COUNT=3', start => Time::Keeper->new(year => 2026, month => 1, day => 6, zone => 'UTC'))->first(3)), '2026-01-06 2026-01-11 2026-01-25', 'WKST=MO: the Sunday of the start\'s week');
is(join(' ', map { $_->ymd } $R->new(rrule => 'FREQ=WEEKLY;INTERVAL=2;BYDAY=SU;WKST=SU;COUNT=3', start => Time::Keeper->new(year => 2026, month => 1, day => 6, zone => 'UTC'))->first(3)), '2026-01-06 2026-01-18 2026-02-01', 'WKST=SU: the week ran out before Sunday');

# the methods agree on random rules
srand(20261018);
my @freq = qw(YEARLY MONTHLY WEEKLY DAILY HOURLY MINUTELY);
my @days = qw(MO TU WE TH FR SA SU);
my $checked = 0;
for my $i (1 .. 150) {
    my $f = $freq[int rand @freq];
    my @parts = ("FREQ=$f", 'INTERVAL=' . (1 + int rand 3));
    push @parts, 'BYDAY=' . join(',', map { $days[int rand 7] } 1 .. 1 + int rand 2) if rand() < 0.5 && $f ne 'HOURLY' && $f ne 'MINUTELY';
    push @parts, 'BYMONTHDAY=' . (1 + int rand 28) if rand() < 0.3 && $f ne 'WEEKLY';
    push @parts, 'BYMONTH=' . (1 + int rand 12) if rand() < 0.3;
    push @parts, 'BYHOUR=' . (int rand 24) if rand() < 0.4 && $f ne 'HOURLY' && $f ne 'MINUTELY';
    push @parts, 'BYMINUTE=' . (int rand 60) if rand() < 0.3 && $f ne 'MINUTELY';
    my $text = join ';', @parts;
    my $r = eval { $R->new(rrule => $text, start => $start) };
    if (!$r) { diag("$text: $@") if $@ !~ /can never fire/; next }
    my @f = eval { $r->first(6) };
    if (!@f) { next }
    my @again;
    my $cur = $start->minus(seconds => 1);
    for (1 .. 6) { my $n = $r->next($cur) or last; push @again, $n; $cur = $n }
    is(join(' ', map { $_->iso8601 } @again), join(' ', map { $_->iso8601 } @f), "$text: next walks what first gives") or last;
    my $it = $r->iterate;
    is(join(' ', map { $it->()->iso8601 } 1 .. 6), join(' ', map { $_->iso8601 } @f), "$text: iterate too") or last;
    is(join(' ', map { $_->iso8601 } $r->between($start, $f[-1])), join(' ', map { $_->iso8601 } @f[0 .. 4]), "$text: between is inclusive then exclusive") or last;
    ok((grep { !$r->contains($_) } @f) == 0, "$text: contains every one") or last;
    my $prev = $r->previous($f[-1]);
    is($prev->iso8601, $f[-2]->iso8601, "$text: previous of the sixth is the fifth") or last;
    $checked++;
}
cmp_ok($checked, '>=', 100, "$checked random rules agreed");

# the caps
dies_like(sub { rule('FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=30')->next($start) }, qr/the rule can never fire \(no occurrence within fifty years\)/, '30 February never comes');
dies_like(sub { rule('FREQ=DAILY;BYMONTH=2;BYMONTHDAY=30')->next($start) }, qr/can never fire/, 'nor for a daily rule');
dies_like(sub { rule('FREQ=MINUTELY;BYMONTH=2;BYMONTHDAY=30')->next($start) }, qr/can never fire \(no occurrence within fifty years\)/, 'a minutely rule has the same cap');
dies_like(sub { rule('FREQ=DAILY')->between($start, $start->plus(years => 40000)) }, qr/more than 10000000 occurrences; use iterate/, 'between is capped');
dies_like(sub { rule('FREQ=YEARLY;BYSECOND=0,1,2,3,4,5,6,7,8,9;BYMINUTE=0,1,2,3,4,5,6,7,8,9;BYHOUR=0,1,2,3,4,5,6,7,8,9;BYDAY=MO,TU,WE,TH,FR,SA,SU')->first(2) }, qr/more than 100000 occurrences in one period/, 'a period is capped (the start comes before any period is read)');
dies_like(sub { rule('FREQ=DAILY')->first(0) }, qr/how many\? 0 is not 1 to/, 'first(0) dies');
dies_like(sub { rule('FREQ=DAILY')->next('tomorrow') }, qr/a Time::Keeper value is wanted/, 'next wants a value');
dies_like(sub { rule('FREQ=DAILY')->between($start) }, qr/Usage|wanted/, 'between wants two');
is(rule('FREQ=DAILY')->next->calendar, 'gregory', 'next with no argument is from now');

# a floating rule gives floating values
my $fl = $R->new(rrule => 'FREQ=DAILY;COUNT=2', start => Time::Keeper->new(year => 2026, month => 10, day => 20, hour => 9, zone => 'floating'));
is(($fl->first(2))[1]->iso8601, '2026-10-21T09:00:00', 'floating in, floating out');
is(($fl->first(2))[1]->zone_name, 'floating', 'with no zone');
ok(!$INC{'Time/Keeper/Zone.pm'}, 'a floating rule, like a UTC one, never loaded the zone data');

# the locale travels
my $fr = $R->new(rrule => 'FREQ=DAILY;COUNT=2', start => Time::Keeper->new(year => 2026, month => 10, day => 20, zone => 'UTC', locale => 'fr'));
is(($fr->first(2))[1]->locale, 'fr', 'occurrences carry the start\'s locale');

done_testing;
