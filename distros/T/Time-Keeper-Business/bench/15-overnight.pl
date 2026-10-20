#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Business;
my $day   = Time::Keeper::Business->new(zone => 'Europe/London', hours => ['09:00-17:30']);
my $night = Time::Keeper::Business->new(zone => 'Europe/London', hours => ['22:00-06:00']);
my $t = Time::Keeper->new(year => 2026, month => 10, day => 16, hour => 3, zone => 'Europe/London');
my $d = rate(sub { $day->is_business_hours($t) }, 'daytime');
my $n = rate(sub { $night->is_business_hours($t) }, 'overnight');
printf "info is_business_hours at 03:00: daytime table %s, overnight table %s\n", fmt_rate($d), fmt_rate($n);
mark_less('is_business_hours, overnight vs daytime', sprintf('%.2f', $d / $n), 1.5, 1, 'within', 'x');
done();
