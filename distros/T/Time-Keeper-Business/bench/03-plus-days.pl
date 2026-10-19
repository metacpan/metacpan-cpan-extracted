#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Business;
my $b = Time::Keeper::Business->new(holidays => Time::Keeper::Business::Rule->uk, weekend => 'en-GB');
my $t = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
my $d = $t->to_date;
$b->plus_business_days($t, 10);
my $mine = rate(sub { $b->plus_business_days($t, 10) }, 'plus_business_days');
my $core = rate(sub { $t->plus(days => 10) }, 'Time::Keeper plus(days)');
printf "info plus_business_days of a Date: %s\n", fmt_rate(rate(sub { $b->plus_business_days($d, 10) }, 'a Date'));
mark_rate('plus_business_days($t, 10)', $mine, 2e6);
mark_less('plus_business_days vs plus(days => 10)', sprintf('%.2f', $core / $mine), 5, 1, 'within', 'x');
if (eval { require Date::Business; 1 }) {
    mark('plus_business_days', $mine, rate(sub { Date::Business->new(DATE => '20261015')->addb(10) }, 'Date::Business'), 20, 'Date::Business addb');
}
else { absent('Date::Business', 'addb') }
done();
