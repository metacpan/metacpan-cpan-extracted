#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 4 }   
use GO::TestHarness;
use GO::AppHandle;

# ----- REQUIREMENTS -----

# ------------------------


my $apph = get_readonly_apph();

my $acc = 'FBgn0000490';   # let's hope dpp keeps the same FBgn!!
my $gp = $apph->get_product({acc=>$acc});
my @syns = sort @{$gp->synonym_list};
stmt_note("$acc synonyms: @syns");
stmt_note("\n\n");
my $t = $apph->get_terms({product=>{acc=>$acc}});
stmt_note($t->[0]->acc);

my ($gp2) = grep {$_->acc eq $acc} map {$_->gene_product} @{$t->[0]->selected_association_list};
stmt_check($gp2);
use Data::Dumper;
stmt_note($gp2);
#print Dumper $gp2;
stmt_check($gp2->synonym_list);

# If $gp1 and $gp2 have the same symbol, they should have the same synonyms.

stmt_check($gp->symbol eq $gp2->symbol);
my @syns2 = sort @{$gp2->synonym_list};
stmt_note("re-fetched syns: @syns2");
stmt_ok("@syns" eq "@syns2");



