#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Sun; use Time::Keeper::Moon;

my $sun = Time::Keeper::Sun->new(place => 'Europe/London');
my $t = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 12, zone => 'UTC');
my $top = rate(sub { Time::Keeper::Moon->position($t, place => $sun) }, 'position, place');
my $geo = rate(sub { Time::Keeper::Moon->position($t) }, 'position');
my $ill = rate(sub { Time::Keeper::Moon->illumination($t) }, 'illumination');
printf "info position from a place %s; geocentric %s; illumination, exact %s\n", map { fmt_rate($_) } $top, $geo, $ill;
mark('Moon->position($t, place => $sun)', $top, 300_000, 1, 'the mark');
mark('Moon->illumination, exact', $ill, 500_000, 1, 'the mark');
done();
