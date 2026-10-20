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
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}

my $anchor = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London', locale => 'en-GB');
local $Time::Keeper::CLOCK = $anchor;
my $n = $N->new(zone => 'Europe/London', locale => 'en-GB');

# The surface, Thursday 15 October 2026 at 09:00 in London.
{
    my %want = (
        'tomorrow'               => '2026-10-16T00:00:00+01:00',
        'yesterday'              => '2026-10-14T00:00:00+01:00',
        'today'                  => '2026-10-15T00:00:00+01:00',
        'now'                    => '2026-10-15T09:00:00+01:00',
        'in 3 days'              => '2026-10-18T09:00:00+01:00',
        '3 hours ago'            => '2026-10-15T06:00:00+01:00',
        'in 2 weeks and 3 days'  => '2026-11-01T09:00:00+00:00',
        'next month'             => '2026-11-01T00:00:00+00:00',
        'last month'             => '2026-09-01T00:00:00+01:00',
        'this month'             => '2026-10-01T00:00:00+01:00',
        'next year'              => '2027-01-01T00:00:00+00:00',
        'last year'              => '2025-01-01T00:00:00+00:00',
        'this year'              => '2026-01-01T00:00:00+00:00',
        'this week'              => '2026-10-12T00:00:00+01:00',
        'next week'              => '2026-10-19T00:00:00+01:00',
        'last week'              => '2026-10-05T00:00:00+01:00',
        'this quarter'           => '2026-10-01T00:00:00+01:00',
        'next quarter'           => '2027-01-01T00:00:00+00:00',
        'last quarter'           => '2026-07-01T00:00:00+01:00',
        'in 0 days'              => '2026-10-15T09:00:00+01:00',
        '0 days ago'             => '2026-10-15T09:00:00+01:00',
        'in 1 days'              => '2026-10-16T09:00:00+01:00',
        'in 2 years'             => '2028-10-15T09:00:00+01:00',
        '18 months ago'          => '2025-04-15T09:00:00+01:00',
        'in 90 minutes'          => '2026-10-15T10:30:00+01:00',
        '45 seconds ago'         => '2026-10-15T08:59:15+01:00',
        'in 2 wk.'               => '2026-10-29T09:00:00+00:00',
    );
    for my $text (sort keys %want) {
        is(str(sub { $n->parse($text) }), $want{$text}, "'$text'");
    }
    is($n->parse('tomorrow')->locale, 'en-GB', 'the value carries the locale');
    is($n->parse('tomorrow')->zone_name, 'Europe/London', 'and the zone');
    is(str(sub { $N->new(now => $anchor->plus(minutes => 37, seconds => 15))->parse('this hour') }), '2026-10-15T09:00:00+01:00', 'this hour');
    is(str(sub { $N->new(now => $anchor->plus(minutes => 37, seconds => 15))->parse('this minute') }), '2026-10-15T09:37:00+01:00', 'this minute');
    is(str(sub { $N->new(now => $anchor->plus(minutes => 37, seconds => 15))->parse('now') }), '2026-10-15T09:37:15+01:00', 'now is the anchor');
}

# The locale's week.
{
    is(str(sub { $n->in_locale('en-US')->parse('this week') }), '2026-10-11T00:00:00+01:00', 'en-US: the week starts on Sunday');
    is(str(sub { $n->in_locale('en')->parse('this week') }), '2026-10-11T00:00:00+01:00', 'and plain en is en-US');
    is(str(sub { $n->in_locale('fr')->parse('cette semaine') }), '2026-10-12T00:00:00+01:00', 'fr: on Monday');
    is(str(sub { $n->in_locale('ar-EG')->parse('هذا الأسبوع') }), '2026-10-10T00:00:00+01:00', 'ar-EG: on Saturday');
}

# Other locales' words.
{
    is(str(sub { $n->in_locale('fr')->parse('après-demain') }), '2026-10-17T00:00:00+01:00', 'fr après-demain');
    is(str(sub { $n->in_locale('fr')->parse('avant-hier') }), '2026-10-13T00:00:00+01:00', 'fr avant-hier');
    is(str(sub { $n->in_locale('fr')->parse('il y a 3 heures') }), '2026-10-15T06:00:00+01:00', 'fr il y a 3 heures');
    is(str(sub { $n->in_locale('de')->parse('vor 2 Wochen') }), '2026-10-01T09:00:00+01:00', 'de vor 2 Wochen');
    is(str(sub { $n->in_locale('de')->parse('übermorgen') }), '2026-10-17T00:00:00+01:00', 'de übermorgen');
    is(str(sub { $n->in_locale('ja')->parse('3 日後') }), '2026-10-18T09:00:00+01:00', 'ja as written');
    is(str(sub { $n->in_locale('ja')->parse('3日後') }), '2026-10-18T09:00:00+01:00', 'ja as typed');
    is(str(sub { $n->in_locale('ja')->parse('明後日') }), '2026-10-17T00:00:00+01:00', 'ja the day after tomorrow');
    is(str(sub { $n->in_locale('ru')->parse('через 21 день') }), '2026-11-05T09:00:00+00:00', 'ru 21 days');
    is(str(sub { $n->in_locale('ar')->parse('خلال يومين') }), '2026-10-17T09:00:00+01:00', 'ar the dual');
    is(str(sub { $n->in_locale('ar-EG')->parse('قبل ٣ أيام') }), '2026-10-12T09:00:00+01:00', 'ar-EG its digits');
    is(str(sub { $n->in_locale('he')->parse('בעוד יומיים') }), '2026-10-17T09:00:00+01:00', 'he two days');
    is(str(sub { $n->in_locale('zh')->parse('3天后') }), '2026-10-18T09:00:00+01:00', 'zh');
    is(str(sub { $N->parse('demain', locale => 'fr', zone => 'Europe/London') }), '2026-10-16T00:00:00+01:00', 'the class form');
}

