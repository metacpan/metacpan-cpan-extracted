#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;

# Relative phrases at the edges the C grammar draws: a joiner of two words
# (Tongan "mo e"), and a phrase CLDR gives two meanings, which 0.01 read in
# its hash's order and 0.02 refuses unless prefer picks (t/14 has the rest).
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, minute => 30, zone => 'Europe/London');
sub at { my ($loc, $text) = @_; my $v = eval { Time::Keeper::Natural->new(locale => $loc, zone => 'Europe/London')->parse($text) }; return $v ? "$v" : "died: $@" }

is(at('to', "ʻi he houa ʻe 2 mo e miniti ʻe 30"), '2026-10-15T12:00:00+01:00', 'to: two hours and thirty minutes, joined by two words');
is(at('to', "houa ʻe 2 kuoʻosi mo e miniti ʻe 30 kuoʻosi"), '2026-10-15T07:00:00+01:00', 'to: and in the past');
is(at('to', "ʻi he ʻaho ʻe 3 mo e ʻi he houa ʻe 4"), '2026-10-18T13:30:00+01:00', 'to: each part marked');
like(at('da', 'på ma.'), qr/'på ma\.' means this Monday and next Monday in da; pass prefer/, 'da: a phrase with two meanings dies naming both (0.02)');
is(Time::Keeper::Natural->new(locale => 'da', zone => 'Europe/London', prefer => 'future')->parse('på ma.') . '', '2026-10-19T00:00:00+01:00', 'prefer future: next Monday');
is(Time::Keeper::Natural->new(locale => 'da', zone => 'Europe/London', prefer => 'past')->parse('på ma.') . '', '2026-10-12T00:00:00+01:00', 'prefer past: this Monday');

done_testing;
