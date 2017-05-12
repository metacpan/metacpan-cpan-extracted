#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 1,}
use GO::TestHarness;
use GO::AppHandle;

# ----- REQUIREMENTS -----

# ------------------------

#n_tests(7);

#stmt_ok;
#exit 0;

my $apph = get_readonly_apph();
my $node = $apph->get_term({acc=>30532});
printf "node=$node\n";
my $g = $apph->get_graph_by_terms([$node]);
stmt_note( $g->n_associations($node->acc) );

ok($g->n_associations($node->acc));

