#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
BEGIN {
	$ENV{SLOW_TEST} = 1;
}
use Test::Slow;

# I want to execute this test thanks to env var SLOW_TEST=1
ok(1);

done_testing;
