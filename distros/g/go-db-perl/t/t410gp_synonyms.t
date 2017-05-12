#!/usr/local/bin/perl -w

#!/usr/bin/perl

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 2 }
use GO::TestHarness;
use GO::AppHandle;
use GO::Model::TreeIterator;

# ----- REQUIREMENTS -----

# Comments are in the defs file, they have a line
# beneath the definition references that start with
# comment:

# We should be able to search on these as well as
# display them.

# ------------------------

my @array;

my $apph = get_readonly_apph;

## This reference should be a definition
## reference, not a general reference.

my $product = $apph->get_products({'synonym'=>'YMR056C'});

my $syns = $product->[0]->synonym_list;
stmt_check(grep { $_ eq 'YMR056C' } @$syns);

my $terms = $apph->get_terms({'products'=>$product});
my @psyns =
  map {
      map {
	  @{$_->gene_product->synonym_list || []}
      } @{$_->selected_association_list}
  } @$terms;
stmt_check(grep {$_ eq 'YMR056C'} @psyns);
 
