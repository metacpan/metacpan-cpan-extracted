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

n_tests(5);


use GO::Parser;
use Data::Dumper;
 # Get args

create_test_database("go_species");
my $apph = getapph();

my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);

$parser->parse ("./t/data/baby-function.dat");
my @errs = $parser->parse_assocs("./t/data/mini-fb-assocs.fb");
use Data::Dumper; print Dumper \@errs;
stmt_check(!@errs);
my $pl = $apph->get_products({term=>3677, deep=>1});
stmt_check(scalar(@$pl));
printf "%s %s\n", $_->symbol, $_->type foreach @$pl;

my $p = $apph->get_product({symbol=>'Zfh1'});
stmt_check($p->species->ncbi_taxa_id(), 7227);
stmt_note($p->type);
stmt_check($p->type, 'faketype');
stmt_ok;
