#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
use Text::Tradition;

my $t = Text::Tradition->new( 
    'name'  => 'simple test', 
    'input' => 'Tabular',
    'file'  => 't/data/simple.txt',
    );
is( $t->stemma_count, 0, "No stemmas added yet" );
my $s;
ok( $s = $t->add_stemma( dotfile => 't/data/simple.dot' ), "Added a simple stemma" );
is( ref( $s ), 'Text::Tradition::Stemma', "Got a stemma object returned" );
is( $t->stemma_count, 1, "Tradition claims to have a stemma" );
is( $t->stemma(0), $s, "Tradition hands back the right stemma" );
}



# =begin testing
{
use Text::Tradition;
use JSON qw/ from_json /;

my $t = Text::Tradition->new( 
    'name'  => 'Stemweb test', 
    'input' => 'Self',
    'file'  => 't/data/besoin.xml',
    'stemweb_jobid' => '4',
    );

is( $t->stemma_count, 0, "No stemmas added yet" );

my $answer = from_json( '{"status": 0, "job_id": "4", "algorithm": "RHM", "format": "newick", "start_time": "2013-10-26 10:44:14.050263", "result": "((((((((((((_A_F,_A_U),_A_V),_A_S),_A_T1),_A_T2),_A_A),_A_J),_A_B),_A_L),_A_D),_A_M),_A_C);\n", "end_time": "2013-10-26 10:45:55.398944"}' );
my $newst = $t->record_stemweb_result( $answer );
is( scalar @$newst, 1, "New stemma was returned from record_stemweb_result" );
is( $newst->[0], $t->stemma(0), "Answer has the right object" );
ok( !$t->has_stemweb_jobid, "Job ID was removed from tradition" );
is( $t->stemma_count, 1, "Tradition has new stemma" );
ok( $t->stemma(0)->is_undirected, "New stemma is undirected as it should be" );
is( $t->stemma(0)->identifier, "RHM 1382784254_0", "Stemma has correct identifier" );
is( $t->stemma(0)->from_jobid, 4, "New stemma has correct associated job ID" );
foreach my $wit ( $t->stemma(0)->witnesses ) {
	ok( $t->has_witness( $wit ), "Extant stemma witness $wit exists in tradition" );
}
}




1;
