#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;
use GO::AppHandle;
#use GO::Model::Graph;
# ----- REQUIREMENTS -----

# This test script tests the following requirements:

# ------------------------

n_tests(4);
my $apph = get_readonly_apph;
stmt_ok;
my $term = $apph->get_term_by_acc(8047);
stmt_ok;
stmt_note('getting assocs');
my $as = $term->association_list;
stmt_note("assocs:@$as");
stmt_check($term->association_list->[0]->gene_product->speciesdb ne '');


stmt_check($term->association_list->[0]->gene_product->acc ne '');
