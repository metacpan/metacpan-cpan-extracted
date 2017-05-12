#!/usr/bin/perl

# Compile testing for VCS::CSync

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::Script;

ok( $] >= 5.005, "Your perl is new enough" );

use_ok('VCS::CSync');

script_compiles_ok('script/csync');

