#!/usr/bin/perl

# Compile test (trivial, should easily pass)

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5.005, 'Perl version is new enough' );

use_ok( 'ThreatNet::DATN2004' );
