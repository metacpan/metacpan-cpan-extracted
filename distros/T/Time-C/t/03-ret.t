#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

use Time::C;

my $t = Time::C->now();
my $ret = $t->day_of_week = 8;

is ($ret, 1, 'correct return value');
