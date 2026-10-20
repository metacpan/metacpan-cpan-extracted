#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;

# Intervals: the ISO form, what format_interval writes in a locale, and two
# phrases round a range word or the locale's dash. An end that names a day
# or longer runs to its last nanosecond; a time is an instant.
my $N = 'Time::Keeper::Natural';
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, minute => 30, zone => 'Europe/London');
my $A = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, minute => 5, zone => 'Europe/London');
sub iv {
    my ($loc, $text, @opt) = @_;
    my @r = eval { $N->new(locale => $loc, zone => 'Europe/London', @opt)->parse_interval($text) };
    return @r ? join(' / ', @r) : "died: $@";
}
my $DAY_END = 'T23:59:59.999999999';

# What format_interval writes, read back.
for my $c (['en', 'yMMMd', [days => 2], "2026-10-15T00:00:00+01:00 / 2026-10-17${DAY_END}+01:00"],
           ['en', 'yMMMd', [months => 1, days => 3], "2026-10-15T00:00:00+01:00 / 2026-11-18${DAY_END}+00:00"],
           ['en', 'hm', [hours => 3, minutes => 20], '2026-10-15T09:05:00+01:00 / 2026-10-15T12:25:00+01:00'],
           ['en-GB', 'yMMMd', [days => 2], "2026-10-15T00:00:00+01:00 / 2026-10-17${DAY_END}+01:00"],
           ['fr', 'yMMMd', [days => 2], "2026-10-15T00:00:00+01:00 / 2026-10-17${DAY_END}+01:00"],
           ['de', 'yMMM', [months => 1], "2026-10-01T00:00:00+01:00 / 2026-11-30${DAY_END}+00:00"],
           ['ja', 'yMMMd', [days => 2], "2026-10-15T00:00:00+01:00 / 2026-10-17${DAY_END}+01:00"],
           ['ja', 'hm', [hours => 3, minutes => 20], '2026-10-15T09:05:00+01:00 / 2026-10-15T12:25:00+01:00'],
           ['ar-EG', 'yMMMd', [days => 2], "2026-10-15T00:00:00+01:00 / 2026-10-17${DAY_END}+01:00"],
           ['es-CO', 'Hm', [hours => 3, minutes => 20], '2026-10-15T09:05:00+01:00 / 2026-10-15T12:25:00+01:00'],
           ['zh-Hant', 'hm', [minutes => 25], '2026-10-15T09:05:00+01:00 / 2026-10-15T09:30:00+01:00'],
           ['bal', 'hm', [days => 2], '2026-10-15T09:05:00+01:00 / 2026-10-17T09:05:00+01:00'],
           ['en', 'y', [years => 1], "2026-01-01T00:00:00+00:00 / 2027-12-31${DAY_END}+00:00"]) {
    my ($loc, $sk, $plus, $want) = @$c;
    my $x = $A->in_locale($loc);
    my $t = $x->format_interval($x->plus(@$plus), skeleton => $sk);
    is(iv($loc, $t), $want, "$loc $sk: '$t'");
}
like($A->in_locale('bal')->format_interval($A->plus(days => 2), skeleton => 'hm'), qr/^17-10-2026/, 'bal writes the end first round its dash, and is read so');
is(iv('en', 'Oct 15 - 17, 2026'), "2026-10-15T00:00:00+01:00 / 2026-10-17${DAY_END}+01:00", 'a hyphen typed for the dash');
is(iv('en', 'Oct 15 – Nov 18'), "2026-10-15T00:00:00+01:00 / 2026-11-18${DAY_END}+00:00", 'no year: the anchor\'s, and "15" and "18" are not years');

# ISO 8601, as Time::Keeper reads it.
is(iv('en', '2026-10-15T09:00/PT2H'), '2026-10-15T09:00:00+01:00 / 2026-10-15T11:00:00+01:00', 'ISO: a start and a duration');
is(iv('en', '2026-10-15/2026-10-17'), '2026-10-15T00:00:00+01:00 / 2026-10-17T00:00:00+01:00', 'ISO: two dates, as Time::Keeper reads them');

