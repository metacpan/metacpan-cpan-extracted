#!perl
use 5.010;
use strict;
use warnings;
use Time::Keeper;
use Time::Keeper::Business;

my $year = shift // Time::Keeper->today->year;
my $rule = Time::Keeper::Business::Rule->uk;
my $b = Time::Keeper::Business->new(holidays => $rule, weekend => 'en-GB', zone => 'Europe/London', name => $rule->name);

print "$b, $year\n";
printf "  %s  %s  %s\n", $_->[0], $_->[0]->format('EEEE'), $_->[1] for $b->holidays(year => $year);

my $day = Time::Keeper::Date->new(year => $year, month => 12, day => 20);
print "the ten business days after $day:\n";
printf "  %s  %s\n", $day = $b->next_business_day($day), $day->format('EEEE') for 1 .. 10;
