#!/usr/bin/perl

# Compile testing for WWW::ActiveState::PPM

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5.006, 'Perl version is new enough' );

use_ok( 'WWW::ActiveState::PPM' );
