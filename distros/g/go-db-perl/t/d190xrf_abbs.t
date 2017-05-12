#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;
use Test;
BEGIN { plan tests => 5, todo => [] }
set_n_tests(5);

use GO::Parser;

 # Get args

create_test_database("go_slimtest");
my $apph = getapph() || die;

my $parser = new GO::Parser ({format=>'xrf_abbs',
                              handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);

ok(1);
$parser->parse ("./t/data/GO.xrf_abbs");

my $dbs = $apph->get_dbs;
foreach (@$dbs) {
    printf "%s\n", $_->name;
}
ok (@$dbs > 1);
$dbs = $apph->get_dbs({name=>"ZFIN"});
ok(@$dbs==1);
my $db = shift @$dbs;
ok($db->fullname =~ /zebra/i);

$apph->disconnect;
#destroy_test_database();
ok(1);
