#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;
use Test;
BEGIN { plan tests => 5, todo => [4] }
set_n_tests(5);

use GO::Parser;

# Get args

create_test_database("go_graphtest");
my $apph = getapph() || die;

my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);

ok(1);;
$parser->parse ("./t/data/baby-function.dat");

ok(1);;

$b = $apph->get_graph("GO:0003700", 0);
ok ($b->n_children("GO:0003700") == 6);

my $terms = $apph->get_terms({acc=>[3700, 3701, 3711]});
stmt_note(scalar(@$terms));
my $graph = $apph->get_graph_by_terms($terms, 1);
stmt_note($graph->n_children("GO:0003700"));
$graph->to_text_output;
ok ($graph->n_children("GO:0003700") == 6);


$apph->disconnect;
destroy_test_database();
ok(1);;
