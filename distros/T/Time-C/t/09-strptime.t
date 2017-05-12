#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

plan tests => 4;

use Time::C;

my $t = Time::C->strptime("2016-04-30", "%Y-%m-%d")->strptime("15:48:09", "%H:%M:%S");

is ($t, "2016-04-30T15:48:09Z", "correct time from two strptime calls");

my $t2 = Time::C->strptime("15:48:09", "%H:%M:%S")->strptime("2016-04-30", "%Y-%m-%d");

is ($t2, "2016-04-30T15:48:09Z", "correct time even if the order is reversed");

my $t3 = Time::C->strptime("09", "%S")->strptime("04", "%m")->strptime("15", "%H")->strptime("30", "%d")->strptime("48", "%M")->strptime("2016", "%Y");

is ($t3, "2016-04-30T15:48:09Z", "correct time even if everything is scrambled");

my $t4 = Time::C->now_utc(); $t4->strptime("2016-04-30", "%Y-%m-%d")->strptime("15:48:09", "%H:%M:%S");

is ($t4, "2016-04-30T15:48:09Z", "correct time even after calling strptime on an object");

#done_testing;