# Other anchors.
{
    my $tokyo = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 23, minute => 30, zone => 'Asia/Tokyo');
    is(str(sub { $N->new(now => $tokyo)->parse('tomorrow') }), '2026-10-16T00:00:00+09:00', 'tomorrow in Tokyo is Tokyo\'s tomorrow');
    is(str(sub { $N->new(now => $tokyo)->parse('in 1 hour') }), '2026-10-16T00:30:00+09:00', 'an hour on');
    my $float = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'floating');
    my $t = $N->new(now => $float)->parse('tomorrow');
    is($t->zone_name, 'floating', 'a floating anchor gives a floating value');
    is($t->day, 16, 'on the next day');
    is(str(sub { $N->new(now => $anchor, zone => 'Asia/Tokyo')->parse('today') }), '2026-10-15T00:00:00+09:00', 'an anchor read in another zone: its date there');
}

# Every unit, every count, both ways, against plus.
{
    my %by_unit = (year => 'years', quarter => 'months', month => 'months', week => 'weeks', day => 'days',
                   hour => 'hours', minute => 'minutes', second => 'seconds');
    my ($asks, @bad, @faults) = (0);
    for my $loc (qw(en-GB fr de ru ar ja)) {
        my $p = $n->in_locale($loc);
        my $v = $anchor->in_locale($loc);
        for my $unit (sort keys %by_unit) {
            for my $count (-3 .. 3) {
                my $t = $v->plus($by_unit{$unit} => ($unit eq 'quarter' ? 3 * $count : $count));
                for my $style (qw(long short narrow)) {
                    $asks++;
                    my $s = $t->format_relative(to => $v, unit => $unit, style => $style, numeric => 'always');
                    my $got = eval { $p->parse($s) };
                    next if $got && $got->epoch == $t->epoch;
                    my $r = Time::Keeper::Locale->relative_names($loc, $unit, $style);
                    my $cat = Time::Keeper::Locale->plural_category($loc, abs $count);
                    if ($count < 0 && ($r->{past}{$cat} || '') eq ($r->{future}{$cat} || '-')) {
                        push @faults, "$loc $unit $style $cat";
                        next;
                    }
                    push @bad, "$loc $unit $count $style '$s': " . ($got ? "$got" : $@);
                }
            }
        }
    }
    ok(!@bad, "numeric phrases are the anchor plus the count ($asks asks)") or diag(join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)]);
    is_deeply(\@faults, ['ar month short few'], 'one CLDR 48.2.3 fault: the Arabic short past month for a few months carries the future word, and reads as the future')
        or diag(join ', ', @faults);
    ($asks, @bad) = (0);
    for my $loc (qw(en-GB fr de ru ar ja)) {
        my $p = $n->in_locale($loc);
        my $v = $anchor->in_locale($loc);
        for my $unit (sort keys %by_unit) {
            my $r = Time::Keeper::Locale->relative_names($loc, $unit);
            for my $k (sort keys %{ $r->{at} }) {
                $asks++;
                my $want = $unit eq 'second' && !$k ? $v
                         : ($unit eq 'week' ? $v->truncate(to => 'week', week_start => 'locale') : $v->truncate(to => $unit))
                           ->plus($by_unit{$unit} => ($unit eq 'quarter' ? 3 * $k : $k));
                my $got = eval { $p->parse($r->{at}{$k}) };
                push @bad, "$loc $unit $k '$r->{at}{$k}': " . ($got ? "$got" : $@) unless $got && $got->epoch == $want->epoch;
            }
        }
    }
    ok(!@bad, "period words are the period's start ($asks asks)") or diag(join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)]);
}

# Dates from points.
{
    my $d = $n->parse_date('next Tuesday');
    isa_ok($d, 'Time::Keeper::Date');
    is("$d", '2026-10-20', 'next Tuesday as a date');
    is(str(sub { $n->parse_date('in 3 hours') }), '2026-10-15', 'the date of a moment');
    is(str(sub { $N->new(now => Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 22, zone => 'Europe/London'))->parse_date('in 3 hours') }), '2026-10-16', 'which may be tomorrow');
}

# Deaths.
{
    dies_like(sub { $n->parse('in 2 weeks and 3 days ago') }, qr/^\Q$N->parse: cannot read 'in 2 weeks and 3 days ago' at '\E.*\Q': one direction a phrase\E/, 'both ways');
    dies_like(sub { $n->parse('in 3 days ago') }, qr/^\Q$N->parse: cannot read 'in 3 days ago' at 'ago': no such word in en-GB\E/, 'a marker at each end is not a chain: the second one is the stray word');
    dies_like(sub { $n->parse('2 weeks and 3 days') }, qr/^\Q$N->parse: cannot read '2 weeks and 3 days' at '\E.*\Q': a duration, not a time; parse_duration reads it\E/, 'no way at all');
    dies_like(sub { $n->parse('in 3 fortnights') }, qr/^\Q$N->parse: cannot read 'in 3 fortnights' at '\E.*\Q': no such word in en-GB\E/, 'a word it has not');
    dies_like(sub { $n->parse('tomorrow xyzzy') }, qr/cannot read 'tomorrow xyzzy' at 'xyzzy': no such word in en-GB/, 'the token after what read');
    dies_like(sub { $n->in_locale('fr')->parse('tomorrow') }, qr/no such word in fr/, 'English in French');
    is($n->try_parse('in 3 days ago'), undef, 'try_parse gives undef');
}

done_testing;
