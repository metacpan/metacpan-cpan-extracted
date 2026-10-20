#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;

# A count with a decimal fraction, in the locale's decimal sign, converted
# down exactly; a month, a quarter or a year has no fixed length.
my $N = 'Time::Keeper::Natural';
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
sub d {
    my ($loc, $text) = @_;
    my $v = eval { $N->new(locale => $loc, zone => 'Europe/London')->parse_duration($text) };
    return $v ? "$v" : "died: $@";
}
sub p {
    my ($loc, $text) = @_;
    my $v = eval { $N->new(locale => $loc, zone => 'Europe/London')->parse($text) };
    return $v ? "$v" : "died: $@";
}

is(d('en', '1.5 hours'), 'PT1H30M', '1.5 hours');
is(d('en', '0.25 days'), 'PT6H', '0.25 days');
is(d('en', '2.5 weeks'), 'P17DT12H', '2.5 weeks: 17 days 12 hours');
is(d('en', '1.5 minutes'), 'PT1M30S', '1.5 minutes');
is(d('en', '0.5 seconds'), 'PT0.5S', '0.5 seconds');
is(d('en', '1.25 hours, 30 minutes'), 'PT1H45M', 'a fraction in a chain');
is(d('de', '1,5 Stunden'), 'PT1H30M', 'de: the comma');
is(d('fr', '2,5 jours'), 'P2DT12H', 'fr');
is(d('ar-EG', '٢٫٥ ساعة'), 'PT2H30M', 'ar-EG: its sign and digits');
is(d('ar-EG', '2.5 ساعة'), 'PT2H30M', '  and the full stop, which no Arabic number uses otherwise');
is(d('ru', '1,5 часа'), 'PT1H30M', 'ru: the plural form 1.5 takes');
is(d('ja', '1.5時間'), 'PT1H30M', 'ja, with no space');
like(d('en', '1.5 months'), qr/cannot read '1\.5 months' at '1\.5': a month has no fixed length at /, 'a month has no fixed length');
like(d('en', '2.5 years'), qr/a year has no fixed length/, 'nor a year');
like(d('en', '1.0000000001 seconds'), qr/a fraction finer than a nanosecond/, 'a fraction finer than a nanosecond');
like(d('en', '1,5 hours'), qr/cannot read '1,5 hours'/, 'en: 1,5 is not a number');

# A full stop between digits is no longer dropped: 0.01 read "1.5 hours" as
# fifteen. A group separator in groups of three is.
is(d('en', '1,500 seconds'), 'PT1500S', 'en: 1,500 is a thousand and five hundred');
is(d('de', '1.500 Sekunden'), 'PT1500S', 'de: 1.500 is too');
like(d('en', '1,50 seconds'), qr/cannot read/, 'a group of two is not a group');

# Relative counts.
is(p('en', 'in 1.5 hours'), '2026-10-15T10:30:00+01:00', 'in 1.5 hours');
is(p('en', '2.5 days ago'), '2026-10-12T21:00:00+01:00', '2.5 days ago');
is(p('de', 'in 1,5 Stunden'), '2026-10-15T10:30:00+01:00', 'de: in 1,5 Stunden');
like(p('en', 'in 1.5 months'), qr/a month has no fixed length/, 'a month dies here too');
like(p('en', 'in 1.5 quarters'), qr/a quarter has no fixed length/, 'and a quarter');
like(p('en-GB', '3.30 pm'), qr/cannot read '3\.30 pm'/, 'a time written with a full stop is not taken for a count');
{
    my $m = $N->new(locale => 'en', zone => 'Europe/London')->match_duration('1.5 hours');
    is($m->precision, 'none', 'match_duration: precision none');
    is("" . $m->value, 'PT1H30M', '  and the value');
}

# Every locale: 1.5 hours and 2.5 days written in its decimal sign and its
# unit patterns, read back.
{
    my ($asks, @bad) = (0);
    for my $loc (Time::Keeper::Locale->codes) {
        my $dec = Time::Keeper::Locale->number_symbols($loc)->{decimal};
        my $n = $N->new(locale => $loc, zone => 'Europe/London');
        for my $c (['hour', '1', '5', 'PT1H30M'], ['day', '2', '5', 'P2DT12H']) {
            my ($unit, $a, $b, $want) = @$c;
            my $pat = Time::Keeper::Locale->unit_patterns($loc, $unit, 'long')->{count}{other} // next;
            (my $t = $pat) =~ s/\{0\}/$a$dec$b/;
            $asks++;
            my $v = eval { $n->parse_duration($t) };
            push @bad, "$loc '$t': " . ($v // $@) unless $v && "$v" eq $want;
        }
    }
    cmp_ok($asks, '>=', 2000, "$asks fractions written in every locale");
    ok(!@bad, 'each reads') or diag(join "\n", scalar(@bad) . ' do not:', @bad[0 .. ($#bad < 9 ? $#bad : 9)]);
}

done_testing;
