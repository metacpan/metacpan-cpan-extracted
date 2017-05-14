#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 7;
}
use strict;
use GO::Model::Graph;

# ----- REQUIREMENTS -----

# A graph object must be able to trace multiple paths to the root, if 
# there exists > 1path

# Graphs should deal with redundant info gracefully

# It should be possible to iterate from a root of the graph to the leaf nodes,
# tracing multiple paths if required

# ------------------------

my $graph = GO::Model::Graph->new;
ok(1);

map {
	$graph->add_term({acc=>$_});
} qw (1 2 3 4 5 6);

$graph->add_relationship(1, 2);
$graph->add_relationship(1, 3);
#$graph->add_relationship(2, 4);
# add_relationship can be used in two ways with identical reuslts;
# let's checkboth
$graph->add_relationship({acc1=>2, acc2=>4});
$graph->add_relationship(3, 4);
$graph->add_relationship(4, 5);

# lets check we got stuff
my $pl;

$pl = $graph->paths_to_top(5);
#map {stmt_note("path length = ".$_->length."\n")} @$pl;
ok(@$pl == 2);

# 
$graph->add_relationship(4, 5);
$pl = $graph->paths_to_top(5);
#map {stmt_note("path length = ".$_->length."\n")} @$pl;
ok(@$pl == 2);

#
my $tl;
$tl = $graph->get_parent_terms(4);
ok(@$tl == 2);

$tl = $graph->get_child_terms(1);
ok(@$tl == 2);

# traverse
my $n = 0;
my @nodes = (1);
while (@nodes) {
	$n++;
	my $node = shift @nodes;
	my @children= map {$_->{acc}} @{$graph->get_child_terms($node)};
#	stmt_note("node:$node has ".join(";",@children)." children\n");
	push(@nodes, map {$_->{acc}} @{$graph->get_child_terms($node)});
}
# some paths should have been traversed twice
ok($n == 7);

ok(1);
