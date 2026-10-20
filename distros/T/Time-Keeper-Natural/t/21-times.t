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

# Times on the anchor's day.
{
    my %want = (
        '15:30'       => '2026-10-15T15:30:00+01:00',
        '9:05'        => '2026-10-15T09:05:00+01:00',
        '09:05'       => '2026-10-15T09:05:00+01:00',
        '15:30:45'    => '2026-10-15T15:30:45+01:00',
        '3 pm'        => '2026-10-15T15:00:00+01:00',
        '3 PM'        => '2026-10-15T15:00:00+01:00',
        '3pm'         => '2026-10-15T15:00:00+01:00',
        '3:30 pm'     => '2026-10-15T15:30:00+01:00',
        '3:30pm'      => '2026-10-15T15:30:00+01:00',
        '12 am'       => '2026-10-15T00:00:00+01:00',
        '12 pm'       => '2026-10-15T12:00:00+01:00',
        '3 in the afternoon' => '2026-10-15T15:00:00+01:00',
        '9 in the morning'   => '2026-10-15T09:00:00+01:00',
        '9 at night'         => '2026-10-15T21:00:00+01:00',
        'noon'        => '2026-10-15T12:00:00+01:00',
        'midnight'    => '2026-10-15T00:00:00+01:00',
        '15'          => '2026-10-15T15:00:00+01:00',
        '0'           => '2026-10-15T00:00:00+01:00',
        '23'          => '2026-10-15T23:00:00+01:00',
        '3'           => '2026-10-15T03:00:00+01:00',
    );
    for my $text (sort keys %want) {
        is(str(sub { $n->parse($text) }), $want{$text}, "'$text'");
    }
    is(str(sub { $n->in_locale('fr')->parse('15:30') }), '2026-10-15T15:30:00+01:00', 'fr');
    is(str(sub { $n->in_locale('fr')->parse('midi') }), '2026-10-15T12:00:00+01:00', 'fr midi');
    is(str(sub { $n->in_locale('fr')->parse('minuit') }), '2026-10-15T00:00:00+01:00', 'fr minuit');
    is(str(sub { $n->in_locale('fr')->parse('9') }), '2026-10-15T09:00:00+01:00', 'fr: a bare 9 is 09:00, the clock has twenty-four hours');
    is(str(sub { $n->in_locale('ja')->parse('15:30') }), '2026-10-15T15:30:00+01:00', 'ja');
    is(str(sub { $n->in_locale('ja')->parse('正午') }), '2026-10-15T12:00:00+01:00', 'ja noon');
    is(str(sub { $n->in_locale('ar-EG')->parse('٣:٣٠ م') }), '2026-10-15T15:30:00+01:00', 'ar-EG in its digits and its pm');
    is(str(sub { $n->in_locale('de')->parse('15 Uhr') }), '2026-10-15T15:00:00+01:00', 'de with its Uhr');
    is(str(sub { $n->parse_date('15:30') }), '2026-10-15', 'as a date');
    my $late = $N->new(now => Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 23, minute => 50, zone => 'Europe/London'));
    is(str(sub { $late->parse('9:00') }), '2026-10-15T09:00:00+01:00', 'a time is today even when past');
}

# The bare hour: en-GB's clock has twenty-four hours in CLDR, en-US's twelve.
{
    my $us = $n->in_locale('en-US');
    is(str(sub { $n->parse('3') }), '2026-10-15T03:00:00+01:00', 'en-GB: 3 is 03:00, the clock has twenty-four hours');
    is(str(sub { $n->new(bare_hour => 'pm')->parse('3') }), '2026-10-15T03:00:00+01:00', 'and the option does not apply to it');
    dies_like(sub { $us->parse('3') }, qr/^\Q$N->parse: cannot read '3' at '3': a bare hour; say am, pm or pass bare_hour\E/, 'en-US: a bare 3 dies');
    dies_like(sub { $us->parse('12') }, qr/a bare hour/, 'and 12');
    is(str(sub { $us->new(bare_hour => 'am')->parse('3') }), '2026-10-15T03:00:00+01:00', 'am');
    is(str(sub { $us->new(bare_hour => 'pm')->parse('3') }), '2026-10-15T15:00:00+01:00', 'pm');
    is(str(sub { $us->new(bare_hour => 'am')->parse('12') }), '2026-10-15T00:00:00+01:00', '12 am');
    is(str(sub { $us->new(bare_hour => 'pm')->parse('12') }), '2026-10-15T12:00:00+01:00', '12 pm');
    is(str(sub { $us->new(bare_hour => 'pm')->parse('15') }), '2026-10-15T15:00:00+01:00', '15 is 15 whatever the option');
    is(str(sub { $us->parse('0') }), '2026-10-15T00:00:00+01:00', 'and 0 is midnight');
    my %next = ('02:00' => '03:00', '09:00' => '15:00', '15:30' => '15:00', '23:00' => '15:00');
    for my $at (sort keys %next) {
        my ($h, $m) = split /:/, $at;
        my $p = $N->new(now => Time::Keeper->new(year => 2026, month => 10, day => 15, hour => $h, minute => $m, zone => 'Europe/London', locale => 'en-US'), bare_hour => 'next');
        is(str(sub { $p->parse('3') }), "2026-10-15T$next{$at}:00+01:00", "next at $at: 3 is $next{$at}");
    }
    dies_like(sub { $n->parse('24') }, qr/no such word/, '24 is not an hour');
    dies_like(sub { $n->parse('in the afternoon') }, qr/no such word/, 'a period with no hour');
    is($us->try_parse('3'), undef, 'try_parse gives undef');
}

done_testing;
