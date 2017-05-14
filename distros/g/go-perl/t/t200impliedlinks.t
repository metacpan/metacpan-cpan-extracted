#!/usr/local/bin/perl -w

use lib '.';
BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 2;
}

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use strict;
use GO::Parser;
use GO::ObjCache;

# ----- REQUIREMENTS -----

# This test script tests the GO::Model::LogicalDefinition

# ------------------------

my $parser = new GO::Parser ({handler=>'obj'});
my $graph = $parser->handler->g;
ok(1);
$parser->parse ("./t/data/impliedlinks.obo");
my $g = $parser->handler->graph;
my $t = $g->get_term("A");
my $ps = $g->get_parent_terms($t);
ok (@$ps==4);
