#!/usr/bin/perl

# Compile testing for Validate::Net

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5.005, 'Perl version is new enough' );

use_ok( 'Validate::Net' );
