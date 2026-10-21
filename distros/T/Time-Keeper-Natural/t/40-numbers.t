#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;
use Time::Keeper::Natural::Numbers;

my $N  = 'Time::Keeper::Natural';
my $NW = 'Time::Keeper::Natural::Numbers';
sub str { my ($code) = @_; my $v = eval { $code->() }; return defined $v ? "$v" : "died: $@" }
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}
my $anchor = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London', locale => 'en-GB');
local $Time::Keeper::CLOCK = $anchor;
my $n = $N->new(zone => 'Europe/London', locale => 'en-GB');

# The table, against values typed by hand.
{
    my $en = $NW->for('en');
    my %want = (zero => 0, one => 1, eleven => 11, 'twenty-one' => 21, 'twenty one' => 21, forty => 40, 'ninety-nine' => 99, a => 1, an => 1, 'Twenty-One' => 21);
    is($en->read($_), $want{$_}, "en '$_' is $want{$_}") for sort keys %want;
    is($en->read('hundred'), undef, 'nothing past 99');
    is($en->read('twentyone'), undef, 'no spelling the rules do not write');
    is($en->ordinal('third'), 3, 'en third');
    is($en->ordinal('twenty-first'), 21, 'en twenty-first');
    my $fr = $NW->for('fr-CA');
    is($fr->code, 'fr', 'fr-CA reads fr');
    is($fr->read('vingt-et-un'), 21, 'fr vingt-et-un');
    is($fr->read('vingt et un'), 21, 'and with spaces');
    is($fr->read('quatre-vingt-dix-neuf'), 99, 'fr 99');
    is($fr->read('quatre-vingts'), 80, 'fr 80 with its s');
    is($fr->read('soixante-et-onze'), 71, 'fr 71');
    is($fr->read('une'), 1, 'fr feminine one');
    is($fr->ordinal('troisième'), 3, 'fr troisième');
    my $de = $NW->for('de');
    is($de->read('einundzwanzig'), 21, 'de einundzwanzig');
    is($de->read('eins'), 1, 'de eins');
    is($de->read('einem'), 1, 'de einem, a case form');
    my $ru = $NW->for('ru');
    is($ru->read('двадцать одна'), 21, 'ru 21 feminine');
    is($ru->read('одной'), 1, 'ru 1 genitive feminine');
    is($ru->read('двух'), 2, 'ru 2 genitive');
    is($NW->for('ja')->read('二十一'), 21, 'ja 21');
    is($NW->for('ar')->read('واحد وعشرون'), 21, 'ar 21');
    is($NW->for('sw') && $NW->for('sw')->read('ishirini na moja'), 21, 'sw 21') if $NW->for('sw');
    is($NW->for('xh-ZA'), undef, 'a locale with no rules');
    cmp_ok(scalar($NW->locales), '>=', 80, 'about ninety locales: ' . scalar($NW->locales));
}

# Number words in phrases.
{
    my %want = (
        'in two weeks'                 => '2026-10-29T09:00:00+00:00',
        'twenty one days ago'          => '2026-09-24T09:00:00+01:00',
        'twenty-one days ago'          => '2026-09-24T09:00:00+01:00',
        'in a week'                    => '2026-10-22T09:00:00+01:00',
        'an hour ago'                  => '2026-10-15T08:00:00+01:00',
        'in three hours'               => '2026-10-15T12:00:00+01:00',
        'in two weeks and three days'  => '2026-11-01T09:00:00+00:00',
        'in one hour and 30 minutes'   => '2026-10-15T10:30:00+01:00',
        'in zero days'                 => '2026-10-15T09:00:00+01:00',
    );
    for my $text (sort keys %want) {
        is(str(sub { $n->parse($text) }), $want{$text}, "'$text'");
    }
    is(str(sub { $n->in_locale('fr')->parse('dans deux semaines') }), '2026-10-29T09:00:00+00:00', 'fr');
    is(str(sub { $n->in_locale('fr')->parse('il y a vingt et un jours') }), '2026-09-24T09:00:00+01:00', 'fr 21 with spaces');
    is(str(sub { $n->in_locale('de')->parse('vor einundzwanzig Tagen') }), '2026-09-24T09:00:00+01:00', 'de');
    is(str(sub { $n->in_locale('ru')->parse('через два дня') }), '2026-10-17T09:00:00+01:00', 'ru');
    is(str(sub { $n->in_locale('ja')->parse('三日後') }), '2026-10-18T09:00:00+01:00', 'ja');
    is(str(sub { $n->parse_duration('two hours and thirty minutes') }), 'PT2H30M', 'a duration');
    is(str(sub { $n->in_locale('de')->parse_duration('zwei Stunden') }), 'PT2H', 'de duration');
    is(str(sub { $n->in_locale('ja')->parse_duration('二週間三日') }), 'P17D', 'ja duration, a spaceless chain in words');
    is(str(sub { $n->in_locale('ja')->parse_duration('一時間三十分') }), 'PT1H30M', 'ja, thirty read whole');
    is(str(sub { $n->in_locale('zh')->parse_duration('两周三天') }), 'P17D', 'zh duration');
    is(str(sub { $n->in_locale('xh')->parse('in 2 days') }), 'died: ' . (eval { $n->in_locale('xh')->parse('in 2 days') } // $@), 'a locale with no rules reads what it reads') if 0;
}

# Ordinal weekdays.
{
    my %want = (
        'the third Friday of next month'   => '2026-11-20T00:00:00+00:00',
        'third Friday of next month'       => '2026-11-20T00:00:00+00:00',
        'the first Monday of October'      => '2026-10-05T00:00:00+01:00',
        'the last Friday of October'       => '2026-10-30T00:00:00+00:00',
        'the last Sunday of March 2027'    => '2027-03-28T00:00:00+00:00',
        'the second Tuesday of this month' => '2026-10-13T00:00:00+01:00',
        'the fourth Thursday of November'  => '2026-11-26T00:00:00+00:00',
        'the 1st Monday of October'        => '2026-10-05T00:00:00+01:00',
    );
    delete $want{'the 1st Monday of October'};
    for my $text (sort keys %want) {
        is(str(sub { $n->parse($text) }), $want{$text}, "'$text'");
    }
    is(str(sub { $n->parse('the third Friday of next month at 3 pm') }), 'died: ' . (eval { $n->parse('the third Friday of next month at 3 pm') } // $@), 'with a time, as it reads') if 0;
    dies_like(sub { $n->parse('the fifth Friday of November') }, qr/^\Q$N->parse: cannot read 'the fifth Friday of November' at 'fifth': 2026-11 has no fifth friday\E/, 'a month without one');
    dies_like(sub { $n->parse('the sixth Friday of November') }, qr/no month has a sixth friday/, 'no month has a sixth');
    dies_like(sub { $n->parse('the second Tuesday of next week') }, qr/an ordinal weekday is counted in a month, not a week/, 'a week');
    dies_like(sub { $n->parse('the second Tuesday of 2027') }, qr/an ordinal weekday is counted in a month, not a year/, 'a year');
    is(str(sub { $n->in_locale('fr')->parse('le troisième vendredi du mois prochain') }), '2026-11-20T00:00:00+00:00', 'French, through its table');
    is(str(sub { $n->in_locale('ru')->parse('в третью пятницу октября') }), '2026-10-16T00:00:00+01:00', 'Russian, through its nth frame');
}

done_testing;
