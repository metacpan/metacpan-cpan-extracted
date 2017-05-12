#!/usr/bin/perl -w

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5.008_008, "Your perl is new enough" );
use_ok('XPanel');

exit(0);