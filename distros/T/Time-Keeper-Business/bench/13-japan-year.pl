#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Business;
require './eg/japan.pl';
my ($jp, $y) = (japan(), 2016);
mark_rate('a new year of the Japan set (sandwiched day)', rate(sub { if (++$y > 2999) { $y = 2016; $jp = japan() } $jp->holidays(year => $y) }, 'japan'), 3e4);
done();
