use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Files;
use obogaf::parser;

## input files
my $obofile = "t/data/test_gobasic.obo";
my $fakeobo = "t/data/test_GObasic.obo";
my $fakeext = "t/data/test_gobasic.OBO";

## test read or die
lives_ok( sub { my $file = obogaf::parser::build_edges($obofile) }, 'file opened' );
dies_ok ( sub { my $file = obogaf::parser::build_edges($fakeobo) }, 'die: wrong file name');
dies_ok ( sub { my $file = obogaf::parser::build_edges($fakeext) }, 'die: no obo extension');

## my out file
my $fh;

## test standard go.obo file
my $gores   = obogaf::parser::build_edges($obofile);
my $goedges = "t/data/test_gobasic_edges.txt"; 
open $fh, ">", $goedges; 
print $fh "${$gores}";
close $fh;
file_ok($goedges, "biological_process\tGO:0018108\tGO:0007260\tpeptidyl-tyrosine phosphorylation\ttyrosine phosphorylation of STAT protein\tis-a\nbiological_process\tGO:0007259\tGO:0007260\treceptor signaling pathway via JAK-STAT\ttyrosine phosphorylation of STAT protein\tpart-of\n", "test that build_edges works");

## to test branch 'namespace not defined' we must hack the obo file first..
my $gobo_hack= "t/data/test_gobasic_no_namespace.obo";
open $fh, ">", $gobo_hack; 
open FH, "<", $obofile;
while(<FH>){
    next if /^namespace:/;
    print $fh $_;
}
close FH;
close $fh;

## test obo file without namespace
my $gores_hack   = obogaf::parser::build_edges($gobo_hack);
my $goedges_hack = "t/data/test_gobasic_edges_no_namespace.txt"; 
open $fh, ">", $goedges_hack; 
print $fh "${$gores_hack}";
close $fh;
file_ok($goedges_hack, "GO:0018108\tGO:0007260\tpeptidyl-tyrosine phosphorylation\ttyrosine phosphorylation of STAT protein\tis-a\nGO:0007259\tGO:0007260\treceptor signaling pathway via JAK-STAT\ttyrosine phosphorylation of STAT protein\tpart-of\n", "test that build_edges works");


done_testing();

