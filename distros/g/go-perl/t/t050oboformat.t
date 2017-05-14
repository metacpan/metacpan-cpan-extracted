#!/usr/local/bin/perl -w

use lib '.';
BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 6;
}
# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use strict;
use GO::Parser;

# ----- REQUIREMENTS -----

# This test script tests the following requirements:/x
# GO::Model::Graph must implement the GO::Builder interface; ie
# it should be possible to pass in a graph to a parser and have it build
# up a graph object

# ------------------------

my $parser = new GO::Parser ({format=>'obo_text',
			      handler=>'obj'});
ok(1);
$parser->parse (shift @ARGV || "./t/data/test-go.obo");
ok(1);
my $graph = $parser->handler->g;
my $terms = $graph->find_roots;
foreach my $term (@$terms) {
    printf "ROOT: %s\n", $term->name;
}
ok(@$terms == 3);
$terms = $graph->get_all_nodes;
my $t = 0;
my $t2 = 0;
ok(@$terms == 97);
foreach my $term (@$terms) {
    my $rels = $graph->get_relationships($term->acc);
    $t2 += @$rels;
    $t+= @{$graph->get_parent_relationships($term->acc)};
    foreach my $rel (@$rels) {
	printf "EDGE|%s|%s|%s\n",
	  $rel->subject_acc,
	    $rel->object_acc,
	      $rel->type;
    }
}
printf "total parent rels:%s\n", $t;
printf "total (both ways):%s\n", $t2;
ok($t == 118);
ok($t2 == 218);   # trailing rels counted only once

