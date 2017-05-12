#!/usr/bin/perl

# Compile testing for Test::POE::Stopping

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

# Check their perl version
ok( $] >= 5.006, "Your perl is new enough" );

# Does the module load
use_ok('Test::POE::Stopping');
ok(
	defined(&poe_stopping),
	'Exports pod_stopping by default',
);
