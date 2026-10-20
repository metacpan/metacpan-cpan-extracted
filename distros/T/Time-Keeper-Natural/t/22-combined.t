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

# A day and a time, either way round.
{
    my %want = (
        'next Tuesday 3 pm'               => '2026-10-20T15:00:00+01:00',
        '3 pm next Tuesday'               => '2026-10-20T15:00:00+01:00',
        'next Tuesday 15:30'              => '2026-10-20T15:30:00+01:00',
        'tomorrow 15:30'                  => '2026-10-16T15:30:00+01:00',
        'tomorrow noon'                   => '2026-10-16T12:00:00+01:00',
        'noon tomorrow'                   => '2026-10-16T12:00:00+01:00',
        'tomorrow 3 in the afternoon'     => '2026-10-16T15:00:00+01:00',
        'yesterday midnight'              => '2026-10-14T00:00:00+01:00',
        '15 October 9 am'                 => '2026-10-15T09:00:00+01:00',
        '15 October 2026 9 am'            => '2026-10-15T09:00:00+01:00',
        '9 am 15 October'                 => '2026-10-15T09:00:00+01:00',
        '15/10/2026 15:30'                => '2026-10-15T15:30:00+01:00',
        'Thursday, 15 October 2026, 15:30' => '2026-10-15T15:30:00+01:00',
        'next week 9 am'                  => '2026-10-19T09:00:00+01:00',
        'next month 9:30'                 => '2026-11-01T09:30:00+00:00',
        'in 3 days 5 pm'                  => '2026-10-18T17:00:00+01:00',
        '2026-10-20 15:30'                => '2026-10-20T15:30:00+01:00',
    );
    for my $text (sort keys %want) {
        is(str(sub { $n->parse($text) }), $want{$text}, "'$text'");
    }
    is(str(sub { $n->in_locale('en-US')->parse('Oct 20 3 pm') }), '2026-10-20T15:00:00+01:00', 'en-US');
    is(str(sub { $n->in_locale('fr')->parse('demain 15:30') }), '2026-10-16T15:30:00+01:00', 'fr');
    is(str(sub { $n->in_locale('fr')->parse('jeudi 15 octobre 2026 15:30') }), '2026-10-15T15:30:00+01:00', 'fr a full date and a time');
    is(str(sub { $n->in_locale('de')->parse('morgen 15:30') }), '2026-10-16T15:30:00+01:00', 'de');
    is(str(sub { $n->in_locale('de')->parse('15. Oktober 15 Uhr') }), '2026-10-15T15:00:00+01:00', 'de date and Uhr');
    dies_like(sub { $n->parse('Oct 20') }, qr/no such word/, 'a bare number is never the time of an absolute date');
    dies_like(sub { $n->in_locale('en-US')->new(bare_hour => 'pm')->parse('15 October 3') }, qr/no such word/, 'not even with the option');
    is(str(sub { $n->in_locale('ja')->parse('明日15:30') }), '2026-10-16T15:30:00+01:00', 'ja, nothing between');
    is(str(sub { $n->in_locale('ja')->parse('来週の火曜日15:30') }), '2026-10-20T15:30:00+01:00', 'ja weekday');
    is(str(sub { $n->in_locale('ja')->parse('10月15日 15:30') }), '2026-10-15T15:30:00+01:00', 'ja date and time');
    is(str(sub { $n->parse_date('next Tuesday 3 pm') }), '2026-10-20', 'as a date');
    is(str(sub { $n->parse('tomorrow 3') }), '2026-10-16T03:00:00+01:00', 'a bare hour on a day: 03:00 in en-GB');
    is(str(sub { $n->in_locale('en-US')->new(bare_hour => 'pm')->parse('tomorrow 3') }), '2026-10-16T15:00:00+01:00', 'in en-US by the option');
    is(str(sub { $n->in_locale('en-US')->new(bare_hour => 'next')->parse('tomorrow 3') }), '2026-10-16T15:00:00+01:00', 'next on another day is by the anchor\'s time of day');
}

# A time into a clock change.
{
    my $spring = $N->new(now => Time::Keeper->new(year => 2027, month => 3, day => 27, hour => 9, zone => 'Europe/London', locale => 'en-GB'));
    is(str(sub { $spring->parse('tomorrow 1:30') }), '2027-03-28T02:30:00+01:00', 'a time the clocks skipped moves forward');
    is(str(sub { $spring->parse('tomorrow 0:30') }), '2027-03-28T00:30:00+00:00', 'one before the change stands');
}

# Deaths.
{
    dies_like(sub { $n->in_locale('en-US')->parse('tomorrow 3') }, qr/cannot read 'tomorrow 3' at '3': a bare hour; say am, pm or pass bare_hour/, 'a bare hour on a day in en-US');
    dies_like(sub { $n->parse('in 3 hours 5 pm') }, qr/^\Q$N->parse: cannot read 'in 3 hours 5 pm' at 'in': a time on a time\E/, 'a time on a time');
    dies_like(sub { $n->parse('Tuesday 15 October 3 pm') }, qr/2026-10-15 was a Thursday/, 'the weekday still checked');
    dies_like(sub { $n->parse('tomorrow xyzzy') }, qr/at 'xyzzy': no such word/, 'a word after a day');
    dies_like(sub { $n->parse('3 pm 4 pm') }, qr/no such word/, 'two times');
    is($n->in_locale('en-US')->try_parse('tomorrow 3'), undef, 'try_parse gives undef');
}

done_testing;
