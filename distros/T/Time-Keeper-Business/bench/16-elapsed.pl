#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Business;
my %b = map { $_ => Time::Keeper::Business->new(zone => 'America/New_York', hours => ['09:00-17:00'], reckon => $_) } qw(wall elapsed);
my ($a, $z) = map { Time::Keeper->new(year => 2026, month => 1, day => $_, hour => 11, zone => 'America/New_York') } 12, 19;
my $w = rate(sub { $b{wall}->business_hours_between($a, $z, number => 1) }, 'wall');
my $e = rate(sub { $b{elapsed}->business_hours_between($a, $z, number => 1) }, 'elapsed');
printf "info business_hours_between a steady week: wall %s, elapsed %s\n", fmt_rate($w), fmt_rate($e);
mark_less('between a week, elapsed vs wall', sprintf('%.2f', $w / $e), 2, 1, 'within', 'x');
done();
