#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Moon;

# The moon: phase_name (which finds the last new moon) against
# Astro::MoonPhase's phase, and next(phase => 'full') on its own.
eval { require Astro::MoonPhase; 1 }
    or do { print "SKIP moon: Astro::MoonPhase is not installed (TK_BENCH_LIB)\n"; exit 0 };
my $t = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 12, zone => 'UTC');
my $name = rate(sub { Time::Keeper::Moon->phase_name($t) }, 'phase_name');
my $illum = rate(sub { Time::Keeper::Moon->illumination($t) }, 'illumination');
my $theirs = rate(sub { my @p = Astro::MoonPhase::phase(1760000000) }, 'Astro::MoonPhase phase');
my $next = rate(sub { Time::Keeper::Moon->next(phase => 'full', after => $t) }, 'next full');
my $hunt = rate(sub { my @p = Astro::MoonPhase::phasehunt(1760000000) }, 'Astro::MoonPhase phasehunt');
my $day = rate(sub { Time::Keeper::Moon->on($t, zone => 'Europe/London') }, 'Moon->on');
printf "info phase_name %s; illumination %s; next full %s; Moon->on %s; Astro::MoonPhase phase %s, phasehunt %s\n",
    map { fmt_rate($_) } $name, $illum, $next, $day, $theirs, $hunt;
mark('Moon->phase_name', $name, $theirs, 2, 'Astro::MoonPhase');
mark('Moon->next(phase => full)', $next, 100_000, 1, 'the mark');
done();
