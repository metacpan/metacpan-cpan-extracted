#!/usr/bin/perl

# Compile testing for asa

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;

require_ok('asa');
