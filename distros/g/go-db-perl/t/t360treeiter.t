#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 2, todo => [1,2]  }
use GO::TestHarness;
use GO::AppHandle;
use GO::Model::TreeIterator;

# ----- REQUIREMENTS -----

#  Test that TreeIterator.pm acts
# like a tree and not like a graph.

# ------------------------

my @array;
my @arra;
my $apph = get_readonly_apph;
$apph->filters({evcodes=>['iea']});

my $g = $apph->get_node_graph(3700, 0);
#print $g->to_text_output;

#push @arra, ["GO:0003673", "GO:0005575", "GO:0005576", "GO:0009277", "GO:0005621"];
#push @array, ["GO:0003673", "GO:0005575", "GO:0005576", "GO:0009277"];#, 30312, 5618, 9277];
push @array, ["GO:0003673", "GO:0003674", "GO:0005488", "GO:0003676", "GO:0003677", "GO:0003700"];
push @array, ["GO:0003673", "GO:0003674", "GO:0030528", "GO:0003700"];
#push @arra, ["GO:0003673", "GO:0005575", "GO:0030312", "GO:0005618", "GO:0009277","GO:0005621"];
#push @array, [3673, 5575, 5576, 9277];
#push @array, ["GO:0003673"];
#my $i = new GO::Model::TreeIterator($g, \@array);         
#$i->close_below();
#$i->set_bootstrap_mode;
#while (my $ni = $i->next_node_instance) {
#	my $a = $i->get_current_path;
#	print $ni->term->acc."\n";#
#
#}
ok(0);
ok(0);


