#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;
use blib;

my @Report;

use Time::TimeTick format_report => \&save_rpt,
    initial_tag => "INITIAL TEST", final_tag => "FINAL TEST";

timetick("TEST");

Time::TimeTick::end;

is($Report[0][1], 'INITIAL TEST', "Tag ok");
is($Report[1][1], 'TEST',         "Tag ok");
is($Report[2][1], 'FINAL TEST',   "Tag ok");



sub save_rpt
{
  @Report = @_;
}


