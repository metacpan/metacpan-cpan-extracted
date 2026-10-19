#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Recurrence;

# The named door: every(n, unit, on =>, at =>, until =>, count =>), and the
# RRULE each spelling produces.

my $R = 'Time::Keeper::Recurrence';
my $start = Time::Keeper->new(year => 2026, month => 10, day => 20, hour => 9, zone => 'Europe/London');
sub every { $R->every(@_, start => $start) }
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'did not die' : $@);
}

is(every(2, 'weeks', on => [qw(tue thu)])->rrule, 'FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,TH', 'every 2 weeks on Tuesday and Thursday');
is(every(1, 'week', on => 'monday')->rrule, 'FREQ=WEEKLY;BYDAY=MO', 'a full weekday name, one unit');
is(every(1, 'month', on => 'last fri', at => '17:00')->rrule, 'FREQ=MONTHLY;BYSECOND=0;BYMINUTE=0;BYHOUR=17;BYDAY=-1FR', 'the last Friday at five');
is(every(1, 'month', on => '3rd Tuesday')->rrule, 'FREQ=MONTHLY;BYDAY=3TU', '3rd Tuesday');
is(every(1, 'month', on => ['1st mon', '-1 fri'])->rrule, 'FREQ=MONTHLY;BYDAY=1MO,-1FR', 'ordinals both ways');
is(every(1, 'month', on => [1, 15, -1])->rrule, 'FREQ=MONTHLY;BYMONTHDAY=1,15,-1', 'days of the month');
is(every(1, 'year', on => 'last sun', at => '02:00:00')->rrule, 'FREQ=YEARLY;BYSECOND=0;BYMINUTE=0;BYHOUR=2;BYDAY=-1SU', 'a year rule');
is(every(3, 'days', at => '09:30')->rrule, 'FREQ=DAILY;INTERVAL=3;BYSECOND=0;BYMINUTE=30;BYHOUR=9', 'at sets the clock parts');
is(every(90, 'minutes')->rrule, 'FREQ=MINUTELY;INTERVAL=90', 'minutes');
is(every(1, 'hour')->rrule, 'FREQ=HOURLY', 'an hour');
is(every(10, 'seconds')->rrule, 'FREQ=SECONDLY;INTERVAL=10', 'seconds');
is(every(1, 'day', count => 10)->rrule, 'FREQ=DAILY;COUNT=10', 'count');
my $until = Time::Keeper->new(year => 2027, month => 12, day => 31, hour => 23, minute => 59, second => 59, zone => 'UTC');
is(every(1, 'day', until => $until)->rrule, 'FREQ=DAILY;UNTIL=20271231T235959Z', 'until as a value, in UTC');
is(every(1, 'day', until => $until)->until->epoch, $until->epoch, 'and read back');
my $r = every(2, 'weeks', on => [qw(tue thu)]);
is($r->freq . ' ' . $r->interval, 'weekly 2', 'freq and interval');
is($r->start->iso8601, '2026-10-20T09:00:00+01:00', 'the start');
is($r->zone, 'Europe/London', 'the zone from the start');
is($r->gap . ' ' . $r->overlap, 'forward earlier', 'a rule\'s defaults');
is($R->every(1, 'day', start => $start, gap => 'skip')->gap, 'skip', 'gap can be given');
my $fl = Time::Keeper->new(year => 2026, month => 10, day => 20, hour => 9, zone => 'floating');
is($R->every(1, 'day', start => $fl, until => $fl->plus(days => 3))->rrule, 'FREQ=DAILY;UNTIL=20261023T090000', 'a floating until for a floating start');

dies_like(sub { every(1, 'fortnight') }, qr/the unit is seconds, minutes, hours, days, weeks, months or years, not 'fortnight'/, 'a bad unit dies');
dies_like(sub { every(0, 'days') }, qr/every how many\? 0 is not a count above zero/, 'zero dies');
dies_like(sub { every(1, 'week', on => 'funday') }, qr/on => 'funday' is not a weekday/, 'a bad weekday dies');
dies_like(sub { every(1, 'week', on => 'last fri') }, qr/on => 'last fri' is not a weekday, with 1st to 5th or last before it for months or years/, 'an ordinal needs months or years');
dies_like(sub { every(1, 'week', on => 15) }, qr/on => a day of the month needs months or years/, 'a month day needs months or years');
dies_like(sub { every(1, 'month', on => 32) }, qr/on => 32 is not a day of the month/, 'a bad month day dies');
dies_like(sub { every(1, 'day', at => '25:00') }, qr/at => '25:00' is not a time of day, HH:MM or HH:MM:SS/, 'a bad time dies');
dies_like(sub { every(1, 'day', at => '9am') }, qr/at => '9am' is not a time of day/, 'words die');
dies_like(sub { every(1, 'day', count => 0) }, qr/count => 0 is not a count above zero/, 'a bad count dies');
dies_like(sub { every(1, 'day', count => 3, until => $until) }, qr/until and count cannot both be given/, 'both ends die');
dies_like(sub { every(1, 'day', until => 'never') }, qr/until is not a Time::Keeper value/, 'a bad until dies');
dies_like(sub { $R->every(1, 'day') }, qr/start => a Time::Keeper value is wanted/, 'no start dies');
dies_like(sub { $R->every(1, 'day', start => $start, until => $fl->plus(days => 3)) }, qr/UNTIL must be in UTC \(end in Z\) when the start has a zone/, 'a floating until on a zoned start dies');
dies_like(sub { every(1, 'day', rrule => 'FREQ=DAILY') }, qr/'rrule' is not an argument here/, 'rrule is not an argument of every');

done_testing;
