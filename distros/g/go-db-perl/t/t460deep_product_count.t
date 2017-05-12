#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;

n_tests(2);

my $apph = get_readonly_apph();
stmt_ok;

my $term_name="eye morphogenesis";

my $i=0;

my  $gpl_count = $apph->get_deep_product_count({term=>{name=>$term_name},speciesdb=>"FB"});
#my $gpl_count = $apph->get_deep_product_count({term=>$term_name});

stmt_note("count: ".$gpl_count);

my $gpl=$apph->get_deep_products({term=>$term_name,speciesdb=>"FB"});

stmt_note("num: ".scalar(@$gpl));
stmt_note($_->symbol) foreach @$gpl;
stmt_check(@$gpl == $gpl_count);
