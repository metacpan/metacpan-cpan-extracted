#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;

# Absolute dates and times at the edges the C draws: a two-digit year (read
# by Time::Keeper's own pivot, the century assumed), an hour placed by the
# locale's day-period rules, and the precision an ISO time gives.
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, minute => 30, zone => 'Europe/London');
sub m1 { my ($loc, $text) = @_; return Time::Keeper::Natural->new(locale => $loc, zone => 'Europe/London')->match($text) }

is(m1('en-US', '1/15/50')->value . '', '2050-01-15T00:00:00+00:00', 'en-US: 50 is 2050, by Time::Keeper\'s pivot');
is_deeply([ m1('en-US', '1/15/50')->assumed ], [ 'time', 'century', 'zone' ], 'and the century is assumed');
is(m1('en-GB', '3 in the afternoon')->value . '', '2026-10-15T15:00:00+01:00', 'en-GB: an hour in the afternoon is after noon');
is(m1('en-GB', '11 in the morning')->value . '', '2026-10-15T11:00:00+01:00', 'en-GB: and one in the morning before');
is(m1('ja', '3 昼')->value . '', '2026-10-15T15:00:00+01:00', 'ja: 3 in the daytime is placed by the period\'s rule, after noon');
is(m1('ja', '3 昼')->precision, 'hour', 'to the hour');
is(m1('en-GB', '2026-10-20 15:30')->precision, 'minute', 'an ISO time to the minute is minute precision');
is(m1('en-GB', '2026-10-20T15:30:10')->precision, 'second', 'and to the second, second');
is(m1('en-GB', '2026-W43')->precision, 'week', 'an ISO week is a week');

done_testing;
