#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use utf8;
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# Known answers for the thirteen arithmetic calendars, read off ICU through
# Node's Intl.DateTimeFormat and kept in plan_time_keeper_2/sources/
# calendar-samples.tsv (a copy travels with the dist in t/). Every row is
# built both ways: the Gregorian day read in the calendar, and the calendar
# date made with new and read back as the Gregorian day.
use Time::Keeper;

my $file = 't/calendar-samples.tsv';
open my $h, '<:encoding(UTF-8)', $file or plan skip_all => "no $file";
my %slot = (Tishri => 1, Heshvan => 2, Kislev => 3, Tevet => 4, Shevat => 5, 'Adar I' => 6, Adar => 7, 'Adar II' => 7, Nisan => 8, Iyar => 9, Sivan => 10, Tamuz => 11, Av => 12, Elul => 13);
my %era_index = (AD => 1, BC => 0, AH => 0, Minguo => 1, 'B.R.O.C.' => 0, AA => 0, BE => 0, AP => 0, 'Śaka' => 0, AM => 1, '' => 0);
my ($rows, $bad, %seen) = (0, 0);
while (<$h>) {
    next if /^#/;
    chomp;
    my ($iso, $cal, $era, $year, $month, $day) = split /\t/;
    next if $cal =~ /^(buddhist|japanese|roc)$/ && $iso lt '1582-10-15';
    my $t = Time::Keeper->parse("${iso}T00:00:00Z", calendar => $cal);
    my $slot = $cal eq 'hebrew' ? $slot{$month} : $month;
    my $got_slot = $t->month;
    $got_slot = $t->is_leap_year ? $got_slot : ($got_slot <= 5 ? $got_slot : $got_slot + 1) if $cal eq 'hebrew';
    my @problems;
    push @problems, "day $got_slot vs $slot" if $got_slot != $slot;
    push @problems, 'day' if $t->day != $day;
    push @problems, 'era_year' if $t->era_year != $year;
    if ($cal eq 'japanese') {
        my ($name) = $era =~ /^(\w+)/;
        push @problems, "era $era" if $name =~ /^(Reiwa|Heisei|Showa|Taisho|Meiji)$/i && lc($t->era) ne lc($name);
    }
    elsif ($cal eq 'gregory') { push @problems, "era $era" if $t->era ne ($era eq 'AD' ? 'ce' : 'bce') }
    elsif ($cal eq 'roc') { push @problems, "era $era" if $t->era ne ($era eq 'Minguo' ? 'roc' : 'broc') }
    elsif ($cal eq 'ethiopic') { push @problems, "era $era" if $t->era ne ($era eq 'AM' ? 'am' : 'aa') }
    elsif ($cal eq 'coptic') { push @problems, "era $era" if $t->era ne ($era eq 'AM' ? 'am' : 'before-am') }
    my $made = Time::Keeper->new(year => $t->year, month => $t->month, day => $t->day, calendar => $cal);
    push @problems, 'round trip' if $made->iso8601 ne "${iso}T00:00:00Z";
    $rows++;
    $seen{$cal}++;
    if (@problems) {
        $bad++;
        diag("$iso in $cal: @problems (ours " . join('-', $t->era, $t->era_year, $t->month, $t->day) . ", ICU $era $year $month $day)") if $bad <= 20;
    }
}
is($bad, 0, "$rows ICU answers across " . scalar(keys %seen) . " calendars agree, and each date rebuilds its day");

