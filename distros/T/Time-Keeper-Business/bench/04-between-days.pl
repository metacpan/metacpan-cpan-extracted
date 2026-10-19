#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Business;
my $b = Time::Keeper::Business->new(holidays => Time::Keeper::Business::Rule->uk, weekend => 'en-GB');
my ($a, $z) = (Time::Keeper->new(year => 2026, month => 1, day => 1, zone => 'UTC'), Time::Keeper->new(year => 2027, month => 1, day => 1, zone => 'UTC'));
$b->business_days_between($a, $z);
my $mine = rate(sub { $b->business_days_between($a, $z) }, 'business_days_between');
mark_rate('business_days_between, a year', $mine, 2e6);
if (eval { require Date::Business; 1 }) {
    my ($x, $y) = (Date::Business->new(DATE => '20260101'), Date::Business->new(DATE => '20270101'));
    mark('business_days_between', $mine, rate(sub { $x->diffb($y) }, 'Date::Business'), 20, 'Date::Business diffb');
}
else { absent('Date::Business', 'diffb') }
done();
