#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;

# A calendar: its dates read as Time::Keeper writes them, the anchor taken
# in it so relative phrases count its months, and every value in it. The
# clock is Thursday 15 October 2026, 09:00 in London: 4 Heshvan 5787, a
# Hebrew leap year; 令和8年; Mehr 23, 1405 AP; 4 Jumada I 1448 AH.
my $N = 'Time::Keeper::Natural';
my $TK09 = Time::Keeper->VERSION >= 0.09;
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
sub p {
    my ($loc, $cal, $text) = @_;
    my $v = eval { $N->new(locale => $loc, zone => 'Europe/London', ($cal ? (calendar => $cal) : ()))->parse($text) };
    return $v ? $v->iso8601 . ' ' . $v->calendar : "died: $@";
}
my $DAY = '2026-10-15T00:00:00+01:00';

# The option.
{
    ok(!eval { $N->new(calendar => 'lunar'); 1 }, 'a calendar that is not one dies');
    like($@, qr/^\Q$N\E->new: 'lunar' is not a calendar: gregory, buddhist/, '  naming the calendars');
    is($N->new(calendar => 'hebrew')->calendar, 'hebrew', 'calendar');
    is($N->new->calendar, undef, '  undef unset');
    is($N->new(locale => 'ja-u-ca-japanese')->calendar, 'japanese', 'a -u-ca- extension gives it');
    is($N->new(locale => 'ar-u-ca-islamic-umalqura-nu-latn')->calendar, 'islamic-umalqura', '  an id with a hyphen, before another key');
    is($N->new(locale => 'ja-u-ca-japanese', calendar => 'gregory')->calendar, 'gregory', '  and calendar wins over it');
    is(p('en', 'gregory', 'October 15, 2026'), "$DAY gregory", 'the Gregorian is the plain parser');
}

# Dates in their calendars.
is(p('en', 'hebrew', '4 Heshvan 5787'), "$DAY hebrew", 'Hebrew in English');
is(p('en', 'hebrew', '15 Adar I 5787'), '2027-02-22T00:00:00+00:00 hebrew', 'Adar I in a leap year');
is(p('en', 'hebrew', '15 Adar II 5787'), '2027-03-24T00:00:00+00:00 hebrew', 'Adar II, a month later');
is(p('ja', 'japanese', '令和8年10月15日'), "$DAY japanese", 'the Japanese era in Japanese');
is(p('en', 'japanese', 'Oct 15, 8 Reiwa'), "$DAY japanese", '  and in English');
is(p('fa', 'persian', '۲۳ مهر ۱۴۰۵'), "$DAY persian", 'Persian in Persian digits');
is(p('ar', 'islamic-umalqura', '4 جمادى الأولى 1448 هـ'), "$DAY islamic-umalqura", 'Umm al-Qura in Arabic');
is(p('en', 'chinese', 'Mo9 6, 2026'), "$DAY chinese", 'the Chinese calendar by its related year');
is(p('pt', 'chinese', '25 de Mês 1 de ding-wei'), '2027-03-03T00:00:00+00:00 chinese', '  by the name of the year: the nearest ding-wei');
is(p('de', 'chinese', '06.09.43'), "$DAY chinese", '  by its place in the cycle, 43: the nearest');
is(p('th', 'buddhist', '15/10/69'), "$DAY buddhist", 'a two-digit Buddhist year in the anchor\'s century, 2569');
is(p('en', 'coptic', 'Baba 5, 1743 AM'), "$DAY coptic", 'Coptic');
SKIP: {
    skip 'Time::Keeper 0.09 reads the numerals some calendars are written in', 3 unless $TK09;
    is(p('he', 'hebrew', 'ד׳ בחשוון תשפ״ז'), "$DAY hebrew", 'Hebrew numerals in Hebrew');
    is(p('zh', 'chinese', '2026丙午年九月初六'), "$DAY chinese", 'the lunar day 初六 in Chinese');
    is(p('ja', 'chinese', '丙午年九月六日'), "$DAY chinese", 'Chinese numerals in Japanese');
}
is(p('es-PA', 'hebrew', '02/04/5787 AM'), "$DAY hebrew", 'es-PA\'s own medium date, MM/dd/y G, before a skeleton that is d/M/y');
is(p('tr', 'chinese', '2026-09-06'), "$DAY chinese", 'a date with no time is the calendar\'s, not ISO 8601\'s');
is(p('en-GB', 'hebrew', '15 October 2026'), "$DAY hebrew", 'a Gregorian date still reads, given back in the calendar');
like(p('en', 'hebrew', '4 Zzz 5787'), qr/^died: \Q$N\E->parse: cannot read '4 Zzz 5787'/, 'a month the calendar has not');

# Relative phrases count the calendar.
is(p('en', 'hebrew', 'next month'), '2026-11-11T00:00:00+00:00 hebrew', 'next month: 1 Kislev');
is(p('en', 'hebrew', 'end of next month'), '2026-12-10T23:59:59.999999999+00:00 hebrew', 'end of next month: 30 Kislev');
is(p('en', 'hebrew', 'in 2 months'), '2026-12-14T09:00:00+00:00 hebrew', 'in 2 months: 4 Tevet');
is(p('en', 'islamic-umalqura', 'next year'), '2027-06-06T00:00:00+01:00 islamic-umalqura', 'next year: 1 Muharram 1449');
is(p('en', 'hebrew', 'tomorrow'), '2026-10-16T00:00:00+01:00 hebrew', 'a day is a day');

# The Match.
{
    my $m = $N->new(locale => 'en', calendar => 'hebrew', zone => 'Europe/London')->match('4 Heshvan');
    is($m->value->calendar, 'hebrew', 'the Match\'s value is in the calendar');
    is($m->value->iso8601, $DAY, '  a date with no year takes the anchor\'s Hebrew year');
    is_deeply([$m->assumed], [qw(time year zone)], '  and says so');
}

# Every calendar's four date formats and its medium date and time, in ten
# locales, read back.
{
    my @bad;
    my $asks = 0;
    for my $cal (Time::Keeper::Calendar->ids) {
        for my $loc (qw(en fr de ja zh ar fa he ru th)) {
            my $n = $N->new(locale => $loc, zone => 'Europe/London', calendar => $cal);
            my $m = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 15, minute => 5, zone => 'Europe/London')->in_calendar($cal)->in_locale($loc);
            for my $w (qw(full long medium short)) {
                my $t = $m->format_date($w);
                next if !$TK09 && $t =~ /[\x{5D0}-\x{5EA}]{2}|[〇一二三四五六七八九十初廿]/;
                $asks++;
                my $v = eval { $n->parse($t) };
                push @bad, "$cal $loc '$t': " . ($v // $@) unless $v && $v->epoch == $m->truncate(to => 'day')->epoch && $v->calendar eq $cal;
            }
            my $t = $m->format_datetime('medium');
            next if !$TK09 && $t =~ /[\x{5D0}-\x{5EA}]{2}|[〇一二三四五六七八九十初廿]/;
            $asks++;
            my $v = eval { $n->parse($t) };
            push @bad, "$cal $loc '$t': " . ($v // $@) unless $v && $v->epoch == $m->truncate(to => 'second')->epoch;
        }
    }
    cmp_ok($asks, '>=', $TK09 ? 840 : 740, "$asks dates and times in 17 calendars");
    ok(!@bad, 'each reads back, in its calendar') or diag(join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)]);
}

done_testing;
