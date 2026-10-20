#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Sky; use Time::Keeper::Star;

# A star map's call: every star to magnitude 4.5 (about 900) from a place at
# one instant. The mark, set in plan_time_keeper_sky/05: under 2 ms.
my $sky = Time::Keeper::Sky->new(place => 'Europe/London');
my $t = Time::Keeper->new(year => 2026, month => 10, day => 19, hour => 22, zone => 'UTC');
my $pos = rate(sub { Time::Keeper::Star->positions($t, magnitude => 4.5, place => $sky) }, 'positions to 4.5');
my $one = rate(sub { Time::Keeper::Star->position('Vega', $t, place => $sky) }, 'one star');
my $find = rate(sub { Time::Keeper::Star->find('alpha Ori') }, 'find by Bayer');
printf "info positions to 4.5 %s (%.2f ms); one position %s; find('alpha Ori') %s\n", fmt_rate($pos), 1000 / $pos, fmt_rate($one), fmt_rate($find);
mark_less('Star->positions to magnitude 4.5', sprintf('%.2f', 1000 / $pos), 2, 1, 'the mark', 'ms');
done();
