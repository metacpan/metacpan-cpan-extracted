#!/usr/local/bin/perl -w

use lib '.';
BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 4;
}
# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use strict;

# ----- REQUIREMENTS -----

# This test script tests the following requirements:/x
# GO::Model::Graph must implement the GO::Builder interface; ie
# it should be possible to pass in a graph to a parser and have it build
# up a graph object

# ------------------------
use GO::Basic;

parse_obo("t/data/test-nucleolar.obo");
find_term(name=>"nuclear body");
print term->acc,"\n";                 # OO usage
print acc(),"\n";                        # procedural usage
ok(acc eq 'GO:0016604');
print "PARENTS\n";
get_parents;
print names, "\n";
ok(names == 1);

get_rparents;
my @names = sort {$a cmp $b} names();
print "@names\n";
ok ("@names" eq "Gene_Ontology cell cellular_component intracellular nucleoplasm nucleus");

find_term("nucleoplasm");
print acc(),"\n";                        # procedural usage
get_rchildren;
@names = sort {$a cmp $b} names();
print "@names\n";
ok ("@names" eq "RENT complex chromatin remodeling complex chromatin silencing complex nuclear body nuclear speck");

find_term(name=>"nuclear organisation and biogenesis");
print term->acc,"\n";                 # OO usage
