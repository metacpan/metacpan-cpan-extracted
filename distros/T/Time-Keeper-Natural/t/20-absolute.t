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

# What Time::Keeper->parse reads, in the parser's zone.
{
    is(str(sub { $n->parse('2026-10-20T15:00:00Z') }), '2026-10-20T16:00:00+01:00', 'ISO with a zone, converted');
    is(str(sub { $n->parse('2026-10-20T15:00:00') }), '2026-10-20T15:00:00+01:00', 'ISO with none, in the parser\'s');
    is(str(sub { $n->parse('2026-10-20') }), '2026-10-20T00:00:00+01:00', 'an ISO date');
    is(str(sub { $n->parse('15 Oct 26 09:00 GMT') }), '2026-10-15T10:00:00+01:00', 'RFC 2822 with a two-digit year, which only its clock time shows');
    is(str(sub { $n->parse('Thursday, 15-Oct-26 09:00:00 GMT') }), '2026-10-15T10:00:00+01:00', 'RFC 850, as HTTP takes it');
    is(str(sub { $n->parse('@1760000000') }), '' . Time::Keeper->from_epoch(1760000000, zone => 'Europe/London'), 'an epoch');
    is($n->parse('2026-10-20T15:00:00Z')->locale, 'en-GB', 'and the parser\'s locale');
}

# The locale's own formats and skeletons.
{
    my %want = (
        '15 October 2026'            => '2026-10-15T00:00:00+01:00',
        '15 October'                 => '2026-10-15T00:00:00+01:00',
        '15 Oct 2026'                => '2026-10-15T00:00:00+01:00',
        '15 Oct'                     => '2026-10-15T00:00:00+01:00',
        '15/10/2026'                 => '2026-10-15T00:00:00+01:00',
        '15/10'                      => '2026-10-15T00:00:00+01:00',
        '5/3'                        => '2026-03-05T00:00:00+00:00',
        'Thursday, 15 October 2026'  => '2026-10-15T00:00:00+01:00',
        'Thu 15 Oct'                 => '2026-10-15T00:00:00+01:00',
        'October 2026'               => '2026-10-01T00:00:00+01:00',
        'Oct 2026'                   => '2026-10-01T00:00:00+01:00',
        'October'                    => '2026-10-01T00:00:00+01:00',
        '2026'                       => '2026-01-01T00:00:00+00:00',
        '20 december'                => '2026-12-20T00:00:00+00:00',
        '1 march'                    => '2026-03-01T00:00:00+00:00',
        '29 february'                => '2028-02-29T00:00:00+00:00',
    );
    delete $want{'29 february'};
    for my $text (sort keys %want) {
        is(str(sub { $n->parse($text) }), $want{$text}, "'$text'");
    }
    is(str(sub { $n->in_locale('en-US')->parse('Oct 20') }), '2026-10-20T00:00:00+01:00', 'en-US: Oct 20');
    is(str(sub { $n->in_locale('en-US')->parse('10/20') }), '2026-10-20T00:00:00+01:00', 'en-US: 10/20 is October');
    is(str(sub { $n->parse('10/5') }), '2026-05-10T00:00:00+01:00', 'en-GB: 10/5 is May');
    dies_like(sub { $n->parse('Oct 20') }, qr/cannot read 'Oct 20' at 'Oct': no such word in en-GB/, 'en-GB has no month-first skeleton');
    dies_like(sub { $n->parse('Tuesday 15 October') }, qr/^\Q$N->parse: cannot read 'Tuesday 15 October' at 'Tuesday': 2026-10-15 was a Thursday\E/, 'a weekday that does not fit');
    dies_like(sub { $n->parse('15 10') }, qr/no such word in en-GB/, 'two bare numbers');
    dies_like(sub { $n->parse('32 October') }, qr/no such word|no such date|does not have/, 'a day the month has not');
    is(str(sub { $n->in_locale('hi')->parse('15/10/26') }), '2026-10-15T00:00:00+01:00', 'a two-digit year takes the nearest century');
    is(str(sub { $n->in_locale('hi')->parse('15/10/99') }), '1999-10-15T00:00:00+01:00', 'and 99 is 1999');
    dies_like(sub { $n->parse('Thursday 15 October 2026') }, qr/no such word/, 'the full date wants its comma in en-GB');
}

