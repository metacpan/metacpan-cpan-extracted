#!/usr/local/bin/perl -w

####
#### How to run separately:
#### reset; perl -I /users/sjcarbon/local/src/cvs/go-dev/go-perl -I
#### /users/sjcarbon/local -I /users/sjcarbon/tmp/DBIx-DBStag-0.09
#### ./t/d270annotation_double_taxon.t
####
#### All tests must be run from the software directory;
#### make sure we are getting the modules from here:
####

use lib '.';
use strict;
use GO::TestHarness;
use GO::Parser;
use Data::Dumper;

###
### REQUIREMENTS
###
### Check that the dual taxon stuff is behaving properly.
###

n_tests(8);

###
### Test 1: Does it load. Try loading the PAMGO stuff.
###

create_test_database("go_dual_taxon");
my $apph = getapph();
my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);
$parser->parse ("./t/data/go-dual-test.obo");
my @errs = $parser->parse_assocs("./t/data/gene_association.pamgo.test");
stmt_check(1);

###
### Test 2: Double is ok for load.
###

my $dual_term = $apph->get_term_by_acc("GO:0001907");
my $dual_assoc_l = $dual_term->get_all_associations;
stmt_check(scalar(@$dual_assoc_l), 17);

###
### Test 3-8: Filtering properly changes doubles and singles.
###

## Base.
print "GO:0019899:\n";
my $pls = $apph->get_products({term=>"GO:0019899"});
printf "%s %s\n", $_->symbol, $_->type foreach @$pls;
stmt_check(scalar(@$pls), 1);

print "GO:0001907:\n";
my $pld = $apph->get_products({term=>"GO:0001907"});
printf "%s %s\n", $_->symbol, $_->type foreach @$pld;
stmt_check(scalar(@$pld), 14);

## A secondary for three.
$apph->filters({qualifier_taxid=>4096});

print "GO:0019899:\n";
$pls = $apph->get_products({term=>"GO:0019899"});
printf "%s %s\n", $_->symbol, $_->type foreach @$pls;
stmt_check(scalar(@$pls), 0);

print "GO:0001907:\n";
$pld = $apph->get_products({term=>"GO:0001907"});
printf "%s %s\n", $_->symbol, $_->type foreach @$pld;
stmt_check(scalar(@$pld), 3);

## Not a secondary.
$apph->filters({});
$apph->filters({qualifier_taxid=>67593});

print "GO:0019899:\n";
$pls = $apph->get_products({term=>"GO:0019899"});
printf "%s %s\n", $_->symbol, $_->type foreach @$pls;
stmt_check(scalar(@$pls), 0);

print "GO:0001907:\n";
$pld = $apph->get_products({term=>"GO:0001907"});
printf "%s %s\n", $_->symbol, $_->type foreach @$pld;
stmt_check(scalar(@$pld), 0);
