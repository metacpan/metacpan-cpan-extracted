#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use utf8;
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

use Time::Keeper;

my $T = 'Time::Keeper::Time';
my $K = 'Time::Keeper';
my $Dur = 'Time::Keeper::Duration';
sub tm { $T->new(hour => $_[0], minute => $_[1] || 0, second => $_[2] || 0, nanosecond => $_[3] || 0) }
sub dies_like { my ($code, $re, $name) = @_; ok(!eval { $code->(); 1 }, $name) or return; like($@, $re, "$name: the message") }

my $tm = $T->new(hour => 9, minute => 5, second => 7, nanosecond => 250_000_000, locale => 'fr');
isa_ok($tm, $T, 'new');
ok(!$tm->isa('Time::Keeper'), 'not a Time::Keeper');
is("$tm", '09:05:07.250', 'stringifies with the fewest exact digits');
is($tm->iso8601, '09:05:07.250', 'iso8601');
is($tm->iso8601(precision => 0), '09:05:07', 'precision 0');
is($tm->iso8601(precision => 9), '09:05:07.250000000', 'precision 9');
is(tm(9, 5, 7)->iso8601, '09:05:07', 'no fraction when none');
is(tm(9, 5, 7, 1)->iso8601, '09:05:07.000000001', 'nine digits for a nanosecond');
is($tm->TO_JSON, '09:05:07.250', 'TO_JSON');
is($tm->hms, '09:05:07', 'hms');
is($tm->hms('.'), '09.05.07', 'hms with a separator');
is($tm->time, '09:05:07', 'time');
is($tm->hour, 9, 'hour');
is($tm->minute, 5, 'minute');
is($tm->second, 7, 'second');
is($tm->nanosecond, 250_000_000, 'nanosecond');
is($tm->millisecond, 250, 'millisecond');
is($tm->microsecond, 250_000, 'microsecond');
is($tm->hour_12, 9, 'hour_12');
is(tm(0)->hour_12, 12, 'midnight is 12');
is(tm(15)->hour_12, 3, '15 is 3');
is($tm->am_pm, 'AM', 'am_pm in fr');
is($tm->in_locale('en')->am_pm, 'AM', 'in en');
is(tm(15)->in_locale('en')->am_pm, 'PM', 'PM');
is($tm->locale, 'fr', 'locale');
ok(!$tm->can('year'), 'no year');
ok(!$tm->can('day_of_week'), 'no day_of_week');
ok(!$tm->can('epoch'), 'no epoch');
ok(!$tm->can('next'), 'no adjusters');
is($T->new->iso8601, '00:00:00', 'every part defaults to 0');
dies_like(sub { $T->new(hour => 24) }, qr/hour/, 'hour 24 dies');
dies_like(sub { $T->new(hour => 23, minute => 59, second => 60) }, qr/no second 60/, 'second 60 dies');
dies_like(sub { $T->new(day => 1) }, qr/unknown argument 'day'/, 'no date keys');
dies_like(sub { $T->new(zone => 'UTC') }, qr/unknown argument 'zone'/, 'no zone');
is($T->try_new(hour => 25), undef, 'try_new');

my $now = $T->now;
isa_ok($now, $T, 'now');
my $real = $K->now->to_time;
cmp_ok(abs(($real - $now)->total_seconds), '<', 2, 'now is within two seconds of the value\'s time of day');
{
    local $Time::Keeper::CLOCK = $K->parse('2026-10-15T23:30:15.5Z');
    is($T->now . '', '23:30:15.500', 'now reads the test clock');
    is($T->now(zone => 'Asia/Tokyo') . '', '08:30:15.500', 'in a zone');
    is($T->now(locale => 'de')->locale, 'de', 'with a locale');
}
my $v = $K->new(year => 2026, month => 10, day => 15, hour => 23, minute => 30, second => 15, nanosecond => 7, zone => 'Asia/Tokyo', locale => 'ja');
my $to = $v->to_time;
isa_ok($to, $T, 'to_time');
is("$to", '23:30:15.000000007', 'the wall-clock time of day');
is($to->locale, 'ja', 'with the locale');
is($K->parse('2016-12-31T23:59:60.5Z')->to_time . '', '23:59:59.999999999', 'a leap second clamps to the last nanosecond before it');

