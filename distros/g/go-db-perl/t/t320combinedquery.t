#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 7 }
use GO::TestHarness;
use GO::AppHandle;

# ----- REQUIREMENTS -----

# we want to be able to do combined queries;
# eg fetch me every product that is
# transmembrane receptor and membrane

# ------------------------

#my $acc1 = 'GO:0006413'; # translation initiation
#my $acc2 = 'GO:0005852'; # eukaryotic translation initiation factor 3 complex
my $acc1 = 'GO:0006413'; # translation initiation
my $acc2 = 'GO:0045182'; # translation regulator activity
my $acc3 = 'GO:0044444'; # cytoplasmic part

my $apph = get_readonly_apph(@ARGV);
$apph->filters->{speciesdbs} = 'FB';

my $pl = $apph->get_deep_products({terms=>[$acc1,$acc2], operator=>"and"});
stmt_note("Intersection: $acc1 + $acc2");
foreach my $p (@$pl) {
    stmt_note($p->symbol);
}
stmt_check(scalar(@$pl));

stmt_note("Query: $acc1");
my $pl1 = $apph->get_deep_products({terms=>[$acc1]});
stmt_note($_->symbol) foreach @$pl1;;
my %ph1 = map {$_->id => $_ } @$pl1;
stmt_check(@$pl1 > @$pl); # intersection should contain same-as or less

stmt_note("Query: $acc2");
my $pl2 = $apph->get_deep_products({terms=>[$acc2]});
stmt_note($_->symbol) foreach @$pl2;;
my %ph2 = map {$_->id => $_ } @$pl2;
stmt_check(@$pl2 > @$pl); # intersection should contain same-as or less

# intersection should contain nothing that is not in union
stmt_check(!
           grep {
               !($ph1{$_->id} && $ph2{$_->id})
           } @$pl
          );

$pl = $apph->get_deep_products({terms=>[$acc1,$acc2,$acc3], operator=>"and"});
stmt_note("Intersection: $acc1 + $acc2 + $acc3");
foreach my $p (@$pl) {
    stmt_note($p->symbol);
}
stmt_check(scalar(@$pl));

stmt_note("Query: $acc3");
my $pl3 = $apph->get_deep_products({terms=>[$acc3]});
stmt_note($_->symbol) foreach @$pl3;
my %ph3 = map {$_->id => $_ } @$pl3;
stmt_check(@$pl3 > @$pl); # intersection should contain same-as or less

# intersection should contain nothing that is not in union
stmt_check(!
           grep {
               !($ph1{$_->id} && $ph2{$_->id} && $ph3{$_->id})
           } @$pl
          );

stmt_note("Query: roots");
my $c = $apph->get_deep_product_count({terms=>[{name=>'biological_process'},{name=>'cellular_component'}], operator=>"and"});
stmt_note($c);

stmt_note("Query: roots, no filters");
$apph->filters->{speciesdbs} = undef;
$apph->filters->{evcodes} = [];
my $c2 = $apph->get_deep_product_count({terms=>[{name=>'biological_process'},{name=>'cellular_component'}], operator=>"and"});
stmt_note($c2);
