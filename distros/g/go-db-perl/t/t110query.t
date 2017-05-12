#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;
use GO::AppHandle;
 
n_tests(3);
my $apph = get_readonly_apph;
stmt_ok;

$apph->filters({speciesdb=>"FB"});

my $tl =
   $apph->get_terms({products=>[qw(Abl abs ac)]});

stmt_note(scalar(@$tl));

my $tl2 =
   $apph->get_terms({product_accs=>[qw(FBgn0000017 FBgn0015331 FBgn0000022)]});

stmt_note(scalar(@$tl2));
stmt_check(scalar(@$tl2) == scalar(@$tl));

$tl =
   $apph->get_terms({dbxref_dbname=>"genprotec"});

stmt_note(scalar(@$tl));

my $graph = $apph->get_graph_by_terms($tl, 0, {terms=>{names=>-1}});
stmt_note(scalar(@$tl));
stmt_note($graph->node_count);
stmt_check($graph->node_count > 200);
#$graph->to_text_output;






