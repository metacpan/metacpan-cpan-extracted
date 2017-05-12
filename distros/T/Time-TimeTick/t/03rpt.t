#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 2;
use blib;

my @Report;

use Time::TimeTick format_report => \&save_rpt,
    suppress_initial => 1, suppress_final => 1;

timetick("TEST");
Time::TimeTick::report;

like($Report[0][0], qr/[\d.]/, "Number ok");

is($Report[0][1], 'TEST', "Tag ok");


sub save_rpt
{
  @Report = @_;
}


