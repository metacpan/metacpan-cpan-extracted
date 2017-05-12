#!/usr/bin/perl

# Compile testing for pler

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::Script;

# Does the script compile
use_ok( 'pler' );
script_compiles_ok( 'script/pler' );
