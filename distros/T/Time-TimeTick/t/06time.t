#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 1;
use blib;

my @Report;

use Time::TimeTick format_report => \&save_rpt,
    suppress_initial => 1, suppress_final => 1;

timetick("ONE");
sleep 1;
timetick("TWO");

Time::TimeTick::report;

my $elapsed = $Report[1][0] - $Report[0][0];
ok(0.8 < $elapsed && $elapsed < 1.2, "Time roughly in range");



sub save_rpt
{
  @Report = @_;
}


