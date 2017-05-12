#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;

n_tests(2);

my $apph = get_readonly_apph();
stmt_ok;

# lets check we got stuff

$apph->filters({speciesdb=>"SGD"});
my @test_list = ();
#my $h = $apph->get_enriched_term_hash([ map { {synonym=>$_} } qw(YNL116W YNL030W) ]);
push @test_list, @{$apph->get_products({synonym=>"YNL116W"})};
push @test_list, @{$apph->get_products({synonym=>"YNL030W"})};
my $h = $apph->get_enriched_term_hash(\@test_list);

$apph->disconnect;
stmt_ok;

