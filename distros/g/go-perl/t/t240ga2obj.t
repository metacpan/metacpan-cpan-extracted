#!/usr/local/bin/perl -w

use lib '.';
use constant NUMTESTS => 3;
BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => NUMTESTS;
}
# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use strict;
use GO::Parser;

# ----- REQUIREMENTS -----

# The gene association file must be isomorphic to the GO model

# ------------------------


if (1) {

    ## Setup
    my $f = './t/data/test-gene_association.fb';
    my $p = GO::Parser->new({format=>'go_assoc', handler=>'obj'});
    $p->parse($f);
    my $g = $p->handler->graph;
    my $term_l = $g->get_all_nodes;

    ## Get all the nodes?
    ok(scalar(@{$g->get_all_nodes}), 40);

    ## Examine one node in detail.
    my $t = $g->get_term("GO:0000003");

    ## Acc right?
    ok($t->acc,'GO:0000003');

    ## Aspect right?
    ok($t->get_code_from_namespace,'P');    
}
