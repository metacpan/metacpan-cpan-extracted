#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Sky; use Time::Keeper::Planet;

# A planet's day (rise, set, transit) at a place, a configuration search,
# and a year of closest approaches. Information for plan_time_keeper_sky/04;
# the marks are Phase 10's.
my $sky = Time::Keeper::Sky->new(place => 'Europe/London');
my $t = Time::Keeper->new(year => 2026, month => 10, day => 19, zone => 'UTC');
for my $p (qw(mercury jupiter neptune)) {
    my $r = rate(sub { Time::Keeper::Planet->on($t, $p, place => $sky) }, "on $p");
    printf "info Planet->on %-8s %s (%.2f ms)\n", $p, fmt_rate($r), 1000 / $r;
}
my $o = rate(sub { Time::Keeper::Planet->next(event => 'opposition', planet => 'mars', after => $t) }, 'next opposition');
my $e = rate(sub { Time::Keeper::Planet->next(event => 'greatest_elongation_east', planet => 'mercury', after => $t) }, 'next elongation');
my $c = rate(sub { Time::Keeper::Sky->closest_approach('moon', 'jupiter', from => $t, to => $t->epoch + 365 * 86400) }, 'closest a year');
printf "info next opposition (Mars) %.1f ms; next greatest elongation (Mercury) %.1f ms; a year of moon-Jupiter approaches %.0f ms\n", 1000 / $o, 1000 / $e, 1000 / $c;
done();
