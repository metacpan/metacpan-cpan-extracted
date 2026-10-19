#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Business;
my $b = Time::Keeper::Business->new(holidays => Time::Keeper::Business::Rule->uk, weekend => 'en-GB', zone => 'Europe/London',
                                    hours => { default => ['09:00-12:30', '13:30-17:30'], fri => ['09:00-13:00'] });
my $t = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 11, zone => 'Europe/London');
$b->deadline($t, days => 2, end_of_day => 1);
mark_rate('deadline(days => 2, end_of_day => 1)', rate(sub { $b->deadline($t, days => 2, end_of_day => 1) }, 'deadline'), 1e6);
printf "info deadline(hours => 4): %s; deadline(): %s\n", fmt_rate(rate(sub { $b->deadline($t, hours => 4) }, 'hours')), fmt_rate(rate(sub { $b->deadline($t) }, 'next open'));
done();
