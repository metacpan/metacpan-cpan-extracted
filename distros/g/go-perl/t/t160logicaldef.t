#!/usr/local/bin/perl -w

use lib '.';
BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 5;
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
$parser->parse ("./t/data/llm.obo");

my $t = $graph->get_term_by_name("larval locomotory behavior");
printf "ns: %s\n", $t->namespace;
ok ($t->namespace eq 'biological_process');

my $ldef = $t->logical_definition;
printf "ldef ns: %s\n", $ldef->namespace;
ok ($ldef->namespace eq 'foo');
foreach (@{$ldef->intersection_list}) {
    print "@$_\n";
}
my $gacc = $ldef->generic_term_acc;
print "$gacc\n";
ok($gacc eq 'GO:0007626');
my $diff = $ldef->differentia->[0];
ok("@$diff" eq "OBOL:during FBdv:00005336");

