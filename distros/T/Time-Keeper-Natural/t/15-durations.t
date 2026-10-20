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
my $D = 'Time::Keeper::Duration';
sub str { my ($code) = @_; my $v = eval { $code->() }; return defined $v ? "$v" : "died: $@" }
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
my $n = $N->new(locale => 'en');

# The surface.
{
    my %want = (
        '1 hour, 30 minutes'            => 'PT1H30M',
        '1 hr 30 min'                   => 'PT1H30M',
        '1h 30m'                        => 'PT1H30M',
        '1:05:09'                       => 'PT1H5M9S',
        '1:30'                          => 'PT1H30M',
        '0:06:00'                       => 'PT6M',
        '12:00:00'                      => 'PT12H',
        '0:00:07.5'                     => 'PT7.5S',
        '2 weeks'                       => 'P14D',
        '1 year, 2 months and 3 days'   => 'P1Y2M3D',
        '1 year, 2 months, and 3 days'  => 'P1Y2M3D',
        '30 minutes and 1 hour'         => 'PT1H30M',
        'PT90M'                         => 'PT1H30M',
        'pt90m'                         => 'PT1H30M',
        'P1Y2M3DT4H5M6S'                => 'P1Y2M3DT4H5M6S',
        '500 milliseconds'              => 'PT0.5S',
        '2 days and 500 milliseconds'   => 'P2DT0.5S',
        '3 microseconds'                => 'PT0.000003S',
        '7 nanoseconds'                 => 'PT0.000000007S',
        '30m'                           => 'PT30M',
        '2y 3m'                         => 'P2Y3M',
        '2m 3d'                         => 'P2M3D',
        '2m 5s'                         => 'PT2M5S',
        '1y 2m 3d 4h 5m 6s'             => 'P1Y2M3DT4H5M6S',
        '1 yr, 2 mths, 3 days, 4 hr, 5 min, 6 sec' => 'P1Y2M3DT4H5M6S',
    );
    for my $text (sort keys %want) {
        is(str(sub { $n->parse_duration($text) }), $want{$text}, "'$text'");
    }
    isa_ok($n->parse_duration('2 weeks'), $D);
    is(str(sub { $N->parse_duration('2 semaines', locale => 'fr') }), 'P14D', 'the class form (a duration prints its days)');
}

# Other locales.
{
    is(str(sub { $n->in_locale('de')->parse_duration('1 Std., 30 Min.') }), 'PT1H30M', 'de short');
    is(str(sub { $n->in_locale('de')->parse_duration('1 J, 2 M, 3 T, 4h, 5 Min. und 6 Sek.') }), 'P1Y2M3DT4H5M6S', 'de narrow, with its und');
    is(str(sub { $n->in_locale('ar')->parse_duration('ساعتان و30 دقيقة') }), 'PT2H30M', 'ar, the dual and the joined waw');
    is(str(sub { $n->in_locale('ja')->parse_duration('2 時間 30 分') }), 'PT2H30M', 'ja as written');
    is(str(sub { $n->in_locale('ja')->parse_duration('2時間30分') }), 'PT2H30M', 'ja as typed');
    is(str(sub { $n->in_locale('fi')->parse_duration('1.05.09') }), 'PT1H5M9S', 'fi writes the clock with full stops');
    is(str(sub { $n->in_locale('ar-EG')->parse_duration('١:٠٥:٠٩') }), 'PT1H5M9S', 'ar-EG in its digits');
    is(str(sub { $n->in_locale('ru')->parse_duration('2 недели и 3 дня') }), 'P17D', 'ru');
    is(str(sub { $n->in_locale('pl')->parse_duration('5 godzin') }), 'PT5H', 'pl many');
}

# Every unit at 1, 2, 5 and 21 in every width, in five locales, against Duration->format.
{
    my ($asks, @bad, @ambiguous) = (0);
    for my $loc (qw(en de pl ar ja)) {
        my $p = $n->in_locale($loc);
        for my $unit (qw(year month week day hour minute second)) {
            for my $c (1, 2, 5, 21) {
                my $d = $D->new($unit . 's' => $c);
                for my $style (qw(long short narrow)) {
                    $asks++;
                    my $s = $d->format(locale => $loc, style => $style);
                    my $got = eval { $p->parse_duration($s) };
                    next if $got && "$got" eq "$d";
                    if ($got && grep { my $x = $_; Time::Keeper::Natural::Lexicon->for($loc)->key($got->format(locale => $loc, style => $x)) eq Time::Keeper::Natural::Lexicon->for($loc)->key($s) } qw(long short narrow)) { push @ambiguous, "$loc $style '$s'"; next }
                    push @bad, "$loc $unit $c $style '$s': " . ($got ? "$got" : $@);
                }
            }
        }
    }
    ok(!@bad, "every unit, count and width reads back ($asks asks)") or diag(join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)]);
    ok(@ambiguous <= 8, scalar(@ambiguous) . ' strings CLDR writes the same for two units (English\'s narrow m)') or diag(join "\n", @ambiguous);
    note($_) for @ambiguous;
}

# Lists of one, two and three parts in each width.
{
    for my $loc (qw(en de ar)) {
        for my $d (map { $D->parse($_) } qw(PT5H PT1H30M PT1H5M9S P1Y2M3D)) {
            for my $style (qw(long short narrow)) {
                my $s = $d->format(locale => $loc, style => $style);
                is(str(sub { $n->in_locale($loc)->parse_duration($s) }), "$d", "$loc $style '$s'");
            }
        }
    }
}

# Deaths.
{
    dies_like(sub { $n->parse_duration('1 hour and 2 hours') }, qr/^\Q$N->parse_duration: cannot read '1 hour and 2 hours' at '2 hours': hour is given twice\E/, 'a unit twice');
    dies_like(sub { $n->parse_duration('tomorrow') }, qr/^\Q$N->parse_duration: cannot read 'tomorrow' at 'tomorrow': a time, not a duration\E/, 'a time');
    dies_like(sub { $n->parse_duration('in 3 days') }, qr/a time, not a duration/, 'a counted time');
    dies_like(sub { $n->parse('2 weeks') }, qr/^\Q$N->parse: cannot read '2 weeks' at '2': a duration, not a time; parse_duration reads it\E/, 'parse of a duration');
    is(str(sub { $n->parse('1:05:09') }), '2026-10-15T01:05:09Z', 'parse of a clock string is a time of day; parse_duration of it is a duration');
    dies_like(sub { $n->parse('PT1H') }, qr/a duration, not a time; parse_duration reads it/, 'parse of ISO');
    dies_like(sub { $n->parse_duration('-1 hour') }, qr/^\Q$N->parse_duration: cannot read '-1 hour' at '-': a sign; a duration is unsigned\E/, 'a sign');
    dies_like(sub { $n->parse_duration('1 fortnight') }, qr/no such word in en/, 'a unit it has not');
    dies_like(sub { $n->parse_duration('') }, qr/the text is empty/, 'nothing');
    is(str(sub { $n->parse_duration('1:5:9') }), 'PT1H5M9S', 'a clock with one-digit minutes and seconds reads too');
    dies_like(sub { $n->parse_duration('1:5:9:3') }, qr/no such word in en/, 'four parts are not a clock');
    is($n->try_parse_duration('tomorrow'), undef, 'try_parse_duration gives undef');
    is($n->try_parse_duration('2 weeks'), 'P14D', 'and the duration otherwise');
}

done_testing;
