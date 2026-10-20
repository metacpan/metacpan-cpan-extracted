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
sub str {
    my ($code) = @_;
    my $v = eval { $code->() };
    return defined $v ? "$v" : "died: $@";
}
my $L = 'Time::Keeper::Locale';
my @KEYS = qw(mon tue wed thu fri sat sun);
my $thursday = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London', locale => 'en-GB');
local $Time::Keeper::CLOCK = $thursday;

# From each of seven anchors, next, last and this for each of seven days.
{
    my ($asks, @bad) = (0);
    for my $offset (0 .. 6) {
        my $anchor = $thursday->plus(days => $offset);
        my $n = $N->new(now => $anchor);
        my $week = $anchor->truncate(to => 'week', week_start => 'locale');
        for my $d (1 .. 7) {
            my $r = $L->relative_names('en-GB', $KEYS[ $d - 1 ]);
            my %want = (
                1  => $anchor->next(day_of_week => $d)->truncate(to => 'day'),
                -1 => $anchor->previous(day_of_week => $d)->truncate(to => 'day'),
                0  => $week->plus(days => ($d - $week->day_of_week) % 7),
            );
            for my $k (-1, 0, 1) {
                $asks++;
                my $got = eval { $n->parse($r->{at}{$k}) };
                push @bad, "$anchor '$r->{at}{$k}': " . ($got ? "$got" : $@) unless $got && $got->epoch == $want{$k}->epoch;
            }
        }
    }
    ok(!@bad, "next, last and this from every day of the week ($asks asks)") or diag(join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)]);
}

# On the day itself, and the rest of the surface.
{
    my $n = $N->new(zone => 'Europe/London', locale => 'en-GB');
    is(str(sub { $n->parse('next Thursday') }), '2026-10-22T00:00:00+01:00', 'next Thursday on a Thursday is a week on');
    is(str(sub { $n->parse('this Thursday') }), '2026-10-15T00:00:00+01:00', 'this Thursday is today');
    is(str(sub { $n->parse('last Thursday') }), '2026-10-08T00:00:00+01:00', 'last Thursday a week back');
    is(str(sub { $n->parse('next Tuesday') }), '2026-10-20T00:00:00+01:00', 'next Tuesday');
    is(str(sub { $n->parse('last Tuesday') }), '2026-10-13T00:00:00+01:00', 'last Tuesday');
    is(str(sub { $n->parse('this Tuesday') }), '2026-10-13T00:00:00+01:00', 'this Tuesday is the week\'s, already past');
    is(str(sub { $n->parse('this Sunday') }), '2026-10-18T00:00:00+01:00', 'this Sunday ends an en-GB week');
    is(str(sub { $n->in_locale('en-US')->parse('this Sunday') }), '2026-10-11T00:00:00+01:00', 'and starts an en-US one');
    is(str(sub { $n->parse('next Tue.') }), '2026-10-20T00:00:00+01:00', 'the short width');
    is(str(sub { $n->parse('next Tu') }), '2026-10-20T00:00:00+01:00', 'the narrow one');
    is(str(sub { $n->parse('in 2 Tuesdays') }), '2026-10-27T00:00:00+00:00', 'in 2 Tuesdays');
    is(str(sub { $n->parse('in 1 Tuesday') }), '2026-10-20T00:00:00+01:00', 'in 1 Tuesday is next Tuesday');
    is(str(sub { $n->parse('2 Tuesdays ago') }), '2026-10-06T00:00:00+01:00', '2 Tuesdays ago');
    is(str(sub { $n->in_locale('fr')->parse('mardi prochain') }), '2026-10-20T00:00:00+01:00', 'fr mardi prochain');
    is(str(sub { $n->in_locale('fr')->parse('mardi dernier') }), '2026-10-13T00:00:00+01:00', 'fr mardi dernier');
    is(str(sub { $n->in_locale('de')->parse('letzten Dienstag') }), '2026-10-13T00:00:00+01:00', 'de letzten Dienstag');
    is(str(sub { $n->in_locale('de')->parse('nächsten Dienstag') }), '2026-10-20T00:00:00+01:00', 'de nächsten Dienstag');
    is(str(sub { $n->in_locale('ja')->parse('来週の火曜日') }), '2026-10-20T00:00:00+01:00', 'ja next Tuesday');
    is(str(sub { $n->in_locale('ja')->parse('先週の火曜日') }), '2026-10-13T00:00:00+01:00', 'ja last Tuesday');
    is(str(sub { $n->parse_date('next Tuesday') }), '2026-10-20', 'as a date');
    is($n->parse('next Tuesday')->hour, 0, 'the day\'s first moment');
}

done_testing;
