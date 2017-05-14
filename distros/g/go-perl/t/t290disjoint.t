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

# ----- REQUIREMENTS -----

# parser and model must handle disjoint_from

# ------------------------

my $parser = new GO::Parser ({format=>'obo',
			      handler=>'obj'});
my $graph = $parser->handler->g;
ok(1);

$parser->parse ("./t/data/regulation_of_somitogenesis.obo");

my $terms = $graph->get_all_nodes;
my $term = $graph->get_term("GO:0032501");
my $ok;
foreach (@{$term->disjoint_from_term_list}) {
    printf "%s\n", $_;
    $ok = 1 if $_ eq 'GO:0009987';
}
ok($ok);
