#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 11 }
use GO::TestHarness;
use GO::AppHandle;

# ----- REQUIREMENTS -----

# ------------------------

#n_tests(7);

#stmt_ok;
#exit 0;

my $apph = get_readonly_apph();
$apph->filters({speciesdb=>['sgd']});
my $term_list = $apph->get_terms({product=>'cap*'});

stmt_note( join("; ", map {$_->name } @$term_list) );

stmt_check(scalar(@$term_list));
stmt_ok;

my $test = 1;

foreach my $term(@$term_list) {
  foreach my $ass (@{$term->selected_association_list}) {
    if (lc($ass->gene_product->speciesdb) ne 'sgd') {
      $test = 0;
    }
  }
}
# check that all non SGDs were filtered
stmt_check( $test );

$apph->filters({speciesdb=>['sgd', 'fb']});
$term_list = $apph->get_terms({product=>'cap*'});

stmt_note( join("; ", map {$_->name } @$term_list));
stmt_check(scalar(@$term_list));
stmt_ok;

$test = 1;

my $set = {};
foreach my $term(@$term_list) {
    printf "%s %s\n", $term->name, $term->public_acc;
    $set->{$term->id} = $term;
  foreach my $ass (@{$term->selected_association_list}) {
    if (!grep {$ass->gene_product->speciesdb eq $_} ('SGD', 'FB')) {
      $test = 0;
    }
  }
}
# check that all non SGDs or FBs were filtered
stmt_check( $test );


# check that specifying a species constraint overrides filters
$term_list = $apph->get_terms({product=>'cap*', speciesdb=>['!sgd', '!fb']});
foreach my $term(@$term_list) {
    printf "%s %s\n", $term->name, $term->public_acc;
    $set->{$term->id} = $term;
}
my $ntc = scalar(@$term_list);
# speciesdbs are mutually exclusive
$apph->filters({});
$term_list = $apph->get_terms({product=>'cap*'});
$test = 1;
foreach my $term(@$term_list) {
    if (!$set->{$term->id}) {
        $test = 0;
    }
}
stmt_check($test && scalar(keys %$set) == scalar(@$term_list));

$term_list = $apph->get_terms({product=>'cap*', speciesdb=>['sgd'], evcodes=>['IDA']});
foreach my $term(@$term_list) {
    printf "%s %s\n", $term->name, $term->public_acc;
}
$term_list = $apph->get_terms({product=>'cap*', speciesdb=>['sgd'], evcodes=>['!IDA']});
foreach my $term(@$term_list) {
    printf "%s %s\n", $term->name, $term->public_acc;
}
stmt_ok;

# non-existent species
$term_list = $apph->get_terms({product=>'dpp', taxid=>-5});
stmt_check(!@$term_list);

# Dmel
$term_list = $apph->get_terms({product=>'dpp', taxid=>7227});
foreach my $term(@$term_list) {
    printf "7277: %s %s\n", $term->name, $term->public_acc;
}
stmt_check(scalar(@$term_list));
# Human
my $p_list = $apph->get_products({term=>{name=>"carbohydrate metabolism"}, taxid=>9606});
foreach my $p (@$p_list) {
    printf "9606: %s %s\n", $p->symbol, $p->species->ncbi_taxa_id;
}
stmt_check(scalar(!grep {$_->species->ncbi_taxa_id != 9606} @$p_list));
