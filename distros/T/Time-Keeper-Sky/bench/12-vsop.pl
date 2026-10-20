#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Sky; use Time::Keeper::Planet;

# VSOP87D, every term: one heliocentric place of each planet, and the sun
# from the VSOP87 earth against the chapter 25 sun, for information. The
# mark, set in plan_time_keeper_sky/00 before any number was seen: each
# planet's apparent place from a place, full series, 20,000 a second.
my $t = Time::Keeper->new(year => 2026, month => 10, day => 19, hour => 12, zone => 'UTC');
my $sky = Time::Keeper::Sky->new(place => 'Europe/London');
for my $p (qw(mercury venus earth mars jupiter saturn uranus neptune)) {
    my $r = rate(sub { Time::Keeper::Planet->heliocentric($p, $t) }, "heliocentric $p");
    printf "info heliocentric %-8s %s (%.1f us)\n", $p, fmt_rate($r), 1e6 / $r;
}
my $pr = rate(sub { $sky->position($t, precise => 1) }, 'position, precise');
my $c25 = rate(sub { $sky->position($t) }, 'position, chapter 25');
printf "info sun position precise %s (%.1f us); chapter 25 %s (%.1f us)\n", fmt_rate($pr), 1e6 / $pr, fmt_rate($c25), 1e6 / $c25;
for my $p (Time::Keeper::Planet->planets) {
    my $r = rate(sub { Time::Keeper::Planet->position($p, $t, place => $sky) }, "position $p");
    mark("Planet->position $p from a place", $r, 20000, 1, 'the mark');
}
done();
