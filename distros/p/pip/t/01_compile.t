#!/usr/bin/perl 

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
use Test::Script;

use_ok( 'Module::Plan::Base'    );
use_ok( 'Module::Plan::Lite'    );
use_ok( 'Module::Plan::Archive' );
use_ok( 'Module::P5Z'           );
use_ok( 'pip'                   );

script_compiles_ok( 'script/pip' );

# Test the test library
use_ok( 't::lib::Test' );
