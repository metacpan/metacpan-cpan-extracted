#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 2, todo => [1] }   
use GO::TestHarness;
use GO::AppHandle;

# ----- REQUIREMENTS -----

# ------------------------

#n_tests(7);

#stmt_ok;
#exit 0;

my $apph = get_readonly_apph();
my $node = $apph->get_term({acc=>7585});
printf "node=$node\n";

# default sort seems to be by datasource and gene_product

my $ass_list;

eval {
    $ass_list = $node->association_list(-sort_by=>'ev_code');
    ok($ass_list->[0]->evidience_list->[0]->code eq 'IGI');
};
if ($@) {
    print $@;
    ok(0);
}

eval {
    $ass_list = $node->association_list(-sort_by=>'gene_product');
    my $bad = 0;
    for (my $i=1; $i<@$ass_list; $i++) {
        $bad =1 if
          $ass_list->[$i-1]->gene_product->symbol gt $ass_list->[$i]->gene_product->symbol;
    }
    ok(!$bad);
};
if ($@) {
    print $@;
    ok(0);
}


