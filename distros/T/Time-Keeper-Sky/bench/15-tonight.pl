#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Sky; use Time::Keeper::Star; use Time::Keeper::Planet;

# Tonight from London, the stars to 1.5 and to 4.5; the night alone; a
# star's day; a planet's position by name through the Sky against its own
# class's. plan_time_keeper_sky/09 set no mark: these are figures for
# Phase 10 to set its marks by.
my $sky = Time::Keeper::Sky->new(place => 'Europe/London');
my $date = Time::Keeper->new(year => 2026, month => 10, day => 19, hour => 12, zone => 'Europe/London');
my $t = Time::Keeper->new(year => 2026, month => 10, day => 19, hour => 22, zone => 'UTC');
my $tn = rate(sub { my @x = $sky->tonight(date => $date) }, 'tonight');
my $tn45 = rate(sub { my @x = $sky->tonight(date => $date, magnitude => 4.5) }, 'tonight to 4.5');
my $night = rate(sub { $sky->night(date => $date) }, 'night');
my $sday = rate(sub { Time::Keeper::Star->on($date, 'Sirius', place => $sky) }, 'Star->on');
my $gen = rate(sub { $sky->position('jupiter', $t) }, 'position by name');
my $own = rate(sub { Time::Keeper::Planet->position('jupiter', $t, place => $sky) }, 'Planet->position');
printf "info tonight %s (%.1f ms); to magnitude 4.5 %s (%.1f ms); night %s (%.2f ms)\n", fmt_rate($tn), 1000 / $tn, fmt_rate($tn45), 1000 / $tn45, fmt_rate($night), 1000 / $night;
printf "info Star->on %s (%.2f ms); position('jupiter') through the Sky %s, Planet->position %s\n", fmt_rate($sday), 1000 / $sday, fmt_rate($gen), fmt_rate($own);
done();
