#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Sun;

my $four = rate(sub { my @s = Time::Keeper::Sun->seasons(year => 2026) }, 'seasons');
my $one = rate(sub { Time::Keeper::Sun->solstice(year => 2026, month => 'june') }, 'solstice');
printf "info seasons %s; one solstice %s\n", fmt_rate($four), fmt_rate($one);
mark('seasons, the four of a year', $four, 100_000, 1, 'the mark');
done();
