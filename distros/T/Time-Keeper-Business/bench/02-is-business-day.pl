#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Business;
my $b = Time::Keeper::Business->new(holidays => Time::Keeper::Business::Rule->uk, weekend => 'en-GB');
my $t = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
my $d = $t->to_date;
$b->is_business_day($t);
my $tk = rate(sub { $b->is_business_day($t) }, 'a Time::Keeper');
my $dd = rate(sub { $b->is_business_day($d) }, 'a Date');
printf "info is_business_day of a Date: %s (two method calls into the core)\n", fmt_rate($dd);
mark_rate('is_business_day', $tk, 5e6);
printf "info Date::Business has no business-day predicate: no comparison here\n";
done();
