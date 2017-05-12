#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 2 }
use GO::TestHarness;
use GO::AppHandle;

# ----- REQUIREMENTS -----

# xrefs should come back sorted by database 
# then xref key.

# ------------------------

my $apph = get_readonly_apph;
#my $apph = get_readonly_apph();
my $t = $apph->get_term_by_acc(3700);
my $db1;
my $db2;
my $term1;
my $term2;
my $test1 = 1;
my $test2 = 1;
foreach my $xref (@{$t->dbxref_list}) {
	if (!$db1) {
		$db1 = $xref->xref_dbname;
	}	
	$db2 = $xref->xref_dbname;
	if (!$db1 ne $db2) {
		if (lc($db2) lt lc($db1)) {
			$test1 = 0;
		} else {
			$db1 = $db2;
		}
	} else {
		if (!$term1) {
			$term1 = $xref->xref_key;
		}	
		$term2 = $xref->xref_dbname;
		if ($term2 lt $term1) {
			$test2 = 0;
		} else {
			$term1 = $term2;
		}
	}
        stmt_note($test1.$test2.$xref->as_str);
}	
		
stmt_check($test1);
stmt_check($test2);
