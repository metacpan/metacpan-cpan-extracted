#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Business;
my $b = Time::Keeper::Business->new(holidays => Time::Keeper::Business::Rule->uk, weekend => 'en-GB');
my $sat = Time::Keeper->new(year => 2026, month => 10, day => 17, hour => 9, zone => 'Europe/London');
$b->roll($sat);
mark_rate('roll on a Saturday', rate(sub { $b->roll($sat) }, 'roll'), 5e6);
printf "info roll modified_following: %s; next_business_day: %s\n",
    fmt_rate(rate(sub { $b->roll($sat, convention => 'modified_following') }, 'modified_following')),
    fmt_rate(rate(sub { $b->next_business_day($sat) }, 'next_business_day'));
done();
