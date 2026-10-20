#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;
use Time::Keeper::Natural::Match;

my $N = 'Time::Keeper::Natural';
my $M = 'Time::Keeper::Natural::Match';
my $anchor = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London', locale => 'en-GB');
local $Time::Keeper::CLOCK = $anchor;
my $n = $N->new(zone => 'Europe/London', locale => 'en-GB');

# The object.
{
    my $m = $n->match('next Tuesday at 3 pm');
    isa_ok($m, $M);
    is('' . $m->value, '2026-10-20T15:00:00+01:00', 'value');
    is($m->kind, 'point', 'kind');
    is($m->precision, 'hour', 'precision');
    is_deeply([$m->assumed], ['zone'], 'assumed: only the zone');
    is($m->text, 'next Tuesday at 3 pm', 'text');
    is_deeply([$m->start, $m->end], [0, 20], 'start and end');
    is($m->locale, 'en-GB', 'locale');
    is($m->anchor->epoch, $anchor->epoch, 'anchor');
    is('' . $m->value, '' . $n->parse('next Tuesday at 3 pm'), 'the value parse gives');
    my $p = $n->match("  tomorrow \t");
    is_deeply([$p->start, $p->end], [2, 10], 'start and end skip the outer whitespace');
    ok(!eval { $m->{value} = 1; 1 }, 'a write dies');
    ok(!eval { $m->{other} = 1; 1 }, 'so does a new key');
    my @a = $m->assumed;
    push @a, 'x';
    is_deeply([$m->assumed], ['zone'], 'and the list handed out is a copy');
    is_deeply([$M->assumptions], ['year', 'month', 'century', 'date', 'time', 'period start', 'weekday next', 'weekday last',
                                  'direction', 'bare_hour am', 'bare_hour pm', 'bare_hour next', 'zone'], 'the assumptions, the whole list');
    ok(!eval { $M->_new(value => 1, kind => 'point', precision => 'day', assumed => ['a guess'], text => 'x'); 1 }, 'an assumption not on it dies');
    like($@, qr/'a guess' is not an assumption/, 'by name');
}

# Each assumption, made by one phrase, and absent from a complete one.
{
    my %want = (
        'tomorrow'                     => [qw(time zone)],
        'next month'                   => ['period start', 'zone'],
        'in 3 days'                    => ['zone'],
        '15 October'                   => [qw(time year zone)],
        '15 October 2026'              => [qw(time zone)],
        '15:30'                        => [qw(date zone)],
        'Tuesday'                      => ['weekday next', 'time', 'zone'],
        'next Tuesday'                 => [qw(time zone)],
        'end of last month'            => ['zone'],
        'the third Friday of next month' => [qw(time zone)],
        '2026-10-20T15:00:00Z'         => [],
        '2026-10-20T15:00:00+09:00'    => [],
        '2026-10-20T15:00:00'          => ['zone'],
        '2026-10-20'                   => [qw(time zone)],
        'tomorrow 15:30'               => ['zone'],
        'next week 9 am'               => ['period start', 'zone'],
        'the 20th'                     => [qw(month time zone)],
    );
    for my $text (sort keys %want) {
        my $m = $n->match($text);
        is_deeply([ $m ? $m->assumed : 'no match' ], $want{$text}, "'$text': " . join(', ', @{ $want{$text} }));
    }
    is_deeply([ $n->new(prefer => 'past')->match('Tuesday')->assumed ], ['weekday last', 'time', 'zone'], 'weekday last');
    is_deeply([ $n->new(prefer => 'future')->match('3 March')->assumed ], [qw(time year zone)], 'year, moved by prefer');
    is_deeply([ $n->in_locale('hi')->match('15/10/26')->assumed ], [qw(time century zone)], 'century');
    is_deeply([ $n->in_locale('hi')->new(prefer => 'future')->match("\x{915}\x{932}")->assumed ], [qw(time direction zone)], 'direction, a two-way phrase that prefer decided');
    my $us = $n->in_locale('en-US');
    is_deeply([ $us->new(bare_hour => $_)->match('3')->assumed ], ["bare_hour $_", 'date', 'zone'], "bare_hour $_, in the order made") for qw(am pm next);
    my %used = map { $_ => 1 } map { @$_ } values %want;
    $used{$_} = 1 for 'weekday last', 'century', 'direction', map { "bare_hour $_" } qw(am pm next);
    is_deeply([ grep { !$used{$_} } $M->assumptions ], [], 'every assumption is made by some phrase above');
}

# Precision.
{
    my %want = (
        'next year' => 'year', 'next quarter' => 'quarter', 'next month' => 'month', 'next week' => 'week',
        'tomorrow' => 'day', 'next Tuesday' => 'day', '15 October' => 'day', '3 pm' => 'hour', '15:30' => 'minute',
        '15:30:45' => 'second', 'now' => 'second', 'in 3 hours' => 'hour', 'in 90 minutes' => 'minute',
        'in 2 days and 500 milliseconds' => 'millisecond', 'end of last month' => 'month', 'October 2026' => 'month',
        '2026' => 'year', '2026-10-20T15:00:00Z' => 'second', '2026-10-20' => 'day',
    );
    is($n->match($_) && $n->match($_)->precision, $want{$_}, "'$_' is $want{$_}") for sort keys %want;
}

# The two siblings.
{
    my $d = $n->match_date('next Tuesday at 3 pm');
    isa_ok($d->value, 'Time::Keeper::Date');
    is('' . $d->value, '2026-10-20', 'match_date gives a date');
    is($d->kind, 'date', 'of kind date');
    is($d->precision, 'hour', 'with the precision the text named');
    my $u = $n->match_duration('1 hour, 30 minutes');
    isa_ok($u->value, 'Time::Keeper::Duration');
    is('' . $u->value, 'PT1H30M', 'match_duration');
    is($u->kind, 'duration', 'of kind duration');
    is($u->precision, 'none', 'and precision none');
    is_deeply([$u->assumed], [], 'nothing assumed');
    is($N->match('tomorrow', locale => 'fr'), undef, 'the class form, English in French: undef');
    is('' . $N->match('demain', locale => 'fr', zone => 'Europe/London')->value, '2026-10-16T00:00:00+01:00', 'the class form');
}

# Nothing that does not read dies.
{
    local $@ = 'left alone';
    is($n->match($_), undef, "match('" . ($_ // 'undef') . "') is undef") for 'nonsense', '', '   ', undef, 'end of', 'in 3 days ago', '2 weeks', 'Tuesday 15 October';
    is($n->in_locale('en-US')->match('3'), undef, 'a bare hour');
    is($n->match_duration('tomorrow'), undef, 'match_duration of a time');
    is($n->match_date('xyzzy'), undef, 'match_date of nothing');
    is($@, 'left alone', '$@ is left alone');
}

done_testing;
