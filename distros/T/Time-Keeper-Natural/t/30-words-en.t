#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;

my $N = 'Time::Keeper::Natural';
sub str { my ($code) = @_; my $v = eval { $code->() }; return defined $v ? "$v" : "died: $@" }
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}
my $anchor = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London', locale => 'en-GB');
local $Time::Keeper::CLOCK = $anchor;
my $n = $N->new(zone => 'Europe/London', locale => 'en-GB');

# The start and the end of a period.
{
    my %want = (
        'end of last month'          => '2026-09-30T23:59:59.999999999+01:00',
        'start of next week'         => '2026-10-19T00:00:00+01:00',
        'end of next week'           => '2026-10-25T23:59:59.999999999+00:00',
        'the end of the year'        => '2026-12-31T23:59:59.999999999+00:00',
        'the start of the year'      => '2026-01-01T00:00:00+00:00',
        'start of the month'         => '2026-10-01T00:00:00+01:00',
        'the end of the month'       => '2026-10-31T23:59:59.999999999+00:00',
        'end of the week'            => '2026-10-18T23:59:59.999999999+01:00',
        'end of the day'             => '2026-10-15T23:59:59.999999999+01:00',
        'end of today'               => '2026-10-15T23:59:59.999999999+01:00',
        'end of tomorrow'            => '2026-10-16T23:59:59.999999999+01:00',
        'beginning of October 2026'  => '2026-10-01T00:00:00+01:00',
        'the beginning of October'   => '2026-10-01T00:00:00+01:00',
        'end of October'             => '2026-10-31T23:59:59.999999999+00:00',
        'end of 2026'                => '2026-12-31T23:59:59.999999999+00:00',
        'end of 15 October'          => '2026-10-15T23:59:59.999999999+01:00',
        'end of next Tuesday'        => '2026-10-20T23:59:59.999999999+01:00',
        'end of Tuesday'             => '2026-10-20T23:59:59.999999999+01:00',
        'end of this quarter'        => '2026-12-31T23:59:59.999999999+00:00',
        'start of last year'         => '2025-01-01T00:00:00+00:00',
        'start of in 3 days'         => '2026-10-18T00:00:00+01:00',
        'end of 3 days ago'          => '2026-10-12T23:59:59.999999999+01:00',
    );
    for my $text (sort keys %want) {
        is(str(sub { $n->parse($text) }), $want{$text}, "'$text'");
    }
    is(str(sub { $n->in_locale('en-US')->parse('end of the week') }), '2026-10-17T23:59:59.999999999+01:00', 'en-US: the week ends on Saturday');
    is(str(sub { $n->parse_date('end of last month') }), '2026-09-30', 'as a date');
    is(str(sub { $N->parse('end of last month', locale => 'en', zone => 'Europe/London') }), '2026-09-30T23:59:59.999999999+01:00', 'the class form, in en');
}

# at, on, the, and a bare weekday.
{
    my %want = (
        'at 3 pm'                 => '2026-10-15T15:00:00+01:00',
        'at 15:30'                => '2026-10-15T15:30:00+01:00',
        'tomorrow at 3 pm'        => '2026-10-16T15:00:00+01:00',
        'at 3 pm tomorrow'        => '2026-10-16T15:00:00+01:00',
        'next Tuesday at 15:30'   => '2026-10-20T15:30:00+01:00',
        'at 9 at night'           => '2026-10-15T21:00:00+01:00',
        'tomorrow at 9 at night'  => '2026-10-16T21:00:00+01:00',
        'at noon tomorrow'        => '2026-10-16T12:00:00+01:00',
        'on Tuesday'              => '2026-10-20T00:00:00+01:00',
        'on Tuesday at 9 am'      => '2026-10-20T09:00:00+01:00',
        'at 9 am on Tuesday'      => '2026-10-20T09:00:00+01:00',
        'on 15 October'           => '2026-10-15T00:00:00+01:00',
        'on 15 October at 3 pm'   => '2026-10-15T15:00:00+01:00',
        'on the 15 October'       => '2026-10-15T00:00:00+01:00',
        'Tuesday'                 => '2026-10-20T00:00:00+01:00',
        'Thursday'                => '2026-10-15T00:00:00+01:00',
        'Wednesday'               => '2026-10-21T00:00:00+01:00',
        'Tuesday at 9 am'         => '2026-10-20T09:00:00+01:00',
        'Tue 9 am'                => '2026-10-20T09:00:00+01:00',
        'the next Tuesday'        => '2026-10-20T00:00:00+01:00',
        'the day after tomorrow'  => '2026-10-17T00:00:00+01:00',
        'on tomorrow'             => '2026-10-16T00:00:00+01:00',
        '@ 3 pm'                  => '2026-10-15T15:00:00+01:00',
    );
    delete $want{'the day after tomorrow'} unless exists Time::Keeper::Locale->relative_names('en-GB', 'day')->{at}{2};
    for my $text (sort keys %want) {
        is(str(sub { $n->parse($text) }), $want{$text}, "'$text'");
    }
    is(str(sub { $n->new(prefer => 'past')->parse('Tuesday') }), '2026-10-13T00:00:00+01:00', 'prefer past: the last Tuesday');
    is(str(sub { $n->new(prefer => 'past')->parse('Thursday') }), '2026-10-15T00:00:00+01:00', 'and Thursday is still today');
    is(str(sub { $n->new(prefer => 'future')->parse('Thursday') }), '2026-10-15T00:00:00+01:00', 'as it is under future');
    is(str(sub { $n->in_locale('fr')->parse('mardi') }), '2026-10-20T00:00:00+01:00', 'a bare weekday needs no table: fr mardi');
    is(str(sub { $n->in_locale('de')->parse('Dienstag 15:30') }), '2026-10-20T15:30:00+01:00', 'de Dienstag with a time');
}

# Deaths.
{
    dies_like(sub { $n->parse('end of in 3 hours') }, qr/^\Q$N->parse: cannot read 'end of in 3 hours' at 'in': a moment, not a period\E/, 'a moment has no end');
    dies_like(sub { $n->parse('end of 15:30') }, qr/a moment, not a period|no such word/, 'nor a time');
    dies_like(sub { $n->parse('end of') }, qr/^\Q$N->parse: cannot read 'end of' at 'end of': nothing left after 'end of'\E/, 'end of nothing');
    dies_like(sub { $n->parse('at') }, qr/nothing left after 'at'/, 'at nothing');
    dies_like(sub { $n->parse('end of xyzzy') }, qr/no such word in en-GB/, 'end of a word it has not');
    dies_like(sub { $n->parse('at tomorrow') }, qr/no such word/, 'at a day is not a time');
    dies_like(sub { $n->in_locale('fr')->parse('end of last month') }, qr/no such word in fr/, 'French does not read English words');
    dies_like(sub { $n->in_locale('sw')->parse('end of last month') }, qr/coverage of sw is data; 'end of' needs its words/, 'a locale with no table says so');
    is($n->try_parse('end of'), undef, 'try_parse gives undef');
}

done_testing;
