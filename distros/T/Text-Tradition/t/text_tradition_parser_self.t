#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
use Safe::Isa;
use Test::Warn;
use Text::Tradition;
use TryCatch;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
eval { no warnings; binmode $DB::OUT, ":utf8"; };

my $tradition = 't/data/florilegium_graphml.xml';
my $t = Text::Tradition->new( 
    'name'  => 'inline', 
    'input' => 'Self',
    'file'  => $tradition,
    );

ok( $t->$_isa('Text::Tradition'), "Parsed GraphML version 2" );
if( $t ) {
    is( scalar $t->collation->readings, 319, "Collation has all readings" );
    is( scalar $t->collation->paths, 376, "Collation has all paths" );
    is( scalar $t->witnesses, 13, "Collation has all witnesses" );
}

# TODO add a relationship, add a stemma, write graphml, reparse it, check that 
# the new data is there
my $language_enabled = $t->can('language');
if( $language_enabled ) {
	$t->language('Greek');
}
my $stemma_enabled = $t->can('add_stemma');
if( $stemma_enabled ) {
	$t->add_stemma( 'dotfile' => 't/data/florilegium.dot' );
}
$t->collation->add_relationship( 'w12', 'w13', 
	{ 'type' => 'grammatical', 'scope' => 'global', 
	  'annotation' => 'This is some note' } );
ok( $t->collation->get_relationship( 'w12', 'w13' ), "Relationship set" );
my $graphml_str = $t->collation->as_graphml;

my $newt = Text::Tradition->new( 'input' => 'Self', 'string' => $graphml_str );
ok( $newt->$_isa('Text::Tradition'), "Parsed current GraphML version" );
if( $newt ) {
    is( scalar $newt->collation->readings, 319, "Collation has all readings" );
    is( scalar $newt->collation->paths, 376, "Collation has all paths" );
    is( scalar $newt->witnesses, 13, "Collation has all witnesses" );
    is( scalar $newt->collation->relationships, 1, "Collation has added relationship" );
    if( $language_enabled ) {
	    is( $newt->language, 'Greek', "Tradition has correct language setting" );
	}
    my $rel = $newt->collation->get_relationship( 'w12', 'w13' );
    ok( $rel, "Found set relationship" );
    is( $rel->annotation, 'This is some note', "Relationship has its properties" );
    if( $stemma_enabled ) {
	    is( scalar $newt->stemmata, 1, "Tradition has its stemma" );
    	is( $newt->stemma(0)->witnesses, $t->stemma(0)->witnesses, "Stemma has correct length witness list" );
    }
}

# Test warning if we can
unless( $stemma_enabled ) {
	my $nst;
	warnings_exist {
		$nst = Text::Tradition->new( 'input' => 'Self', 'file' => 't/data/lexformat.xml' );
	} [qr/DROPPING stemmata/],
		"Got expected stemma drop warning on parse";
} else {
	# Test parse of existing Stemweb job id
	$t->set_stemweb_jobid( '1234' );
	$graphml_str = $t->collation->as_graphml;
	try {
		$newt = Text::Tradition->new( 'input' => 'Self', 'string' => $graphml_str );
		is( $newt->stemweb_jobid, '1234', "Stemweb job ID was reparsed" );
	} catch {
		ok( 0, "Existing stemweb job ID causes parser to explode" );
	}
}
}




1;
