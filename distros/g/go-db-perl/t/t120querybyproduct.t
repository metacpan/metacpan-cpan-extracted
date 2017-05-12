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

n_tests(2);
my $apph = get_readonly_apph;
stmt_ok;

# this should return a list of terms adorned with the 
# relevant associations
my $terms = 
  $apph->get_terms_by_product_symbols([qw(NSR1 TAF67 NUF1 ARP5)],
                                     {speciesdb=>"SGD"});

my $graph = $apph->get_graph_by_terms($terms, 0);
$graph->iterate(sub {my $ni = shift;
                     my $depth = $ni->depth;
                     my $term = $ni->term;
                     my $reltype = 
                       $ni->parent_rel ? $ni->parent_rel->type : "";
                     my $tab = $graph->is_focus_node($term) ? "****" : "    ";
                     my $out =
                       sprintf 
                         "%s %2s Term = %s (%s) :: %s\n",
                         $tab x $depth,
                         $reltype eq "isa" ? "%" : "<",
                         $term->name,
                         $term->public_acc,
                         join("; ", map {$_->gene_product->symbol} @{$term->selected_association_list || []})
                         ;
                     print $out;
                 });
stmt_ok;
