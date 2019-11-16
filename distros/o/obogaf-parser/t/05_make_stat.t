use strict;
use warnings;
use Test::More;
use Test::Files;
use Test::Exception;
use obogaf::parser;

## define variable
my ($fh, $res, $gores, $parentIndex, $childIndex);

## build $goedges
my $obofile = "t/data/test_gobasic.obo";
my $goedges = "t/data/test_gobasic_edges.txt"; 
$gores= obogaf::parser::build_edges($obofile);
open $fh, ">", $goedges; 
print $fh "${$gores}";
close $fh;

## test with namespace
($parentIndex, $childIndex)= (1,2);
$res= obogaf::parser::make_stat($goedges, $parentIndex, $childIndex);
is($res, "#oboterm <tab> degree <tab> indegree <tab> outdegree\nGO:0007260\t2\t2\t0\nGO:0007259\t1\t0\t1\nGO:0018108\t1\t0\t1\n\n~summary stat~\nnodes: 3\nedges: 2\nmax degree: 2\nmin degree: 1\nmedian degree: 1.0000\naverage degree: 0.6667\ndensity: 3.3333e-01\n", "test that make_stat works on whole ontology");

## test read or die
my $fakedges = "t/data/test_GOBASIC_edges.txt";
lives_ok( sub { my $file = obogaf::parser::make_stat($goedges, $parentIndex, $childIndex) }, 'file opened' );
dies_ok ( sub { my $file = obogaf::parser::make_stat($fakedges, $parentIndex, $childIndex) }, 'die: wrong file name');

## build $gobp
my $domain=  "biological_process";
$gores= obogaf::parser::build_subonto($goedges, $domain);
my $gobp= "t/data/test_gobasic_edgesBP.txt"; 
open $fh, ">", $gobp; 
print $fh "${$gores}";
close $fh;

## test without namespace
($parentIndex, $childIndex)= (0,1);
$res= obogaf::parser::make_stat($gobp, $parentIndex, $childIndex);
is($res, "#oboterm <tab> degree <tab> indegree <tab> outdegree\nGO:0007260\t2\t2\t0\nGO:0007259\t1\t0\t1\nGO:0018108\t1\t0\t1\n\n~summary stat~\nnodes: 3\nedges: 2\nmax degree: 2\nmin degree: 1\nmedian degree: 1.0000\naverage degree: 0.6667\ndensity: 3.3333e-01\n", "test that make_stat works on whole ontology");

## test degeneate case 
my $goedges_stat= "t/data/test_gobasic_edges_stat.txt";
open $fh, ">", $goedges_stat; 
open FH, "<", $goedges;
while(<FH>){
    if($.==1){print $fh $_} else {next;}
}
close FH;
close $fh;

($parentIndex, $childIndex)= (1,2);
$res= obogaf::parser::make_stat($goedges_stat, $parentIndex, $childIndex);
is($res, "#oboterm <tab> degree <tab> indegree <tab> outdegree\nGO:0007260\t1\t1\t0\nGO:0018108\t1\t0\t1\n\n~summary stat~\nnodes: 2\nedges: 1\nmax degree: 1\nmin degree: 1\nmedian degree: 1.0000\naverage degree: 0.5000\ndensity: 5.0000e-01\n", "test that make_stat works on whole ontology");

done_testing();
