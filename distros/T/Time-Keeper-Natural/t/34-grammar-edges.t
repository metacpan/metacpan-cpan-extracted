#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;

# The word grammar at edges the C keeps: every skip word at a part's front
# is dropped, not only the first, and "on" takes a day and a time in either
# order.
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, minute => 30, zone => 'Europe/London');
sub p { my ($loc, $text) = @_; my $v = eval { Time::Keeper::Natural->new(locale => $loc, zone => 'Europe/London')->parse($text) }; return $v ? "$v" : "died: $@" }

is(p('en-GB', 'end of the the month'), '2026-10-31T23:59:59.999999999+00:00', 'en-GB: two articles in a row');
is(p('fr', 'fin de la la semaine'), '2026-10-18T23:59:59.999999999+01:00', 'fr: and in French');
is(p('en-GB', 'on Tuesday 3 pm'), '2026-10-20T15:00:00+01:00', 'en-GB: on a day and a time');
is(p('en-GB', 'on 3 pm Tuesday'), '2026-10-20T15:00:00+01:00', 'en-GB: on a time and a day');

done_testing;
