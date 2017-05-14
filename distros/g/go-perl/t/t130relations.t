#!/usr/local/bin/perl -w

use lib '.';
BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 7;
}
# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use strict;
use GO::Parser;
use GO::ObjCache;

# ----- REQUIREMENTS -----

# This test script tests the following requirements:/x
# GO::Model::Graph must implement the GO::Builder interface; ie
# it should be possible to pass in a graph to a parser and have it build
# up a graph object

# also tests id-mapping tag

# ------------------------

my $parser = new GO::Parser ({handler=>'obj'});
my $graph = $parser->handler->g;
ok(1);
$parser->parse ("./t/data/relationship.obo");
$parser->parse ("./t/data/test-nucleolar.obo");
my $t = $graph->get_term("GO:0007569");
ok($t->name, 'cell aging');
my $parents = $graph->get_parent_terms_by_type($t->acc,'OBO_REL:part_of');
ok(@$parents == 1);
my $t2 = shift @$parents;
ok($t2->name eq 'cell death');
ok(1);

my $rel = $graph->get_term('OBO_REL:derives_from');
ok($rel);
print $rel->transitive_over, "\n";
ok($rel->transitive_over eq 'OBO_REL:part_of');