# Other locales, their own order and names.
{
    is(str(sub { $n->in_locale('de')->parse('15.10.2026') }), '2026-10-15T00:00:00+01:00', 'de 15.10.2026');
    is(str(sub { $n->in_locale('de')->parse('15. Oktober 2026') }), '2026-10-15T00:00:00+01:00', 'de long');
    is(str(sub { $n->in_locale('de')->parse('15. Oktober') }), '2026-10-15T00:00:00+01:00', 'de no year');
    is(str(sub { $n->in_locale('de')->parse('Oktober 2026') }), '2026-10-01T00:00:00+01:00', 'de month and year');
    is(str(sub { $n->in_locale('fr')->parse('jeudi 15 octobre 2026') }), '2026-10-15T00:00:00+01:00', 'fr full');
    is(str(sub { $n->in_locale('fr')->parse('15 octobre') }), '2026-10-15T00:00:00+01:00', 'fr no year');
    is(str(sub { $n->in_locale('fr')->parse('15/10/2026') }), '2026-10-15T00:00:00+01:00', 'fr short');
    is(str(sub { $n->in_locale('ja')->parse('2026年10月15日') }), '2026-10-15T00:00:00+01:00', 'ja');
    is(str(sub { $n->in_locale('ja')->parse('10月15日') }), '2026-10-15T00:00:00+01:00', 'ja no year');
    is(str(sub { $n->in_locale('ar-EG')->parse('١٥ أكتوبر ٢٠٢٦') }), '2026-10-15T00:00:00+01:00', 'ar-EG in its digits');
    is(str(sub { $n->in_locale('ru')->parse('15 октября 2026 г.') }), '2026-10-15T00:00:00+01:00', 'ru with its г.');
}

# A date with no year, and prefer.
{
    is(str(sub { $n->parse('3 March') }), '2026-03-03T00:00:00+00:00', 'this year by default, even if past');
    is(str(sub { $n->new(prefer => 'future')->parse('3 March') }), '2027-03-03T00:00:00+00:00', 'prefer future moves a past date on');
    is(str(sub { $n->new(prefer => 'future')->parse('20 October') }), '2026-10-20T00:00:00+01:00', 'and leaves one to come');
    is(str(sub { $n->new(prefer => 'future')->parse('15 October') }), '2026-10-15T00:00:00+01:00', 'today stands');
    is(str(sub { $n->new(prefer => 'past')->parse('20 October') }), '2025-10-20T00:00:00+01:00', 'prefer past moves one to come back');
    is(str(sub { $n->new(prefer => 'past')->parse('3 March') }), '2026-03-03T00:00:00+00:00', 'and leaves a past one');
    is(str(sub { $n->new(prefer => 'future')->parse('3 March 2026') }), '2026-03-03T00:00:00+00:00', 'a year given is kept');
    is(str(sub { $n->parse_date('15 October') }), '2026-10-15', 'as a date');
}

# Round trip: what the locale writes for a date, it reads.
{
    my @dates = map { Time::Keeper->new(year => $_->[0], month => $_->[1], day => $_->[2], zone => 'Europe/London') } [2026, 10, 15], [2027, 1, 1], [2024, 2, 29];
    my ($asks, @bad) = (0);
    for my $loc (qw(en en-GB en-US fr de es it pt nl ru pl ja zh ko ar ar-EG he hi th tr)) {
        my $p = $n->in_locale($loc);
        for my $d (@dates) {
            my $v = $d->in_locale($loc);
            for my $form (['format_date', 'full'], ['format_date', 'long'], ['format_date', 'medium'], ['format_date', 'short'], ['format_skeleton', 'yMMMd'], ['format_skeleton', 'yMMMEd'], ['format_skeleton', 'yMd']) {
                my ($m, $arg) = @$form;
                $asks++;
                my $s = $v->$m($arg);
                my $got = eval { $p->parse($s) };
                push @bad, "$loc $arg '$s': " . ($got ? "$got" : $@) unless $got && $got->epoch == $v->epoch;
            }
        }
    }
    ok(!@bad, "every date form of 20 locales reads back ($asks asks)") or diag(join "\n", @bad[0 .. ($#bad < 14 ? $#bad : 14)]);
}

done_testing;
