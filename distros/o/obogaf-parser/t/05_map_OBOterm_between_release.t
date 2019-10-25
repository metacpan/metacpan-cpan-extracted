use strict;
use warnings;
use Test::More;
use Test::Files;
use Test::Exception;
use obogaf::parser;

# input files and variables
my $obofile = "t/data/test_gobasic.obo";
my $fakeobo = "t/data/test_GObasic.obo";
my $fakeext =  "t/data/test_gobasic.OBO";

my $gafold  = "t/data/test_goa_chicken_128.gaf";
my $zipgaf  = "t/data/test_goa_chicken_128.gaf.gz"; 
my $fakegaf = "t/data/test_GOA_chicken_128.gaf";
my $fakezip = "t/data/test_GOA_chicken_128.gaf.gz";

## define arguments
my $classindex= 4;
my ($res, $stat, $fh);

## test read or die
lives_ok( sub { my $file = obogaf::parser::map_OBOterm_between_release($obofile, $gafold, $classindex) }, 'obo file opened' );
lives_ok( sub { my $file = obogaf::parser::map_OBOterm_between_release($obofile, $zipgaf, $classindex) }, 'gaf file opened' );

dies_ok ( sub { my $file = obogaf::parser::map_OBOterm_between_release($fakeobo, $zipgaf, $classindex) }, 'die: wrong file name');
dies_ok ( sub { my $file = obogaf::parser::map_OBOterm_between_release($fakeext, $zipgaf, $classindex) }, 'die: wrong file name');

dies_ok ( sub { my $file = obogaf::parser::map_OBOterm_between_release($obofile, $fakezip, $classindex) }, 'die: wrong file name');
dies_ok ( sub { my $file = obogaf::parser::map_OBOterm_between_release($obofile, $fakegaf, $classindex) }, 'die: wrong file name');

## test mapping 
($res, $stat)= obogaf::parser::map_OBOterm_between_release($obofile, $gafold, $classindex);
my $mapfile= "t/data/test_chicken_goa_mapped.txt"; 
open $fh, ">", $mapfile; 
print $fh "${$res}";
close $fh;
$res= ${$stat};

file_ok($mapfile, "UniProtKB\tE1C7Z1\tFER\t\tGO:0007260\tGO_REF:0000019\tIEA\tEnsembl:ENSP00000281092\tP\tTyrosine-protein kinase\tE1C7Z1_CHICK|FER\tprotein\ttaxon:9031\t20160507\tEnsembl\nUniProtKB\tF1N9H9\tLIF\t\tGO:0007260\tGO_REF:0000019\tIEA\tEnsembl:ENSMUSP00000067066\tP\tUncharacterized protein\tF1N9H9_CHICK|LIF\tprotein\ttaxon:9031\t20160507\tEnsembl\nUniProtKB\tQ58IU6\tIL21\t\tGO:0007260\tGO_REF:0000019\tIEA\tEnsembl:ENSP00000264497\tP\tInterleukin\tQ58IU6_CHICK|IL21\tprotein\ttaxon:9031\t20160507\tEnsembl\nUniProtKB\tF1NZN5\tIL15\t\tGO:0007260\tGO_REF:0000019\tIEA\tEnsembl:ENSP00000296545\tP\tInterleukin\tF1NZN5_CHICK|IL15\tprotein\ttaxon:9031\t20160507\tEnsembl\nUniProtKB\tE1BXP7\tGCFC1\t\tGO:2000288\tGO_REF:0000019\tIEA\tEnsembl:ENSMUSP00000113835\tP\tUncharacterized protein\tE1BXP7_CHICK|GCFC1\tprotein\ttaxon:9031\t20160507\tEnsembl\nUniProtKB\tE1BXP7\tGCFC1\tNOT\tGO:0001078\tGO_REF:0000033\tIBA\tPANTHER:PTN000259148\tF\tUncharacterized protein\tE1BXP7_CHICK|GCFC1\tprotein\ttaxon:9031\t20141217\tGO_Central\n", "test that map_OBOterm_between_release works");

is($res, "#alt-id <tab> id\nGO:0042503\tGO:0007260\nGO:0042506\tGO:0007260\n\nTot. ontology terms:\t4\nTot. altID:\t7\nTot. altID seen:\t2\nTot. altID unseen:\t5\n", "test that ap_OBOterm_between_release stats are ok");

