#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 1;
use blib;

my $report_called = 0;

use Time::TimeTick format_report => \&save_rpt, suppress_report => 1;

timetick("TEST");

Time::TimeTick::report;

ok(! $report_called, "Report suppressed");


sub save_rpt
{
  $report_called = 1;
}


