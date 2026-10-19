#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Sun; use Time::Keeper::Moon;

# A moonrise: Moon->on($date, place => $sun)->moonrise, which computes the
# day's moonrises, moonsets and transits from the moon's place by chapter 47.
my $sun = Time::Keeper::Sun->new(place => 'Europe/London');
my $date = Time::Keeper::Date->new(year => 2026, month => 10, day => 15);
my $rise = rate(sub { Time::Keeper::Moon->on($date, place => $sun)->moonrise }, 'Moon->on(place)->moonrise');
my $bare = rate(sub { Time::Keeper::Moon->on($date) }, 'Moon->on, no place');
my $next = rate(sub { Time::Keeper::Moon->next_moonrise(1760000000, place => $sun) }, 'next_moonrise');
printf "info a moon day with a place %s; without %s; next_moonrise %s\n", map { fmt_rate($_) } $rise, $bare, $next;
mark('Moon->on($date, place => $sun)->moonrise', $rise, 20_000, 1, 'the mark');
done();
