#!/usr/bin/perl

# Load testing for prefork.pm

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 2;

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Does the module load
use_ok('prefork');
