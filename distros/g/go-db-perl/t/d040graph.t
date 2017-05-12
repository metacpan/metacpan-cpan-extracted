#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;
use Test;
BEGIN { plan tests => 8, todo => [] }
set_n_tests(8);

use GO::Parser;

 # Get args

create_test_database("go_graphtest");
my $apph = getapph() || die;

 my $user = {person=>'auto'};

my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);

ok(1);
$parser->parse ("./t/data/baby-function.dat");
$apph->add_root;
ok(1);

# lets check we got stuff

my $graph = $apph->get_graph_by_search("*DNA*", 0);
my $n_nodes = scalar(@{$graph->get_all_nodes});
$graph->to_text_output;
print "n_nodes=$n_nodes\n";
ok($n_nodes == 35);

# OK, now we're going to try to build a two step graph
# to multiple depths.

my $g = $apph->get_graph_by_acc("GO:0003702", 0);

# first we check that 3702 got no kids.
ok(scalar(@{$g->get_child_relationships("GO:0003702")}) == 0);
print "n_children ".$g->n_children("GO:0003702")."\n";
print "c_r ".scalar(@{$g->get_child_relationships("GO:0003702")})."\n";
if ($apph->can("extend_graph")) {
    $apph->extend_graph($g, "GO:0003711", 1);

    # "GO:0003702" still has no kids
    ok(scalar(@{$g->get_child_relationships("GO:0003702")}) == 0);

    # but "GO:0003711" is now in the graph and has all of its kids
    ok($g->n_children("GO:0003711") == scalar(@{$g->get_child_relationships("GO:0003711")}));

    # make sure "GO:0003711" is a focus node
    my $test = 0;
    foreach my $focus_node (@{$g->focus_nodes()}) {
        print $focus_node->to_text, "\n";
        if ($focus_node->acc == "GO:0003711" ) {$test = 1}
    }
    ok($test);
}
else {
    ok(0);
    ok(0);
    ok(0);
}



$apph->disconnect;
destroy_test_database();
ok(1);;
