#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 2 }   
use GO::TestHarness;
use GO::AppHandle;

# ----- REQUIREMENTS -----

# ------------------------


my $apph = get_readonly_apph();

my $gp = 'Neurl';

my $products = $apph->get_products({'symbol'=>'Neurl'});
stmt_check(scalar(@$products) == 1);

my $terms = $apph->get_terms({'products'=>@$products});
stmt_note($terms->[0]->acc);
my ($term) = grep {$_->acc eq 'GO:0007595'} @$terms;
stmt_note($term->acc);
# If you select terms with only one gp, there should
# be only one selected association, yes?
stmt_note(scalar(@{$term->selected_association_list}));
stmt_note($_->id) foreach @{$term->selected_association_list};
stmt_check(scalar(@{$term->selected_association_list}) == 1);
