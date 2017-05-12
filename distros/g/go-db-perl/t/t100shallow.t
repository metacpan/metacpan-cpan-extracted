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

# get shallow graph
my $graph = $apph->get_node_graph(-acc=>5783, 
				  -depth=>0, 
				  -template=>{terms=>"shallow"});

# check top level term
my $t = $graph->get_term("GO:0005783");

# check no assocs have been loaded by 
# peeking into object
stmt_check(!defined($t->{association_list}));

# the number of assocs should be loaded
stmt_check($t->n_associations() > 0);

# check late-loading is working
stmt_check(scalar(@{$t->association_list}));
$apph->disconnect;













