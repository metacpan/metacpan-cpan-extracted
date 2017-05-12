#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;
use Test;
BEGIN { plan tests => 4, todo => [] }
set_n_tests(4);

use GO::Parser;

 # Get args

create_test_database("go_obstest");
my $apph = getapph() || die;

my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);

ok(1);
$parser->parse ("./t/data/obsolete.obo");
$apph->add_root;
ok(1);

my $terms = $apph->get_terms({search=>"*"});
print "Search1:\n";
printf "  %s\n", $_->name foreach @$terms;
ok(@$terms > 0);

# TODO: test reading of consider/replaced_by

$apph->disconnect;
#destroy_test_database();
ok(1);
