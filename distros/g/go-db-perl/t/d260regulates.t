#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;
use Test;

n_tests(9);


use GO::Parser;
use GO::SqlWrapper qw(:all);

create_test_database("go_mini");
# Get args

my $apph = getapph();
my $dbh = $apph->dbh;

stmt_ok;
my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);
$parser->handler->optimize_by_dtype('obo');
stmt_ok;
$parser->parse ("./t/data/regulation_test.obo");
$parser->show_messages;
stmt_ok;

$apph->add_root;
$apph->fill_path_table;

my $graph = $apph->get_graph(-acc=>"GO:0050790");
print $graph->to_text_output;

my $ps = $graph->get_parent_terms("GO:0050790");

foreach my $t (@$ps) {
    printf "P: %s %s\n", $t->acc, $t->name;
}

stmt_ok(@$ps == 2);
stmt_ok(grep {$_->acc eq 'GO:0003824'} @$ps);
stmt_ok(grep {$_->acc eq 'GO:0065009'} @$ps);

$ps = $graph->get_parent_accs_by_type("GO:0050790","regulates");
foreach my $acc (@$ps) {
    printf "P: $acc\n";
}
stmt_ok(@$ps == 1);

$ps = $graph->get_recursive_parent_terms("GO:0050790");
foreach my $t (@$ps) {
    printf "P: %s %s\n", $t->acc, $t->name;
}
stmt_ok(@$ps > 2);


$apph->disconnect;
stmt_ok;
