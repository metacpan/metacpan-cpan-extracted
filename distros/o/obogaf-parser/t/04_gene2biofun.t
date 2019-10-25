use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Files;
use obogaf::parser;

## input files
my $gafile  = "t/data/test_goa_chicken.gaf";
my $zipgaf  = "t/data/test_goa_chicken.gaf.gz"; 
my $fakegaf = "t/data/test_GOA_chicken.gaf";
my $fakezip = "t/data/test_GOA_chicken.gaf.gz";

## define arguments
my ($res,$stat,$fh);

## test read or die
my ($geneindex, $classindex)= (1, 4);
lives_ok( sub { my $file = obogaf::parser::gene2biofun($gafile,  $geneindex, $classindex) }, 'file opened' );
lives_ok( sub { my $file = obogaf::parser::gene2biofun($zipgaf,  $geneindex, $classindex) }, 'file opened' );
dies_ok ( sub { my $file = obogaf::parser::gene2biofun($fakegaf, $geneindex, $classindex) }, 'die: wrong file name');
dies_ok ( sub { my $file = obogaf::parser::gene2biofun($fakezip, $geneindex, $classindex) }, 'die: wrong file name');

## test gene2biofun without header
($res,$stat)= obogaf::parser::gene2biofun($gafile, $geneindex, $classindex);
my $ann= "t/data/test_chicken.uniprot2go.txt";
open $fh, ">", $ann;
foreach my $k (sort{$a cmp $b} keys %$res) { print $fh "$k $$res{$k}\n";} 
close $fh;
$res= ${$stat};

file_ok($ann, "F1NW72 GO:0048484|GO:0007018|GO:0016887\nF1NW73 GO:0005319|GO:0005524|GO:0006869\n", "test that gene2biofun works");
is($res, "genes: 2\nontology terms: 6\n", "test that gene2biofun stats are ok");

## test gene2biofun with header
my $gafheader= "t/data/test_goa_chicken_header.gaf";
open $fh, ">", $gafheader; 
open FH, "<", $gafile;
while(<FH>){
    if($.<2){print $fh "!\n#header gaf file\n \n";}
    print $fh $_;
}
close FH;
close $fh;

($res,$stat)= obogaf::parser::gene2biofun($gafheader, $geneindex, $classindex);
my $annfile_header= "t/data/test_chicken_uniprot2go_header.txt";
open $fh, ">", $annfile_header;
foreach my $k (sort{$a cmp $b} keys %$res) { print $fh "$k $$res{$k}\n";} 
close $fh;
$res= ${$stat};

file_ok($annfile_header, "F1NW72 GO:0048484|GO:0007018|GO:0016887\nF1NW73 GO:0005319|GO:0005524|GO:0006869\n", "test that gene2biofun works");
is($res, "genes: 2\nontology terms: 6\n", "test that gene2biofun stats are ok");

done_testing();
