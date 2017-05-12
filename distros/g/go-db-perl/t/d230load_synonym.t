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

create_test_database("go_synonym_test");
my $apph = getapph() || die;

my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);

$parser->parse ("./t/data/test_synonym.obo");
ok(1);

my $term = $apph->get_term({acc=>"X:1"});
my $stypes = $term->synonym_type_list;
foreach (@$stypes) {
    print "Syns [$_]:\n";
    printf "  %s\n", $_ foreach @{$term->synonyms_by_type($_)};
}
ok(scalar @{$term->synonyms_by_type("exact")} == 2);
ok(scalar @{$term->synonyms_by_type("related")} == 1);

# TODO: test actual categories..

$apph->disconnect;
#destroy_test_database();
ok(1);
