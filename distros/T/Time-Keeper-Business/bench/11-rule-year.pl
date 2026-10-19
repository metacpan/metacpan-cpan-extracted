#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Business;
my $uk = Time::Keeper::Business::Rule->uk;
my $year = 2026;
$uk->holidays(year => $year);
my $mine = rate(sub { $uk->holidays(year => $year++) }, 'Rule->uk, a new year');
printf "info a fresh Rule->uk and its first year: %s\n", fmt_rate(rate(sub { Time::Keeper::Business::Rule->uk->holidays(year => 2026) }, 'fresh rule'));
mark_rate('Rule->uk->holidays(year => $y), a new year each', $mine, 2e4);
printf "info the memoised year: %s\n", fmt_rate(rate(sub { $uk->holidays(year => 2026) }, 'memoised'));
if (eval { require Date::Holidays; require Date::Holidays::GB; 1 }) {
    my $dh = Date::Holidays->new(countrycode => 'gb');
    mark('a year of holidays', $mine, rate(sub { $dh->holidays(year => $year) }, 'Date::Holidays::GB'), 1, 'Date::Holidays::GB');
}
else { absent('Date::Holidays::GB', 'holidays(year)') }
done();
