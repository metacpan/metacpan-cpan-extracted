use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Files;
use obogaf::parser;

## input files and variable
my $goedges = "t/data/test_gobasic_edges.txt"; 
my $fakedge = "t/data/test_GOBASIC_edges.txt";
my $domain  =  "biological_process";

## define variables
my ($gores, $fh);

## build $goedges
my $obofile = "t/data/test_gobasic.obo";
$gores= obogaf::parser::build_edges($obofile);
open $fh, ">", $goedges; 
print $fh "${$gores}";
close $fh;

## test read or die
lives_ok(  sub { my $file = obogaf::parser::build_subonto($goedges, $domain) }, 'file opened' );
dies_ok (  sub { my $file = obogaf::parser::build_subonto($fakedge, $domain) }, 'die: wrong file name');

## test normal case
$gores= obogaf::parser::build_subonto($goedges, $domain);
my $gobp= "t/data/test_gobasic_edgesBP.txt"; 
open $fh, ">", $gobp; 
print $fh "${$gores}";
close $fh;
file_ok($gobp,  "GO:0018108\tGO:0007260\tpeptidyl-tyrosine phosphorylation\ttyrosine phosphorylation of STAT protein\tis-a\nGO:0007259\tGO:0007260\treceptor signaling pathway via JAK-STAT\ttyrosine phosphorylation of STAT protein\tpart-of\n", "test that build_subonto works");

## test dead and special case 
my $gobp_header= "t/data/test_gobasic_edges_header.txt";
open $fh, ">", $gobp_header;
open FH, "<", $goedges;
while(<FH>){
    if($.<2){print $fh "!header\n"}
    my @vals= split(/\t/,$_);
    print $fh join("\t", @vals[1..$#vals]);
} 
close FH;
close $fh;
dies_ok ( sub { my $file = obogaf::parser::build_subonto($gobp_header, $domain) }, 'die: wrong column number');
file_ok($gobp_header, "!header\nGO:0018108\tGO:0007260\tpeptidyl-tyrosine phosphorylation\ttyrosine phosphorylation of STAT protein\tis-a\nGO:0007259\tGO:0007260\treceptor signaling pathway via JAK-STAT\ttyrosine phosphorylation of STAT protein\tpart-of\n", "test that build_subonto works");

done_testing();

