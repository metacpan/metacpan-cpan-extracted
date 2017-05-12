#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;
use GO::AppHandle;

n_tests(2);
my $apph = get_readonly_apph;
stmt_ok;
my $to_depth = 2;

my $acc= 7049;
my @gl = ();
my $not_ok = 0;
foreach my $depth (0..$to_depth) {
    my $g = $apph->get_node_graph(-acc=>$acc,
                                  -depth=>$depth);
    $gl[$depth] = $g;
    if ($depth > 0 && $gl[$depth-1]) {
        my $pg = $gl[$depth-1];
        foreach my $t (@ {$pg->get_all_nodes} ) {
            unless ($pg->get_term($t->acc)) {
                $not_ok = 1;
                stmt_note($t->acc." not found at depth $depth");
            }
        }
    }
}

stmt_check(!$not_ok);
$apph->disconnect;