# Two phrases.
is(iv('en', 'Monday to Friday'), "2026-10-19T00:00:00+01:00 / 2026-10-23${DAY_END}+01:00", 'Monday to Friday: the Friday after that Monday, to its end');
is(iv('en', 'Friday to Monday'), "2026-10-16T00:00:00+01:00 / 2026-10-19${DAY_END}+01:00", 'Friday to Monday runs over the weekend');
is(iv('en', 'Mon-Fri'), "2026-10-19T00:00:00+01:00 / 2026-10-23${DAY_END}+01:00", 'a hyphen between two phrases');
is(iv('en', 'from 9 am to 5 pm'), '2026-10-15T09:00:00+01:00 / 2026-10-15T17:00:00+01:00', 'a time ends at that instant');
is(iv('en', 'between 9 am and 5 pm'), '2026-10-15T09:00:00+01:00 / 2026-10-15T17:00:00+01:00', 'between ... and');
is(iv('en', '10 pm to 2 am'), '2026-10-15T22:00:00+01:00 / 2026-10-16T02:00:00+01:00', 'an end with no date before its start is the next day\'s');
is(iv('en', '9 am to 5'), '2026-10-15T09:00:00+01:00 / 2026-10-15T17:00:00+01:00', 'a bare hour at the end is the next after the start');
is(iv('en', '9 to 5', bare_hour => 'am'), '2026-10-15T09:00:00+01:00 / 2026-10-15T17:00:00+01:00', '9 to 5 with bare_hour am');
like(iv('en', '9 to 5'), qr/cannot read '9 to 5' at '9': no such word in en/, 'and without it the start is a bare hour');
is(iv('en-GB', '15 to 17 October'), "2026-10-15T00:00:00+01:00 / 2026-10-17${DAY_END}+01:00", 'a day number before a date takes its month');
is(iv('en', 'tomorrow until the end of next week'), "2026-10-16T00:00:00+01:00 / 2026-10-24${DAY_END}+01:00", 'until, to an end already at its end');

# Deaths.
like(iv('en', 'tomorrow to yesterday'), qr/^died: \Q$N\E->parse_interval: cannot read 'tomorrow to yesterday' at 'tomorrow': the interval ends before it starts at /, 'an end before its start');
like(iv('en', 'Oct 17 – 15, 2026'), qr/the interval ends before it starts/, 'in a written interval too');
like(iv('en', 'tomorrow'), qr/cannot read 'tomorrow' at 'tomorrow': a single time, not an interval/, 'one time');
like(iv('en', '2026-10-15'), qr/a single time, not an interval/, 'a date with hyphens is one time');
like(iv('en', 'zzz to qqq'), qr/at 'zzz': no such word in en/, 'words that are not');
like(iv('en', '  '), qr/: the text is empty at /, 'an empty text');
ok(!eval { $N->new->parse_interval(undef); 1 }, 'no text dies');
like($@, qr/^\Q$N->parse_interval: the text is undefined\E/, '  outside the reading shape');

# The Match, the try_ form and the class form.
{
    my $n = $N->new(locale => 'en', zone => 'Europe/London');
    my $m = $n->match_interval('  Monday to Friday ');
    isa_ok($m, 'Time::Keeper::Natural::Match');
    is($m->kind, 'interval', 'kind');
    is($m->value . '', '2026-10-19T00:00:00+01:00', 'value is the start');
    is($m->to . '', "2026-10-23${DAY_END}+01:00", 'to is the end');
    is($m->precision, 'day', 'precision is the start\'s');
    is_deeply([$m->assumed], ['weekday next', 'time', 'zone'], 'what either end assumed');
    is_deeply([$m->start, $m->end], [2, 18], 'start and end are where the text is');
    is($n->match('Monday')->to, undef, 'to is undef on a point');
    is($n->match_interval('tomorrow'), undef, 'a death is undef');
    local $@ = 'left alone';
    is_deeply([$n->try_parse_interval('tomorrow')], [], 'try_parse_interval: an empty list');
    is($@, 'left alone', '  and $@ left alone');
    is(scalar(my @r = $n->try_parse_interval('Monday to Friday')), 2, '  two values when it reads');
    is(join(' / ', $N->parse_interval('9:00 – 10:30', locale => 'en-GB', zone => 'Asia/Tokyo')),
       '2026-10-15T09:00:00+09:00 / 2026-10-15T10:30:00+09:00', 'the class form takes the options');
    my @r2 = $N->new(locale => 'fr', zone => 'Europe/Paris')->parse_interval('15–17 oct. 2026');
    is($r2[0]->locale, 'fr', 'the values are in the parser\'s locale');
    is($r2[1]->zone_name, 'Europe/Paris', '  and zone');
}

done_testing;