is(tm(23, 30)->plus(hours => 1) . '', '00:30:00', '23:30 + 1 hour wraps to 00:30');
is(tm(0, 30)->minus(hours => 1) . '', '23:30:00', '00:30 - 1 hour wraps back');
is(tm(1)->plus(hours => 25) . '', '02:00:00', '+ 25 hours is + 1');
is(tm(1)->plus(minutes => 1440) . '', '01:00:00', '+ 1440 minutes is the same time');
is(tm(1)->plus(seconds => 86400 * 3 + 5) . '', '01:00:05', '+ three days of seconds and five');
is(tm(1)->minus(seconds => 86400 * 3 + 5) . '', '00:59:55', 'and back');
is(tm(23, 59, 59, 999_999_999)->plus(nanoseconds => 1) . '', '00:00:00', 'the last nanosecond plus one is midnight');
is(tm(12)->plus(minutes => (2**59)) . '', (sub { my $m = (2**59) % 1440; sprintf '%02d:%02d:00', (12 + int($m / 60)) % 24, $m % 60 })->(), 'a duration near the limit does not overflow');
is(tm(12)->plus(seconds => -(2**59)) . '', (sub { my $s = (2**59) % 86400; my $t = (12 * 3600 - $s) % 86400; sprintf '%02d:%02d:%02d', int($t / 3600), int($t / 60) % 60, $t % 60 })->(), 'nor a negative one');
is(($tm + $Dur->new(minutes => 55)) . '', '10:00:07.250', '+ a duration');
is(($Dur->new(hours => -10) + $tm) . '', '23:05:07.250', 'duration + time wraps');
is(($tm - $Dur->new(hours => 10)) . '', '23:05:07.250', '- a duration wraps');
my $later = tm(10, 30);
my $diff = $later - $tm;
isa_ok($diff, $Dur, '$b - $a');
is("$diff", 'PT1H24M52.75S', 'the signed duration');
is(($tm + $diff) . '', "$later", 'and adds back');
is(($tm - $later) . '', '-PT1H24M52.75S', 'negative the other way, never wrapped');
is($tm->minus($later) . '', '-PT1H24M52.75S', 'minus a time');
is((tm(0) - tm(23))->total_seconds, -82800, 'midnight minus 23:00 is -23 hours, not +1');
dies_like(sub { $tm->plus(days => 1) }, qr/a time of day has no calendar/, 'plus days dies');
dies_like(sub { $tm->plus(months => 1) }, qr/no calendar/, 'plus months dies');
dies_like(sub { $tm + $Dur->new(days => 1) }, qr/no calendar/, '+ days dies');
dies_like(sub { $Dur->new(days => 1) + $tm }, qr/no calendar/, 'days + time dies');
dies_like(sub { $Dur->new(hours => 1) - $tm }, qr/means nothing/, 'duration - time');

is($tm->with(minute => 0, second => 0, nanosecond => 0) . '', '09:00:00', 'with');
is($tm->with(hour => 23) . '', '23:05:07.250', 'with hour');
dies_like(sub { $tm->with(second => 60) }, qr/second/, 'with second 60 dies');
dies_like(sub { $tm->with(day => 3) }, qr/unknown argument 'day'/, 'with has no date keys');
is($tm->in_locale('de')->locale, 'de', 'in_locale');

