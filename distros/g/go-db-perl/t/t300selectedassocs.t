#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 1 }
use GO::TestHarness;
use GO::AppHandle;

# ----- REQUIREMENTS -----

# when retrieving terms by constraining on product, the default
# behaviour is to adorn the terms with the products used as a 
# constraint.
#
# rationale: say we have a bunch of proteins that we have clustered
# eg via expression data or by sequence analysis; we want to see
# how that cluster jives with the GO categorizations.
# we can just query terms by the product list and show how the
# products are adorned on the tree

# ------------------------

my $apph = get_readonly_apph();
my $pl = $apph->get_products({symbol=>"ORC*"});
my $ok = 1;
foreach my $p (@$pl) {
    printf("PRODUCT: %s %s:%s\n", $p->symbol, $p->speciesdb, $p->acc);
    my $tl = $apph->get_terms({product=>$p});
    foreach my $t (@$tl) {
        my $al = $t->selected_association_list;
        foreach my $a (@$al) {
            if ($a->gene_product->id != $p->id) {
                $ok = 0;
            }
            printf(
               "  %s %20s %s %s %s\n",
                   $t->public_acc,
                   $t->name,
                   $a->gene_product->symbol,
                   join("; ", map {$_->code} @{$a->evidence_list}),
                  );
        }
    }
}
stmt_check($ok);
