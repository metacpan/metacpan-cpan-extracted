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

create_test_database("go_path");
my $apph = getapph();

my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);

stmt_note('loading function');
$parser->handler->optimize_by_dtype('go_ont');
$parser->parse ("./t/data/baby-function.dat");
$apph->add_root;
stmt_note('loading assocs');
$parser->set_type('go_assoc');
$parser->handler->optimize_by_dtype('go_assoc');
$parser->acc2name_h($apph->acc2name_h);
my $a2n = $parser->acc2name_h;
stmt_check($parser->acc_not_found('xxx'));
stmt_check($a2n->{'GO:0003674'} eq 'molecular_function');
$parser->cache_errors;
$parser->parse("./t/data/err-fb-assocs.fb");
my @errs = $parser->errlist;
print $_->sxpr foreach @errs;
stmt_check(@errs == 1);
