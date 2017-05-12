#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;

# REQUIREMENTS

n_tests(7);

use GO::Parser;
use Data::Dumper;
 # Get args

create_test_database;
my $apph = getapph();

my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);
#$parser->handler->add_root('root');
$parser->parse_file("./t/data/go-truncated.obo");
$apph->add_root;
stmt_note('getting root term');
my $root = $apph->get_root_term;
stmt_note("root = ".$root->acc);
my $children = $apph->get_child_terms($root);
stmt_note($_->name) foreach @$children;
#$apph->fill_path_table;
stmt_check(@$children == 2);  # obs and process

my $term = $apph->get_term({acc=>'GO:0050983'});
my $syns = $term->synonym_list;
stmt_note("syns = @$syns");
stmt_check(@$syns == 3);

my $dbxrefs = $term->dbxref_list || [];
stmt_note("dbxref=".$_->as_str) foreach @$dbxrefs;
stmt_check(@$dbxrefs == 2);

my $def = $term->definition;
stmt_note("def=$def");
stmt_check($def);

$dbxrefs = $term->definition_dbxref_list || [];
stmt_note("dbxref=".$_->as_str) foreach @$dbxrefs;
stmt_check(@$dbxrefs == 1);

my $cmt = $term->comment;
stmt_note("cmt=$cmt");
stmt_check($cmt);

my $exsyns = $term->synonyms_by_type('exact') || [];
stmt_note("exsyns=@$exsyns;;");

my $term = $apph->get_term({acc=>'GO:0004431'});
$exsyns = $term->synonyms_by_type('exact');
stmt_note("exsyns=@$exsyns;;");
stmt_check(@$exsyns==1);
