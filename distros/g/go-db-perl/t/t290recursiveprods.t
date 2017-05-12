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

# for any given term we want to be able to supply
# a list of associations for that term and any term below
# it. we want the associations to be attached to the term so
# we can provide a list like this:
# nucelotid binding // protein1
# nucelotid binding // protein2
# nucelotid binding // protein3
# DNA binding // protein4
# DNA binding // protein1
# etc
# so the best way to do this is with a term query;
# but for efficiency, we don't want any terms that have no
# associations
# ------------------------

my $apph = get_readonly_apph();
my $al = $apph->get_associations(-term=>{acc=>3677});
stmt_note(@$al);
if (!@$al) {
    warn "$0 needs updating; choose a better GO ID!";
}
my $tl = $apph->get_terms_with_associations({acc=>3677});
my $all_have = 1;
my $all_ok = 1;
my $n_a = 0;

my %ah = ();

my $n_ptypes = 0;
my %done_t = ();
foreach my $t (@$tl) {
    my $al = $t->association_list;
    $all_have = 0 unless @$al;
    if (!@$al) {
        printf(
               "NONE FOR %s %-20s\n",
               $t->public_acc,
               $t->name,
               );
    }
    foreach my $a (@$al) {
        if (! $t->public_acc) {
            print STDERR "NO ACC\n";
            $all_ok = 0;
        }
        if (! $t->name) {
            print STDERR "NO NAME\n";
            $all_ok = 0;
        }
        if (! $a->gene_product->symbol) {
            print STDERR "NO SYMBOL\n";
            $all_ok = 0;
        }
        $n_a++;
#        $ah{$t->public_acc.':'.$t->name.':'.$a->gene_product->symbol} = 1;
        $ah{$a->id} = 1;
        printf(
               "%s %s %s %s\n",
               $t->public_acc,
               $t->name,
               $a->gene_product->symbol,
               $a->gene_product->type,
              );
        $n_ptypes++ if $a->gene_product->type;
    }
    if ($done_t{$t->id}) {
        warn "duplicate term";
    }
    $done_t{$t->id} = 1;
}
stmt_check($all_have);
stmt_check($all_ok);
stmt_check($n_ptypes);
stmt_note($n_a);
stmt_note(scalar(@$al));
stmt_note(scalar(keys %ah));
#delete $ah{$_->id} foreach @$al;
#if (keys %ah) {
#    print "remaing...\n";
#    print "$_\n", keys %ah;
#}
stmt_check(scalar(keys %ah) == scalar(@$al) && $n_a == scalar(@$al));
