#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;

use Time::Keeper;
use Time::Keeper::Natural;

# A million calls of each kind (TKN_LEAK_N) must leave the process's
# resident size where ten thousand left it: the readers, the deaths, the
# Match and the try_ forms; 0.02's intervals, day ordinals and zones; 0.03's
# calendars, fractions and points. A byte leaked a call is a megabyte here.
my $N = $ENV{TKN_LEAK_N} || 1_000_000;
my $rss = sub { my $k = `ps -o rss= -p $$`; $k =~ s/\s+//g; return $k };
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
my $n = Time::Keeper::Natural->new(locale => 'en-GB', zone => 'Europe/London');
my $fr = Time::Keeper::Natural->new(locale => 'fr', zone => 'Europe/London');
my $heb = Time::Keeper::Natural->new(locale => 'en', zone => 'Europe/London', calendar => 'hebrew');
my @KINDS = (
    [ "parse('tomorrow')",            sub { $n->parse('tomorrow') } ],
    [ "parse('in 3 days')",           sub { $n->parse('in 3 days') } ],
    [ "parse('next Tuesday at 3 pm')", sub { $n->parse('next Tuesday at 3 pm') } ],
    [ "parse('15 October 2026')",     sub { $n->parse('15 October 2026') } ],
    [ "parse('end of last month')",   sub { $n->parse('end of last month') } ],
    [ 'parse_duration',               sub { $n->parse_duration('1 hour, 30 minutes') } ],
    [ 'match, a French chain',        sub { $fr->match('dans 2 semaines et 3 jours') } ],
    [ 'a death',                      sub { eval { $n->parse('next zzz') } } ],
    [ 'try_parse of nothing',         sub { $n->try_parse('zzz 3') } ],
    [ 'parse_interval, written',      sub { $n->parse_interval('15–17 Oct 2026') } ],
    [ 'parse_interval, two phrases',  sub { $n->parse_interval('Monday to Friday') } ],
    [ 'match_interval',               sub { $n->match_interval('9 am - 5 pm EST') } ],
    [ "parse('the 15th')",            sub { $n->parse('the 15th') } ],
    [ "parse('3 pm EST')",            sub { $n->parse('3 pm EST') } ],
    [ 'an ambiguous zone',            sub { eval { $n->parse('9 am IST') } } ],
    [ 'a failure that seeks a zone',  sub { $n->try_parse('meet at 3 pm on the moon') } ],
    [ 'a Hebrew date',                sub { $heb->parse('4 Heshvan 5787') } ],
    [ 'next month in Hebrew',         sub { $heb->parse('next month') } ],
    [ 'a fraction',                   sub { $n->parse_duration('1.5 hours') } ],
    [ 'after a point',                sub { $n->parse('3 days after tomorrow') } ],
    [ 'a day and its evening',        sub { $n->parse('tomorrow evening') } ],
    [ 'the weekend',                  sub { $n->parse('next weekend') } ],
);
for my $k (@KINDS) {
    my ($what, $code) = @$k;
    $code->() for 1 .. 10_000;
    my $before = $rss->();
    $code->() for 1 .. $N;
    my $grew = $rss->() - $before;
    cmp_ok($grew, '<', 1024, "$what: $N calls, resident size grew ${grew} KB");
}

done_testing;
