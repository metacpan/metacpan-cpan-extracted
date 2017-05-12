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

n_tests(1);


use GO::Parser;
use Data::Dumper;
 # Get args

create_test_database("go_species");
my $apph = getapph();

my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);

$parser->parse ("./t/data/goslim_generic.obo");
my @errs = $parser->parse_assocs("./t/data/gene_association.test_properties");
#todo: tests for API
stmt_check(1);
