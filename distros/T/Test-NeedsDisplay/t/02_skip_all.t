#!/usr/bin/perl

# This should skip properly if you don't have DISPLAY

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::NeedsDisplay ':skip_all';
use Test::More tests => 1;

ok( 1, 'Stub test' );
