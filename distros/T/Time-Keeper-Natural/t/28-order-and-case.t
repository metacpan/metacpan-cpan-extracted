#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use File::Temp qw(tempdir);
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;
use Time::Keeper::Natural::Words;

# Word order and case: an ordinal weekday with the period first or no "of"
# (nth), an inflected period put back to CLDR's phrase (alias), and a table
# phrase that is also a CLDR word, marked. The clock is Thursday 15 October
# 2026, 09:00 in London; the clocks go back on Sunday 25 October.
my $N = 'Time::Keeper::Natural';
my $W = 'Time::Keeper::Natural::Words';
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
sub m_ {
    my ($loc, $text) = @_;
    my $m = $N->new(locale => $loc, zone => 'Europe/London')->match($text);
    return $m ? join(' ', $m->value, $m->precision, join(',', $m->assumed)) : 'undef';
}
sub p {
    my ($loc, $text) = @_;
    my $v = eval { $N->new(locale => $loc, zone => 'Europe/London')->parse($text) };
    return $v ? "$v" : "died: $@";
}
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}

# The period first: Japanese.
is(m_('ja', '来月の第3金曜日'), '2026-11-20T00:00:00+00:00 day time,zone', 'ja: the third Friday of next month, in digits');
is(p('ja', '来月の第三金曜日'), '2026-11-20T00:00:00+00:00', 'in an ordinal word');
is(p('ja', '来月の最後の金曜日'), '2026-11-27T00:00:00+00:00', 'the last');
is(p('ja', '今月の第1木曜日'), '2026-10-01T00:00:00+01:00', 'the first Thursday of this month is its first day');
like(p('ja', '来月の第6金曜日'), qr/no month has a 6 金曜日/, 'no month has a sixth');
like(p('ja', '来週の第2金曜日'), qr/an ordinal weekday is counted in a month, not a week/, 'a week is not a month');

# No "of": Russian, the weekday in the accusative.
is(m_('ru', 'в третью пятницу октября'), '2026-10-16T00:00:00+01:00 day year,time,zone', 'ru: the third Friday of October');
is(p('ru', 'третья пятница октября'), '2026-10-16T00:00:00+01:00', 'in the nominative');
is(p('ru', 'в 3 пятницу октября'), '2026-10-16T00:00:00+01:00', 'in digits');
is(p('ru', 'в последнюю пятницу октября'), '2026-10-30T00:00:00+00:00', 'the last, after the clock change');
is(p('ru', 'в третью пятницу следующего месяца'), '2026-11-20T00:00:00+00:00', 'of next month, in the genitive');
is(p('ru', 'в последнюю субботу прошлого месяца'), '2026-09-26T00:00:00+01:00', 'the last Saturday of last month');
is(p('ru', 'в среду'), '2026-10-21T00:00:00+01:00', 'a feminine weekday in the accusative');
is(p('ru', 'во вторник'), '2026-10-20T00:00:00+01:00', 'and a masculine one, as before');

# Aliases through the edges.
is(m_('de', 'Ende nächsten Monats'), '2026-11-30T23:59:59.999999999+00:00 month zone', 'de: the end of next month');
is(p('de', 'Anfang nächsten Jahres'), '2027-01-01T00:00:00+00:00', 'the start of next year');
is(p('de', 'Ende des Monats'), '2026-10-31T23:59:59.999999999+00:00', 'the end of the month');
is(p('de', 'am Ende nächster Woche'), '2026-10-25T23:59:59.999999999+00:00', 'the end of next week');
is(p('ru', 'конец следующего месяца'), '2026-11-30T23:59:59.999999999+00:00', 'ru: the end of next month');
is(p('ru', 'в конце следующего года'), '2027-12-31T23:59:59.999999999+00:00', 'the end of next year');
is(p('ru', 'начало этой недели'), '2026-10-12T00:00:00+01:00', 'the start of this week');
is(p('el', 'τέλος του επόμενου μήνα'), '2026-11-30T23:59:59.999999999+00:00', 'el: the end of next month');
is(p('el', 'στο τέλος της επόμενης εβδομάδας'), '2026-10-25T23:59:59.999999999+00:00', 'the end of next week');
is(p('hi', 'अगले माह का अंत'), '2026-11-30T23:59:59.999999999+00:00', 'hi: the end of next month');
is(p('hi', 'अगले वर्ष की शुरुआत'), '2027-01-01T00:00:00+00:00', 'the start of next year');
is(m_('de', 'nächsten Monats'), '2026-11-01T00:00:00+00:00 month period start,zone', 'an alias alone reads as its phrase');
is(p('de', 'nächsten Monat'), '2026-11-01T00:00:00+00:00', 'the phrase as before');
like(p('de', 'übernächsten Monats'), qr/^died: /, 'an alias is a whole word');

