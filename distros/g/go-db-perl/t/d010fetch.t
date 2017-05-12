#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;

n_tests(4);

my $apph = get_readonly_apph();
stmt_ok;

# lets check we got stuff

my $t = $apph->get_term({acc=>3677});
stmt_note("got term ".$t->description."\n");
stmt_ok;

my $graph = $apph->get_graph($t->acc, 3);
$graph->to_text_output;
stmt_note("Graph has nodes :".$graph->node_count);
stmt_ok;
# traverse
my $n = 0;
my @nodes = (3677);
while (@nodes) {
	$n++;
	my $node = shift @nodes;
	my @children= map {$_->{acc}} @{$graph->get_child_terms($node)};
	stmt_note("node:$node has ".join(";",@children)." as children\n");
	push(@nodes, map {$_->{acc}} @{$graph->get_child_terms($node)});
}

$apph->disconnect;
stmt_ok;
