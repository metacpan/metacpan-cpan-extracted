#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 5 }
use GO::TestHarness;
use GO::AppHandle;

# ----- REQUIREMENTS -----

# ------------------------

#n_tests(7);

#stmt_ok;
#exit 0;

my $apph = get_readonly_apph();
$apph->filters->{speciesdb} = ['sgd'];
my $node = $apph->get_term({acc=>3677});

stmt_ok;

my $test = 1;
my $al = $node->association_list;
foreach my $a (@$al) {
    if (lc($a->gene_product->speciesdb) ne 'sgd') {
        stmt_note("uh-oh: ".$a->gene_product->speciesdb);
        $test = 0;
    }
}

stmt_check( $test );

my $pl = $apph->get_products({deep=>1, term=>$node});
map {stmt_note($_->symbol)} @$pl;

my $pc = $node->n_deep_products;
stmt_note(scalar(@$pl));
stmt_note("pc (sgd) = $pc");
stmt_check($pc);
#stmt_check($pc == scalar(@$pl));

foreach my $p (@$pl) {
  if (lc($p->speciesdb) ne 'sgd') {
    $test = 0;
  }
}
stmt_check( $test );

$apph->filters->{speciesdb} = ['!sgd'];
my $pc2 = $node->n_deep_products("recount");
stmt_note("pc2 (filter !sgd) = $pc2");
my $pl2 = $apph->get_products({deep=>1, term=>$node});
#stmt_check($pc2 == scalar(@$pl2));

delete $apph->filters->{speciesdb};
my $pc3 = $node->n_deep_products("recount");
stmt_note("pc3 (no filter) = $pc3");
stmt_check($pc + $pc2 == $pc3);
my $pl3 = $apph->get_products({deep=>1, term=>$node});
#stmt_check($pc3 == scalar(@$pl3));
stmt_note(scalar(@$pl3));