# The marker.
is(m_('de', 'am Dienstag'), '2026-10-20T00:00:00+01:00 day weekday next,time,zone', 'de: am before a day');
is(p('de', 'am Dienstag um 9 Uhr'), '2026-10-20T09:00:00+01:00', 'with a time');
like(p('de', 'am'), qr/cannot read 'am' at 'am': no such word in de/, 'am alone is not a frame, as before');

# What a table may say.
my $dir = tempdir(CLEANUP => 1);
my $bad = "$dir/de.txt";
my $table = sub {
    open my $fh, '>:encoding(UTF-8)', $bad or die $!;
    print $fh @_;
    close $fh;
};
$table->("on\tam\n");
dies_like(sub { $W->from_file($bad, 'de') }, qr/'am' is a CLDR word in de \(period am\); a table may not take one/, 'am unmarked is refused');
$table->("skip\tder!\n");
dies_like(sub { $W->from_file($bad, 'de') }, qr/'der!' is marked, and only at, on, of, start_of and end_of may be/, 'a mark on skip');
$table->("alias\tnächsten Monats=nächster Monat\n");
dies_like(sub { $W->from_file($bad, 'de') }, qr/the alias 'nächsten Monats=nächster Monat' points at 'nächster Monat', which is not a CLDR word in de/, 'an alias whose phrase is not CLDR\'s');
$table->("alias\tletzten Monat=nächsten Monat\n");
dies_like(sub { $W->from_file($bad, 'de') }, qr/the alias 'letzten Monat=nächsten Monat' takes 'letzten Monat', a CLDR word in de \(month -1\)/, 'an alias that shadows a CLDR word');
$table->("alias\tnächsten Monats\n");
dies_like(sub { $W->from_file($bad, 'de') }, qr/the alias 'nächsten Monats' is not inflected=CLDR phrase/, 'an alias without its phrase');
$table->("nth\t{n} {weekday}\n");
dies_like(sub { $W->from_file($bad, 'de') }, qr/the nth '\{n\} \{weekday\}' needs \{period\}, \{n\} and \{weekday\}, each once/, 'an nth without its period');
$table->("nth\t{n} {weekday} {n} {period}\n");
dies_like(sub { $W->from_file($bad, 'de') }, qr/needs \{period\}, \{n\} and \{weekday\}, each once/, 'or with a slot twice');
$table->("nth\t{n} {weekday} morgen {period}\n");
dies_like(sub { $W->from_file($bad, 'de') }, qr/is a CLDR word in de \(day 1\)/, 'an nth whose words are CLDR\'s');
$table->("on\tam!\nalias\tnächsten Monats=nächsten Monat\nnth\t{period}: {n} {weekday}\n");
my $w = $W->from_file($bad, 'de');
is_deeply([$w->phrases('on')], ['am!'], 'phrases are as the file spells them');
is_deeply([$w->phrases('alias')], ['nächsten Monats=nächsten Monat'], 'an alias too');
is_deeply([$w->frame('am Dienstag', 'on')], ['Dienstag', 'am!'], 'a marked frame with a day after it');
is_deeply([$w->frame('am', 'on')], [], 'and alone, none');
is_deeply([$w->frame('nächsten Monats', 'alias')], [], 'frame does not read an alias');
is_deeply([$w->split_on('x: 3 Freitag', 'nth')], [], 'nor split_on an nth');
my $hl = $W->from_file($W->for('hi')->file, 'hi', 'hi-Latn');
is(scalar($hl->phrases('alias')), 0, 'a locale that borrows a table leaves out the aliases its CLDR lacks');
is(scalar($W->for('hi')->phrases('alias')), 6, 'its own keeps them');

# An alias inside a longer word is not one: "übermorgigen" is not
# "übermorgen". The table is de-AT's, read from a directory of its own.
{
    my $own = tempdir(CLEANUP => 1);
    mkdir "$own/Natural" or die $!;
    mkdir "$own/Natural/words" or die $!;
    open my $fh, '>:encoding(UTF-8)', "$own/Natural/words/de-AT.txt" or die $!;
    print $fh "alias\tmorgigen=morgen\n";
    close $fh;
    local $INC{'Time/Keeper/Natural.pm'} = "$own/Natural.pm";
    is(p('de-AT', 'morgigen'), '2026-10-16T00:00:00+01:00', 'an alias as a whole word');
    like(p('de-AT', 'übermorgigen'), qr/^died: /, 'not inside one');
}

done_testing;
