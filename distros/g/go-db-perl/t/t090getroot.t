#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;
use GO::AppHandle;
 
n_tests(4);
my $apph = get_readonly_apph;
stmt_ok;

# check top level term
my $term = $apph->get_root_term;
print $term->acc."\n";
stmt_check($term->acc eq "GO:0003673" || $term->acc eq 'all');
my $rels = $apph->get_parent_terms($term);
stmt_check(!@$rels);

my $terms = $apph->get_ontology_root_terms;
printf "%s\n",$_->name foreach @$terms;
stmt_note(scalar(@$terms));

# 3 or 6 (may include obsoletes depending on db version)
stmt_check(scalar(@$terms) == 3 ||
           scalar(@$terms) == 6);
$apph->disconnect;
