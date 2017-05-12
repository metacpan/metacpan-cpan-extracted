#!/usr/bin/perl

use 5.008005;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use Test::NoWarnings;
use Test::Script;

# Load ::Publish first to make sure it works independantly
use_ok( 'Xtract::Publish' );
ok( $Xtract::Publish::VERSION, 'Loaded Xtract::Publish' );
is( $Xtract::VERSION, undef, 'Did not load Xtract.pm' );

use_ok( 'Xtract' );

script_compiles_ok( 'script/xtract' );
