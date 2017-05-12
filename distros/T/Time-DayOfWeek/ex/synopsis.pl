#!/usr/bin/perl
use strict;use warnings;use utf8;use v5.10;
use Time::DayOfWeek qw(:dow);

my         ($year, $month, $day)  =  (2003, 12, 7);

say "The Day-of-Week of $year/$month/$day (YMD) is: ",
  DayOfWeek($year, $month, $day);

say 'The 3-letter abbreviation       of the Dow is: ',
  Dow(      $year, $month, $day);

say 'The 0-based  index              of the DoW is: ',
  DoW(      $year, $month, $day);
