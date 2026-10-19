#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Sun;

# A whole day: on() computes the transits, their extrema and the eight kinds
# of crossing in one go.
my $sun = Time::Keeper::Sun->new(latitude => 51.5074, longitude => -0.1278, zone => 'Europe/London');
my $date = Time::Keeper::Date->new(year => 2026, month => 10, day => 15);
my $day = rate(sub { $sun->on($date) }, 'on');
my $polar = Time::Keeper::Sun->new(latitude => 71.2906, longitude => -156.7886, zone => 'America/Anchorage');
my $pd = Time::Keeper::Date->new(year => 2026, month => 5, day => 10);
my $polar_rate = rate(sub { $polar->on($pd) }, 'on, polar edge');
my $d = $sun->on($date);
my $acc = rate(sub { $d->sunrise }, 'sunrise accessor');
my $ev = rate(sub { my @e = $d->events }, 'events');
my $next = rate(sub { $sun->next_sunrise(1760000000) }, 'next_sunrise');
printf "info on %s; a polar-edge day %s; sunrise accessor %s; events %s; next_sunrise %s\n",
    map { fmt_rate($_) } $day, $polar_rate, $acc, $ev, $next;
mark('on(), a whole day', $day, 5000, 1, 'the mark');
done();