is($tm->truncate(to => 'hour') . '', '09:00:00', 'truncate to hour');
is($tm->truncate(to => 'minute') . '', '09:05:00', 'to minute');
is($tm->truncate(to => 'second') . '', '09:05:07', 'to second');
is($tm->truncate(to => 'millisecond') . '', '09:05:07.250', 'to millisecond');
is($tm->round(to => 'minute') . '', '09:05:00', 'round to minute');
is($tm->round(to => 'minute', increment => 15) . '', '09:00:00', 'round to a quarter hour');
is(tm(9, 52)->round(to => 'minute', increment => 15) . '', '09:45:00', '9:52 is nearer 9:45');
is(tm(9, 53)->round(to => 'minute', increment => 15) . '', '10:00:00', '9:53 up to the next hour');
is(tm(23, 59, 40)->round(to => 'minute') . '', '00:00:00', '23:59:40 rounds to midnight');
is(tm(23, 59, 40)->round(to => 'hour', mode => 'floor') . '', '23:00:00', 'mode floor');
is($tm->end_of(to => 'hour') . '', '09:59:59.999999999', 'end_of hour');
dies_like(sub { $tm->truncate(to => 'day') }, qr/an hour or less, not to day/, 'not to a day');
dies_like(sub { $tm->truncate(to => 'month') }, qr/not to month/, 'not to a month');

ok($tm < $later, '<');
ok($later > $tm, '>');
ok($tm == $T->new(hour => 9, minute => 5, second => 7, nanosecond => 250_000_000), '==');
is($T->compare($later, $tm), 1, 'compare');
dies_like(sub { my $x = $tm <=> $v }, qr/compares only with another time of day/, 'not with a value');
dies_like(sub { my $x = $tm <=> Time::Keeper::Date->new(year => 2026, month => 1, day => 1) }, qr/only with another time of day/, 'not with a date');

is($tm->format('HH:mm:ss.SSS'), '09:05:07.250', 'format');
is($tm->in_locale('en')->format('h:mm a'), '9:05 AM', 'h:mm a (the pattern\'s own space)');
is($tm->format('H'), '9', 'H');
dies_like(sub { $tm->format('yyyy-MM-dd HH:mm') }, qr/the pattern letter 'y' needs a year, and a time of day has none/, 'a year letter dies');
dies_like(sub { $tm->format('EEEE') }, qr/'E' needs a day/, 'a weekday dies');
dies_like(sub { $tm->format('HH:mm z') }, qr/'z' needs a zone/, 'a zone dies');
is($tm->in_locale('en')->strftime('%I:%M %p'), '09:05 AM', 'strftime (a plain space: the pattern\'s own)');
is($tm->strftime('%H:%M:%S %N'), '09:05:07 250000000', '%N');
is($tm->strftime('%T %R'), '09:05:07 09:05', '%T and %R');
dies_like(sub { $tm->strftime('%Y') }, qr/%Y needs a year/, '%Y dies');
dies_like(sub { $tm->strftime('%d') }, qr/%d needs a day/, '%d dies');
dies_like(sub { $tm->strftime('%a') }, qr/%a needs a day/, '%a dies');
dies_like(sub { $tm->strftime('%z') }, qr/%z needs a zone/, '%z dies');
dies_like(sub { $tm->strftime('%s') }, qr/%s needs an instant/, '%s dies');
dies_like(sub { $tm->strftime('%c') }, qr/%c needs a date as well as a time of day/, '%c dies');
is($tm->in_locale('en')->format_time, "9:05:07\x{202F}AM", 'format_time medium (CLDR puts U+202F before AM)');
is($tm->in_locale('en')->format_time('short'), "9:05\x{202F}AM", 'short');
is($tm->format_time('short'), '09:05', 'short in fr');
dies_like(sub { $tm->format_time('full') }, qr/'z' needs a zone/, 'full names the zone and dies');
dies_like(sub { $tm->format_time('long') }, qr/'z' needs a zone/, 'so does long');
is($tm->in_locale('en')->format_skeleton('Hms'), '09:05:07', 'format_skeleton Hms');
is($tm->in_locale('en')->format_skeleton('hm'), "9:05\x{202F}AM", 'hm');
dies_like(sub { $tm->format_skeleton('yMMMd') }, qr/needs a (year|month|day)/, 'a date skeleton dies');

