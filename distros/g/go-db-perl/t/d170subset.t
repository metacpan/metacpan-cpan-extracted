#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;
use Test;
BEGIN { plan tests => 8, todo => [] }
set_n_tests(8);

use GO::Parser;

 # Get args

create_test_database("go_slimtest");
my $apph = getapph() || die;

my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);

ok(1);
$parser->parse ("./t/data/goslim_generic.obo");
$apph->add_root;
ok(1);

my $terms = $apph->get_terms({subset=>"goslim_plant"});
print "Search1:\n";
printf "  %s\n", $_->name foreach @$terms;
ok(@$terms > 0);

my $terms2 = $apph->get_terms({search=>"goslim_plant"});
print "Search2:\n";
printf "  %s\n", $_->name foreach @$terms2;
ok(@$terms == @$terms);

my $slims = $apph->get_terms({term_type=>"subset"});
print "Slims:\n";
printf "  %s\n", $_->name foreach @$slims;
ok(@$slims==5);

my $term = $apph->get_term({acc=>"GO:0005615"});
print "In:\n";
printf "  %s\n", $_ foreach @{$term->subset_list};
ok($term->in_subset('goslim_plant'));
ok(@{$term->subset_list} ==3);

# check synonyms - not related to subsets per se, but good to check anyway
$term = $apph->get_term({acc=>"GO:0004872"});
my $stypes = $term->synonym_type_list;
foreach (@$stypes) {
    print "Syns [$_]:\n";
    printf "  %s\n", $_ foreach @{$term->synonyms_by_type($_)};
}
ok(@{$term->synonyms_by_type('narrow')} ==5);
ok(@{$term->synonyms_by_type('related')} ==1);

$apph->disconnect;
#destroy_test_database();
ok(1);
