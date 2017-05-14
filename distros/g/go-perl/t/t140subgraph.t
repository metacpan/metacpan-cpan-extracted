#!/usr/local/bin/perl -w

use lib '.';
BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 1;
}
# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use strict;
use GO::Parser;

# ----- REQUIREMENTS -----

# ------------------------

my $parser = new GO::Parser ({format=>'go_ont'});
my $graph = $parser->parse_to_graph("./t/data/test-function.dat");
my $subgraph = $graph->subgraph({acc=>'GO:0003700'});
$subgraph->to_text_output;
ok($subgraph->term_count == 5);
