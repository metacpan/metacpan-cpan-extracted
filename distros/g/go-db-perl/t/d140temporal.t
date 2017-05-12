#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;
use Test;

n_tests(6);


use GO::Parser;
use GO::SqlWrapper qw(:all);

create_test_database("go_mini");
# Get args

my $apph = getapph();
my $dbh = $apph->dbh;

my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);
$parser->handler->optimize_by_dtype('obo');
$parser->parse ("./t/data/temporal.obo");
$parser->show_messages;
my $terms = $apph->get_terms;
my $roots = $apph->get_root_terms;
printf "root: %s\n", $_->acc foreach @$roots;
stmt_check(scalar(@$roots),3);
$apph->add_root;
$roots = $apph->get_root_terms;
printf "root: %s\n", $_->acc foreach @$roots;
stmt_check(scalar(@$roots),1);
my $root = shift @$roots;
my $g = $apph->get_graph($root->acc);
#print $g->to_text_output;
my $n_terms = $g->term_count;
stmt_note("Filling path");
$apph->fill_path_table;
$terms = $apph->get_terms;
$roots = $apph->get_root_terms;
printf "[2]root: %s\n", $_->acc foreach @$roots;
stmt_check(scalar(@$roots),1);
my $root2 = shift @$roots;
stmt_check($root->acc, $root2->acc);
$g = $apph->get_graph($root2->acc);
print $g->to_text_output;
my $n_terms2 = $g->term_count;
stmt_note($n_terms);
stmt_check($n_terms, $n_terms2);
stmt_check($n_terms, 132);
# to check