# A few anchors by hand, from the literature.
my $K = 'Time::Keeper';
is($K->parse('0622-07-19T00:00:00Z', calendar => 'islamic-civil')->iso8601 =~ s/T.*//r, '0622-07-19', 'the civil Hijri epoch');
is($K->new(year => 1, month => 1, day => 1, calendar => 'islamic-civil')->iso8601, '0622-07-19T00:00:00Z', '1 Muharram 1 AH is 19 July 622');
is($K->new(year => 1, month => 1, day => 1, calendar => 'islamic-tbla')->iso8601, '0622-07-18T00:00:00Z', 'a day earlier in the astronomical reckoning');
is($K->new(year => 1, month => 1, day => 1, calendar => 'hebrew')->iso8601, '-003760-09-07T00:00:00Z', '1 Tishri AM 1');
is($K->new(year => 5787, month => 1, day => 1, calendar => 'hebrew')->iso8601, '2026-09-12T00:00:00Z', 'Rosh Hashanah 5787 is 12 September 2026');
is($K->new(year => 5785, month => 1, day => 1, calendar => 'hebrew')->iso8601, '2024-10-03T00:00:00Z', 'and 5785 was 3 October 2024');
is($K->new(year => 1, month => 1, day => 1, calendar => 'coptic')->iso8601, '0284-08-29T00:00:00Z', 'the Coptic epoch');
is($K->new(year => 1, month => 1, day => 1, calendar => 'ethiopic')->iso8601, '0008-08-27T00:00:00Z', 'the Ethiopic epoch');
is($K->new(year => 1, month => 1, day => 1, calendar => 'persian')->iso8601, '0622-03-21T00:00:00Z', 'the Persian epoch as ICU places it');
is($K->new(year => 1403, month => 1, day => 1, calendar => 'persian')->iso8601, '2024-03-20T00:00:00Z', 'Nowruz 1403');
is($K->new(year => 1, month => 1, day => 1, calendar => 'indian')->iso8601, '0079-03-22T00:00:00Z', 'the Saka epoch');
is($K->new(year => 1946, month => 1, day => 1, calendar => 'indian')->iso8601, '2024-03-21T00:00:00Z', 'Saka 1946 began on 21 March 2024, a Gregorian leap year');
is($K->new(year => 2569, month => 10, day => 15, calendar => 'buddhist')->iso8601, '2026-10-15T00:00:00Z', 'BE 2569');
is($K->new(year => 115, month => 10, day => 15, calendar => 'roc')->iso8601, '2026-10-15T00:00:00Z', 'Minguo 115');
is($K->parse('2019-05-01T00:00:00Z', calendar => 'japanese')->era, 'reiwa', 'Reiwa began on 1 May 2019');
is($K->parse('2019-04-30T00:00:00Z', calendar => 'japanese')->era, 'heisei', 'Heisei ended the day before');
is($K->parse('2019-04-30T00:00:00Z', calendar => 'japanese')->era_year, 31, 'in its 31st year');
is($K->parse('1868-10-23T00:00:00Z', calendar => 'japanese')->era, 'meiji', 'Meiji from 23 October 1868, as CLDR has it');
is($K->parse('0100-01-01T00:00:00Z', calendar => 'japanese')->era_year, -544, 'before Taika the first era counts down (ICU says -545, reading the Julian 30 December 99)');
is($K->new(year => 1448, month => 5, day => 4, calendar => 'islamic-umalqura')->iso8601, '2026-10-15T00:00:00Z', 'Umm al-Qura from the table');
is($K->new(year => 1200, month => 1, day => 1, calendar => 'islamic-umalqura')->iso8601, $K->new(year => 1200, month => 1, day => 1, calendar => 'islamic-civil')->iso8601, 'and civil before the table');
is($K->new(year => 2060, month => 1, day => 1, calendar => 'persian')->iso8601, '2681-03-20T00:00:00Z', 'ICU moves the leap year of 2059 AP to 2060');
is($K->new(year => 7519, month => 2, day => 5, calendar => 'ethioaa')->iso8601, '2026-10-15T00:00:00Z', 'Amete Alem 7519');
is($K->new(year => 2019, month => 2, day => 5, calendar => 'ethiopic')->iso8601, '2026-10-15T00:00:00Z', 'Amete Mihret 2019');
is($K->new(year => 0, month => 1, day => 1, calendar => 'ethiopic')->era, 'aa', 'the Ethiopic year 0 is in Amete Alem');
is($K->new(year => 0, month => 1, day => 1, calendar => 'ethiopic')->era_year, 5500, 'as 5500');
is($K->new(year => 0, month => 1, day => 1, calendar => 'coptic')->era, 'before-am', 'the Coptic year 0 is before the Martyrs');
is($K->new(year => 0, month => 1, day => 1, calendar => 'coptic')->era_year, 1, 'as 1');
is($K->new(year => -538, month => 8, day => 2, calendar => 'islamic-civil')->era_year, -538, 'a Hijri year before the Hijra stays negative, as ICU reads it');

done_testing;
