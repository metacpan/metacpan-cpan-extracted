#!/usr/bin/env perl

use strict;
use lib::abs '../lib';
use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::If' );
}

diag( "Testing Test::If $Test::If::VERSION, Perl $], $^X" );
