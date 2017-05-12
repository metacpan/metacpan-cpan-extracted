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

# ------------------------

#n_tests(7);

#stmt_ok;
#exit 0;

my $apph = get_readonly_apph();
my $t=$apph->get_term({acc=>3677});
my $children = $t->get_child_terms;
my $g = $apph->get_graph("GO:0003677", 0);
stmt_note($g->n_children("GO:0003677"));
stmt_check(scalar(@$children) == $g->n_children("GO:0003677"));

stmt_ok;
