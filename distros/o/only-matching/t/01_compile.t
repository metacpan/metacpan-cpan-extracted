#!/usr/bin/perl -w

# Compile testing for only::matching

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5.005, 'Perl version is new enough' );

require_ok( 'only::matching' );
