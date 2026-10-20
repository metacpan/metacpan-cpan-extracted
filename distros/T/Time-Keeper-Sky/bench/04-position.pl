#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Sun;

my $sun = Time::Keeper::Sun->new(latitude => 51.5074, longitude => -0.1278, zone => 'Europe/London');
my $t = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 12, zone => 'UTC');
my $pos = rate(sub { $sun->position($t) }, 'position');
my $epoch = rate(sub { $sun->position(1760000000) }, 'position, epoch');
my $dt = rate(sub { Time::Keeper::Sun->delta_t($t) }, 'delta_t');
printf "info position %s (from an epoch %s); delta_t %s\n", map { fmt_rate($_) } $pos, $epoch, $dt;
mark('position', $pos, 500_000, 1, 'the mark');
done();
