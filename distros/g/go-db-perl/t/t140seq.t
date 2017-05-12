#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;
use GO::AppHandle;
use GO::IO::Blast;

#use GO::Model::Graph;
# ----- REQUIREMENTS -----

# ------------------------

n_tests(2);
my $apph = get_readonly_apph;
stmt_ok;

$apph->filters({evcodes=>["!IEA", "!ISS"]});
my $product = $apph->get_product({symbol=>"ORC4", speciesdb=>"SGD"});
my $terms = $apph->get_terms({product=>$product});
my $term = $terms->[0];
printf "%s\n", $term->as_str;
foreach my $prod (@{$term->product_list}) {
    if (@{$prod->seq_list || []}) {
        print $prod->seq_list->[0]->seq;
	print "\n";
    }
}
stmt_ok;
