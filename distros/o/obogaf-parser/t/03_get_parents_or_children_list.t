use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Files;
use obogaf::parser;

# input files/variables
my $goedges=     "t/data/test_gobasic_edges.txt"; 
my $fakegoedges= "t/data/test_GObasic_edges.txt";
my ($parentIndex, $childIndex)= (1,2);

## define arguments
my ($res,$gores,$chdlist,$parlist,$fh,$chdORpar);

## build $goedges
my $obofile=  "t/data/test_gobasic.obo";
$gores= obogaf::parser::build_edges($obofile);
open $fh, ">", $goedges; 
print $fh "${$gores}";
close $fh;

## test read or die
lives_ok( sub { my $file = obogaf::parser::get_parents_or_children_list($goedges, $parentIndex, $childIndex, "parents" ) }, 'file opened' );
lives_ok( sub { my $file = obogaf::parser::get_parents_or_children_list($goedges, $parentIndex, $childIndex, "children") }, 'file opened' );

dies_ok ( sub { my $file = obogaf::parser::get_parents_or_children_list($goedges, $parentIndex, $childIndex, "CHILDREN") }, 'die: misspelled' );
dies_ok ( sub { my $file = obogaf::parser::get_parents_or_children_list($goedges, $parentIndex, $childIndex, "PARENTS" ) }, 'die: misspelled' );

dies_ok ( sub { my $file = obogaf::parser::get_parents_or_children_list($fakegoedges, $parentIndex, $childIndex, "parents" ) }, 'die: wrong file name' );
dies_ok ( sub { my $file = obogaf::parser::get_parents_or_children_list($fakegoedges, $parentIndex, $childIndex, "children") }, 'die: wrong file name' );

## test parents list (whole ontology)
$chdORpar= "parents";
$res= obogaf::parser::get_parents_or_children_list($goedges, 1,2, $chdORpar);
$parlist= "t/data/test_gobasic_parents_list.txt";
open $fh, ">", $parlist;
foreach my $k (sort{$a cmp $b} keys %$res) { print $fh "$k $$res{$k}\n";} ## dereferencing
close $fh;

file_ok($parlist, "GO:0007260 GO:0018108|GO:0007259\n", "test that get_parents_or_children_list works");

## test children list (whole ontology)
$chdORpar= "children";
$res= obogaf::parser::get_parents_or_children_list($goedges, 1,2, $chdORpar);
$chdlist= "t/data/test_gobasic_children_list.txt";
open $fh, ">", $chdlist;
foreach my $k (sort{$a cmp $b} keys %$res) { print $fh "$k $$res{$k}\n";} ## dereferencing
close $fh;

file_ok($chdlist, "GO:0007259 GO:0007260\nGO:0018108 GO:0007260\n", "test that get_parents_or_children_list works");

## test parents list (BP subontology)
my $domain= "biological_process";
my $gobp= "t/data/test_gobasic_edgesBP.txt";
$gores= obogaf::parser::build_subonto($goedges, $domain);
open $fh, ">", $gobp; 
print $fh "${$gores}";
close $fh;

$chdORpar= "parents";
$res= obogaf::parser::get_parents_or_children_list($gobp, 0,1, $chdORpar);
$parlist= "t/data/test_gobasicBP_parents_list.txt";
open $fh, ">", $parlist;
foreach my $k (sort{$a cmp $b} keys %$res) { print $fh "$k $$res{$k}\n";} ## dereferencing
close $fh;

file_ok($parlist, "GO:0007260 GO:0018108|GO:0007259\n", "test that get_parents_or_children_list works");

## test children list (BP subontology)
$chdORpar= "children";
$res= obogaf::parser::get_parents_or_children_list($gobp, 0,1, $chdORpar);
$chdlist= "t/data/test_gobasicBP_children_list.txt";
open $fh, ">", $chdlist;
foreach my $k (sort{$a cmp $b} keys %$res) { print $fh "$k $$res{$k}\n";} ## dereferencing
close $fh;

file_ok($chdlist, "GO:0007259 GO:0007260\nGO:0018108 GO:0007260\n", "test that get_parents_or_children_list works");

done_testing();