is($T->parse('09:05:07.25') . '', '09:05:07.250', 'parse');
is($T->parse('T09:05') . '', '09:05:00', 'with a T');
is($T->parse('0905') . '', '09:05:00', 'basic');
is($T->parse('090507.5') . '', '09:05:07.500', 'basic with a fraction');
is($T->parse('09.5') . '', '09:30:00', 'a fractional hour');
is($T->parse('09:05:07,25') . '', '09:05:07.250', 'a comma');
is($T->parse('09:05', locale => 'de')->locale, 'de', 'with a locale');
dies_like(sub { $T->parse('09:05Z') }, qr/names an offset or a zone, and a time of day has none/, 'a Z dies');
dies_like(sub { $T->parse('09:05+01:00') }, qr/names an offset/, 'an offset dies');
dies_like(sub { $T->parse('09:05[Europe/London]') }, qr/names an offset or a zone/, 'a zone dies');
dies_like(sub { $T->parse('24:00') }, qr/24:00 is the end of a day/, '24:00 dies');
dies_like(sub { $T->parse('23:59:60') }, qr/no second 60/, 'second 60 dies');
dies_like(sub { $T->parse('2026-10-15T09:05') }, qr/cannot parse|names an offset/, 'a date dies');
dies_like(sub { $T->parse('nine') }, qr/cannot parse/, 'nonsense dies');
is($T->strptime('15/10/2026 21:05', '%d/%m/%Y %H:%M') . '', '21:05:00', 'strptime drops the date');
is($T->strptime('9:05 PM', '%I:%M %p') . '', '21:05:00', 'PM');
is($T->parse_cldr('09 h 05', "HH 'h' mm", locale => 'fr') . '', '09:05:00', 'parse_cldr');
is($T->try_parse('25:00'), undef, 'try_parse');
ok($T->try_parse('09:00'), 'and a good one');

my $frozen = $tm->FREEZE('any');
like($frozen, qr/^tkp1 2 32707 250000000 fr$/, 'FREEZE text: the seconds into the day');
is($T->THAW('any', $frozen) . '', '09:05:07.250', 'THAW');
require Storable;
my $copy = Storable::thaw(Storable::freeze($tm));
isa_ok($copy, $T, 'Storable');
is("$copy", '09:05:07.250', 'round-trips');
is($copy->locale, 'fr', 'with the locale');
dies_like(sub { $T->THAW('any', 'tkp1 2 86400 0') }, qr/not a frozen/, 'a second past the day does not thaw');
dies_like(sub { $T->THAW('any', Time::Keeper::Date->new(year => 2026, month => 1, day => 1)->FREEZE('any')) }, qr/not a frozen Time::Keeper::Time/, 'a frozen date does not thaw as a time');

my $d = Time::Keeper::Date->new(year => 2026, month => 3, day => 8, locale => 'de');
my $at = $d->at($tm, zone => 'Europe/London');
isa_ok($at, $K, 'Date->at($time)');
is($at->iso8601, '2026-03-08T09:05:07.250+00:00', 'the date at the time in the zone (London is on GMT in March, a named zone, so +00:00 not Z)');
is($at->locale, 'de', 'the date\'s locale, not the time\'s');
dies_like(sub { $d->at(tm(2, 30), zone => 'America/New_York') }, qr/did not happen/, 'a skipped time dies');
is($d->at(tm(2, 30), zone => 'America/New_York', gap => 'forward')->iso8601, '2026-03-08T03:30:00-04:00', 'unless gap => forward');
dies_like(sub { $d->at($tm, hour => 3) }, qr/unknown argument 'hour'/, 'a time and the clock keys together die');
is($d->at(tm(0))->iso8601, '2026-03-08T00:00:00Z', 'midnight as a time');

{
    package Time::Keeper::Time::Sub;
    our @ISA = ('Time::Keeper::Time');
}
is(ref Time::Keeper::Time::Sub->new(hour => 1)->plus(hours => 1), 'Time::Keeper::Time::Sub', 'a subclass survives arithmetic');

done_testing;