## add header in gaf file
my $gafheader= "t/data/test_goa_chicken_128_header.gaf";
open $fh, ">", $gafheader; 
open FH, "<", $gafold;
while(<FH>){
    if($.<2){print $fh "! header gaf file\n!\n";}
    print $fh $_;
}
close FH;
close $fh;

## test gaf file without header
($res, $stat)= obogaf::parser::map_OBOterm_between_release($obofile, $gafheader, $classindex);
my $mapfile_header= "t/data/test_chicken_goa_mapped_header.txt"; 
open $fh, ">", $mapfile_header; 
print $fh "${$res}";
close $fh;
my $header_res= ${$stat};

file_ok($mapfile_header, "! header gaf file\n!\nUniProtKB\tE1C7Z1\tFER\t\tGO:0007260\tGO_REF:0000019\tIEA\tEnsembl:ENSP00000281092\tP\tTyrosine-protein kinase\tE1C7Z1_CHICK|FER\tprotein\ttaxon:9031\t20160507\tEnsembl\nUniProtKB\tF1N9H9\tLIF\t\tGO:0007260\tGO_REF:0000019\tIEA\tEnsembl:ENSMUSP00000067066\tP\tUncharacterized protein\tF1N9H9_CHICK|LIF\tprotein\ttaxon:9031\t20160507\tEnsembl\nUniProtKB\tQ58IU6\tIL21\t\tGO:0007260\tGO_REF:0000019\tIEA\tEnsembl:ENSP00000264497\tP\tInterleukin\tQ58IU6_CHICK|IL21\tprotein\ttaxon:9031\t20160507\tEnsembl\nUniProtKB\tF1NZN5\tIL15\t\tGO:0007260\tGO_REF:0000019\tIEA\tEnsembl:ENSP00000296545\tP\tInterleukin\tF1NZN5_CHICK|IL15\tprotein\ttaxon:9031\t20160507\tEnsembl\nUniProtKB\tE1BXP7\tGCFC1\t\tGO:2000288\tGO_REF:0000019\tIEA\tEnsembl:ENSMUSP00000113835\tP\tUncharacterized protein\tE1BXP7_CHICK|GCFC1\tprotein\ttaxon:9031\t20160507\tEnsembl\nUniProtKB\tE1BXP7\tGCFC1\tNOT\tGO:0001078\tGO_REF:0000033\tIBA\tPANTHER:PTN000259148\tF\tUncharacterized protein\tE1BXP7_CHICK|GCFC1\tprotein\ttaxon:9031\t20141217\tGO_Central\n", "test that map_OBOterm_between_release works");

is($header_res, "#alt-id <tab> id\nGO:0042503\tGO:0007260\nGO:0042506\tGO:0007260\n\nTot. ontology terms:\t4\nTot. altID:\t7\nTot. altID seen:\t2\nTot. altID unseen:\t5\n", "test that ap_OBOterm_between_release stats are ok");

## test gaf file no pair id-altid
my $gafunpair= "t/data/test_goa_chicken_128_unpair.gaf";
open $fh, ">", $gafunpair; 
open FH, "<", $gafold;
while(<FH>){
    my @vals=split(/\t/,$_);
    if($vals[4] eq "GO:0042503" || $vals[4] eq "GO:0042506"){next;} else { print $fh $_; }
}
close FH;
close $fh;

($res, $stat)= obogaf::parser::map_OBOterm_between_release($obofile, $gafunpair, $classindex);
my $mapfile_unpair= "t/data/test_chicken_goa_mapped_unpair.txt"; 
open $fh, ">", $mapfile_header; 
print $fh "${$res}";
close $fh;
my $unpair_res= ${$stat};

file_ok($mapfile_header, "UniProtKB\tE1BXP7\tGCFC1\t\tGO:2000288\tGO_REF:0000019\tIEA\tEnsembl:ENSMUSP00000113835\tP\tUncharacterized protein\tE1BXP7_CHICK|GCFC1\tprotein\ttaxon:9031\t20160507\tEnsembl\nUniProtKB\tE1BXP7\tGCFC1\tNOT\tGO:0001078\tGO_REF:0000033\tIBA\tPANTHER:PTN000259148\tF\tUncharacterized protein\tE1BXP7_CHICK|GCFC1\tprotein\ttaxon:9031\t20141217\tGO_Central\n", "test that map_OBOterm_between_release works");

is($unpair_res, "Tot. ontology terms:\t2\nTot. altID:\t7\nTot. altID seen:\t0\nTot. altID unseen:\t7\n", "test that ap_OBOterm_between_release stats are ok");

done_testing();




