#!/usr/bin/perl

use strict;
use ex::lib '../lib';
use Test::More tests => 2;


BEGIN {
	use_ok( 'constant::def' );
	use_ok( 'constant::abs' );
}

diag( "Testing constant::def $constant::def::VERSION, Perl $], $^X" );
