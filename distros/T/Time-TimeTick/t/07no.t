#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 1;
use blib;

my @Report;

no Time::TimeTick format_report => \&save_rpt;

timetick("TEST");

Time::TimeTick::report;

ok(! @Report, "Report is empty");


sub save_rpt
{
  @Report = @_;
}


