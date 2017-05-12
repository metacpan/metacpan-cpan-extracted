#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;
use GO::AppHandle;

# ----- REQUIREMENTS -----

# The only nodes in a graph that may be parent-less are the root
# nodes.  This test is based on the notion that go term 4175 only
# has 1 parent.  If this changes in the future this test will fail. 

# ------------------------

n_tests(4);

my $apph = get_readonly_apph;
my $term_graph = $apph->get_node_graph(-acc=>4175, -depth=>2, -template=>{terms=>"shallow"});
#my $term_graph = $apph->get_node_graph(-acc=>4175, -depth=>2);

stmt_ok;

my $root_counter = 0;
$term_graph->to_text_output;
foreach my $term (@{$term_graph->get_all_nodes}) {
  if (scalar(@{$term_graph->get_parent_relationships($term->acc)}) == 0) {
#      printf STDERR 
#	"term %s %s has no parents\n", $term->name, $term->public_acc;
    $root_counter++;
  }
}

print "Parentless nodes: " . $root_counter . "\n\n";
stmt_check( $root_counter == 1);
stmt_check( @{$term_graph->get_top_nodes} == 1);
my $root_acc = $term_graph->get_top_nodes->[0]->acc;
stmt_check( $root_acc eq "GO:0003673" || $root_acc eq 'all');
$apph->disconnect;
