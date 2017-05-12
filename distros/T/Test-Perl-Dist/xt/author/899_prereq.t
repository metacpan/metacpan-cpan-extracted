#!/usr/bin/perl

# Test that all our prerequisites are defined in the Makefile.PL.

use strict;

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::Prereq::Build 1.036',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" )
	}
}

diag('Takes a few minutes...');

prereq_ok(5.008001, 'Check prerequisites');
