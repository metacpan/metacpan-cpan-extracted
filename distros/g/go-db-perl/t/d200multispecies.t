#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;

# REQUIREMENTS
#
# check that the path table - population and querying - works
#
# also check gpc while we are here

n_tests(3);


use GO::Parser;
use Data::Dumper;
 # Get args

create_test_database("go_species");
my $apph = getapph();

my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);

$parser->parse ("./t/data/goslim_generic.obo");
my @errs = $parser->parse_assocs("./t/data/gene_association.multitaxontest");
use Data::Dumper; print Dumper \@errs;
stmt_check(!@errs);
my $pl = $apph->get_products({term=>"GO:0004672"});
print "Products for protein kinase activity (4672) [NO SPECIES INTERACTION FILTER]:\n";
printf "%s %s\n", $_->symbol, $_->type foreach @$pl;
stmt_check(scalar(@$pl) > 1);
$apph->filters({qualifier_taxid=>9606});
$pl = $apph->get_products({term=>"GO:0004672"});
print "Products for protein kinase activity (4672) [WITH HUMAN INTERACTION TAXON FILTER]:\n";
printf "%s %s\n", $_->symbol, $_->type foreach @$pl;
stmt_check(scalar(@$pl) == 1);
