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

# A day of the month written as an ordinal in digits: "the 15th", "October
# 15th", "15th of October", "le 1er octobre". The forms come from CLDR's
# %digits-ordinal rules, English's suffixes from its ordinal plural rules.
my $N = 'Time::Keeper::Natural';
my $NW = 'Time::Keeper::Natural::Numbers';
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
sub p {
    my ($loc, $text, @opt) = @_;
    my $v = eval { $N->new(locale => $loc, zone => 'Europe/London', @opt)->parse($text) };
    return $v ? "$v" : "died: $@";
}
sub day { sprintf '2026-%02d-%02dT00:00:00%s', $_[0], $_[1], $_[0] >= 11 || ($_[0] == 10 && $_[1] >= 25) ? '+00:00' : '+01:00' }

# English's suffixes, by CLDR's ordinal rules.
{
    my $en = $NW->for('en');
    my %want = (1 => '1st', 2 => '2nd', 3 => '3rd', 4 => '4th', 11 => '11th', 12 => '12th', 13 => '13th',
                21 => '21st', 22 => '22nd', 23 => '23rd', 24 => '24th', 31 => '31st');
    is($en->day($want{$_}), $_, "$want{$_} is $_") for sort { $a <=> $b } keys %want;
    is($en->day('11st'), undef, '11st is not a form');
    is($en->day('22th'), undef, 'nor 22th');
    is(scalar(my @d = $en->days), 62, 'one form a day');
    is($NW->for('fr')->day('1er'), 1, 'fr 1er');
    is($NW->for('fr')->day('1re'), 1, 'fr 1re');
    is($NW->for('fr')->day('2e'), 2, 'fr 2e');
    is($NW->for('es')->day('1.º'), 1, 'es 1.º');
    is($NW->for('it')->day('1º'), 1, 'it 1º');
    is($NW->for('sv')->day('2:a'), 2, 'sv 2:a');
    is($NW->for('es-419')->read('veintiuno'), 21, 'es-419 has its own day forms and still reads Spanish words');
    is(scalar(my @de = $NW->for('de')->days), 0, 'de has no day ordinals: its dates write "15." in the pattern');
}

# Read.
is(p('en', 'the 15th'), day(10, 15), 'the 15th: the anchor\'s month');
is(p('en', '3rd'), day(10, 3), 'no article');
is(p('en', 'the 3rd', prefer => 'future'), day(11, 3), 'prefer future: the next 3rd');
is(p('en', 'the 20th', prefer => 'past'), day(9, 20), 'prefer past: the last 20th');
is(p('en', 'the 20th', prefer => 'future'), day(10, 20), 'prefer future: this month\'s, still to come');
is(p('en', 'October 15th'), day(10, 15), 'October 15th');
is(p('en', 'October 15th, 2026'), day(10, 15), 'October 15th, 2026');
is(p('en', 'November 1st, 2026'), day(11, 1), 'November 1st, 2026');
is(p('en', 'the 15th of October'), day(10, 15), 'the 15th of October');
is(p('en', '15th October'), day(10, 15), '15th October, in en too');
is(p('en-GB', '15th October 2026'), day(10, 15), 'en-GB 15th October 2026');
is(p('en', 'the 1st of next month'), day(11, 1), 'the 1st of next month');
is(p('en', 'the 2nd at 3 pm'), '2026-10-02T15:00:00+01:00', 'the 2nd at 3 pm');
is(p('fr', 'le 1er octobre'), day(10, 1), 'fr le 1er octobre');
is(p('fr', '1er novembre 2026'), day(11, 1), 'fr 1er novembre 2026');
is(p('es', '1.º de octubre'), day(10, 1), 'es 1.º de octubre');
is(p('it', '1º ottobre'), day(10, 1), 'it 1º ottobre');
is(p('nl', '15e oktober'), day(10, 15), 'nl 15e oktober');
is(p('sv', '2:a oktober'), day(10, 2), 'sv 2:a oktober');
is(p('th', 'ที่ 1'), day(10, 1), 'th ที่ 1, a form with a space');

# What it does not do.
like(p('en', 'the 31st of November'), qr/cannot read 'the 31st of November' at '31st': 2026-11 has no day 31 at /, 'a day the month lacks');
like(p('en', 'the 22th'), qr/no such word in en/, 'a suffix the rules do not write');
like(p('en', 'Tuesday the 20th'), qr/no such word in en/, 'a weekday before it is not read');
is(p('en', 'the 15'), '2026-10-15T15:00:00+01:00', 'a bare number stays what 0.01 read: an hour');
is(p('vi', 'thứ 2'), '2026-10-19T00:00:00+01:00', 'vi thứ 2 is Monday before it is the 2nd: the plain reading comes first');

# The Match, and an interval.
{
    my $m = $N->new(locale => 'en', zone => 'Europe/London')->match('the 15th');
    is($m->precision, 'day', 'precision day');
    is_deeply([$m->assumed], [qw(month time zone)], 'the month assumed');
    is_deeply([$N->new(locale => 'en', zone => 'Europe/London')->match('October 15th')->assumed], [qw(time year zone)], 'not where a month is named');
    is(join(' / ', $N->new(locale => 'en', zone => 'Europe/London')->parse_interval('October 15th - 17th')),
       day(10, 15) . ' / 2026-10-17T23:59:59.999999999+01:00', 'an interval of ordinals');
}

# Every form for 1 to 31, in every locale that has them, alone and in the
# locale's own day and month: a known few are left out by name.
{
    my %bare_known = map { ("vi thứ $_" => 1) } 2 .. 7;
    my %date_known = map { $_ => 1 } qw(ja ko ky yue yue-Hans zh zh-Hant);
    my ($asks, @bad) = (0);
    for my $loc ($NW->locales) {
        my %d = $NW->for($loc)->days or next;
        my $n = $N->new(locale => $loc, zone => 'Europe/London');
        my $md = eval { Time::Keeper->new(year => 2026, month => 10, day => 28, zone => 'Europe/London')->in_locale($loc)->format_skeleton('MMMMd') } // '';
        for my $form (sort keys %d) {
            my $want = sprintf '2026-10-%02d', $d{$form};
            my @t;
            push @t, $form unless $bare_known{"$loc $form"};
            my $date = $md;
            push @t, $date if !$date_known{$loc} && $date =~ s/(?<!\d)28(?!\d)/$form/;
            for my $t (@t) {
                $asks++;
                my $v = eval { $n->parse($t) };
                push @bad, "$loc '$t': " . ($v // $@) unless $v && substr("$v", 0, 10) eq $want;
            }
        }
    }
    cmp_ok($asks, '>=', 3900, "$asks forms read");
    ok(!@bad, 'each reads as its day') or diag(join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)]);
}

done_testing;
