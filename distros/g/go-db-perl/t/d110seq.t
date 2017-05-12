#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;
use GO::AppHandle;

#use GO::Model::Graph;
# ----- REQUIREMENTS -----

# ------------------------

n_tests(2);
my $apph = get_readonly_apph;
stmt_ok;

my $prods = $apph->get_products({term=>"GO:0004386",
				symbol=>"abs", speciesdb=>"FB"});
my $good = 1;
foreach my $prod (@$prods) {
    my $seq = $prod->seq_list->[0];
    if ($seq) {
        printf "DB:%s\n", $_->xref_dbname foreach @{$seq->xref_list};
	my ($spxr) = 
          grep {
              $_->xref_dbname eq 'SPTR' ||
              lc($_->xref_dbname) eq 'uniprot'
          } @{$seq->xref_list};
	my $prod2 = $apph->get_product({seq_acc=>$spxr->xref_key});
	stmt_note($prod2->symbol);
	$good &&= ($prod->symbol eq $prod2->symbol);
	my $prod3 = $apph->get_product({seq_name=>$seq->display_id});
	stmt_note($prod3->symbol);
	$good &&= ($prod->symbol eq $prod3->symbol);
    }
}
stmt_check($good);
