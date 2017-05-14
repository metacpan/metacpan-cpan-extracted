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
use GO::ObjCache;

# ----- REQUIREMENTS -----

# This test script tests the following requirements:/x
# GO::Model::Graph must implement the GO::Builder interface; ie
# it should be possible to pass in a graph to a parser and have it build
# up a graph object

# ------------------------

my $parser = new GO::Parser ({format=>'obo',
			      handler=>'obj'});
my $graph = $parser->handler->g;
ok(1);

$parser->parse ("./t/data/xref_encoding_test.obo");
my $terms = $graph->term_query({name=>"2,4,5-trichlorophenoxyacetic acid metabolic process"});
my $t = shift @$terms;
ok($t);
ok(1);
my @xrefs = ();
foreach my $xref (@{$t->dbxref_list}) {
    print $xref->as_str,"\n";
    push(@xrefs, $xref->as_str);
}
foreach my $xref (@{$t->definition_dbxref_list}) {
    print $xref->as_str,"\n";
    push(@xrefs, $xref->as_str);
}
ok(@xrefs==2);
ok($xrefs[0] eq $xrefs[1]);
ok($xrefs[0] eq 'UM-BBD_pathwayID:2,4,5-t');
