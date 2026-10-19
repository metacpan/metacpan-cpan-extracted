#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Sun;

# A sunrise: on($date)->sunrise, which computes the whole day, against
# Astro::Sunrise's sunrise (the function that takes a date; sun_rise answers
# for today) in precise mode, which iterates in Perl.
eval { require Astro::Sunrise; Astro::Sunrise->import(qw(sunrise)); 1 }
    or do { print "SKIP sunrise: Astro::Sunrise is not installed (TK_BENCH_LIB)\n"; exit 0 };
my $sun = Time::Keeper::Sun->new(latitude => 51.5074, longitude => -0.1278, zone => 'Europe/London');
my $date = Time::Keeper::Date->new(year => 2026, month => 10, day => 15);
my $mine = rate(sub { $sun->on($date)->sunrise }, 'Time::Keeper::Sun');
my $theirs = rate(sub { my @rs = sunrise({ lon => -0.1278, lat => 51.5074, tz => 1, year => 2026, month => 10, day => 15, precise => 1 }) }, 'Astro::Sunrise precise');
mark('on($date)->sunrise', $mine, $theirs, 2, 'Astro::Sunrise');
my $loose = rate(sub { my @rs = sunrise({ lon => -0.1278, lat => 51.5074, tz => 1, year => 2026, month => 10, day => 15, precise => 0 }) }, 'Astro::Sunrise');
printf "info Astro::Sunrise without precise: %s\n", fmt_rate($loose);
my $next = rate(sub { $sun->next_sunrise(1760000000) }, 'next_sunrise');
printf "info next_sunrise, one event from an instant: %s (on() computes the whole day: the transits and eight kinds of crossing)\n", fmt_rate($next);
done();
