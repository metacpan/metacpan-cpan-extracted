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


#stmt_ok;
#exit 0;
my $apph = get_readonly_apph();
my $terms = $apph->get_terms({acc=>[3673, 8150, 7582]});
my $term = $apph->get_term({acc=>8150});

# maybe get_graph_by_terms needs more args...

my $graph;

  $graph = $apph->get_graph_by_terms(
					-terms=>$terms,
					-close_below=>$term,
					-depth=>0
				       );

my $has_7582;
eval {
  foreach my $node (@$graph->get_all_nodes) {
    if ($node->acc eq "GO:0007582") {
      $has_7582 = 1;
    }
  }
};

stmt_check(!$has_7582);

$terms = $apph->get_terms({acc=>[9274]});
$term = $apph->get_term({acc=>"GO:0005575"});#
$graph = $apph->get_graph_by_terms(
                                        -terms=>$terms,
                                        -close_below=>"GO:0005575",
                                        -depth=>0
                                  );
 
$graph->to_text_output; 
stmt_note($graph->node_count);
stmt_check($graph->node_count == 2);
