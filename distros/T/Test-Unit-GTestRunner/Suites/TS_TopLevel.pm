#! /bin/false

package Suites::TS_TopLevel;

use strict;

BEGIN {
#	$SIG{HUP} = $SIG{TERM} = $SIG{QUIT} = 'IGNORE';
}

use base qw (Test::Unit::TestSuite);

sub name { "The top-level test suite" };
sub include_tests { 
		(
		 "Suites::TS_SubSuite1", 
		 "Suites::TS_SubSuite2"
		) 
};

1;
