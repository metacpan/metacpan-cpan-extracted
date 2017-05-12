#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;

n_tests(9);


use GO::Parser;

 # Get args

create_test_database("go_xreftest");
my $apph = getapph();

stmt_ok;
my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);
$parser->parse ("./t/data/xrefs-function.dat");

stmt_ok;

# lets check we got stuff

my $tl = $apph->get_terms({dbxref_dbname=>"MetaCyc"});
stmt_note(@$tl);
stmt_check(@$tl == 2);
$tl = $apph->get_terms({acc=>19381, dbxref_dbname=>"MetaCyc"});
my $t = $tl->[0];
stmt_check($t->dbxref_list);
stmt_note($t->dbxref_list->[0]->as_str);
stmt_check($t->dbxref_list->[0]->as_str eq "MetaCyc:P141-PWY");

$t = $apph->get_term({acc=>9628});
stmt_check($t->dbxref_list->[0]->as_str eq "MetaCyc:A-THIS-IS-MADE-UP");
stmt_check($t->dbxref_list->[1]->as_str eq "MetaCyc:B-THIS-IS-ALSO-MADE-UP");
$t = $apph->get_term({acc=>9605});
use Data::Dumper;
print Dumper $t;
stmt_check($t->dbxref_list->[0]->as_str eq "UM-MADE_UP:2,4-d");
$apph->disconnect;
destroy_test_database();
stmt_ok;
