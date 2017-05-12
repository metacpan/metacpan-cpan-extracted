#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

# OVERVIEW:
# The idea here is that we want to be able to build a 
# graph stepwise, like in a filesystem browser.  The problem
# is that we don't want the parentage of all nodes.  The solution
# is to get a full (parentage included) graph of one term (the one
# used in the original search).  Then you can add other terms as their
# children to the graph as needed.

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 1, todo => [1] }   
use GO::TestHarness;
use GO::AppHandle;
use FileHandle;

# ----- REQUIREMENTS -----

# ------------------------

my $apph = get_readonly_apph();
eval {
    require "GO/IO/HTML.pm";
    my $open_nodes = ('GO:0004002', 'GO:0008026');
    my $graph = $apph->get_node_graph({acc=>4004,
                                       open_nodes=>$open_nodes});
    my $out = new FileHandle(">-");
    
    ok(scalar(@{$graph->paths_to_top} == 7));
};
if ($@) {
    ok(0);
}
