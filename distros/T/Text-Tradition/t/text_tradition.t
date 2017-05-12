#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
use TryCatch;
use_ok( 'Text::Tradition', "can use module" );

my $t = Text::Tradition->new( 'name' => 'empty' );
is( ref( $t ), 'Text::Tradition', "initialized an empty Tradition object" );
is( $t->name, 'empty', "object has the right name" );
is( scalar $t->witnesses, 0, "object has no witnesses" );

my $simple = 't/data/simple.txt';
my $s = Text::Tradition->new( 
    'name'  => 'inline', 
    'input' => 'Tabular',
    'file'  => $simple,
    );
is( ref( $s ), 'Text::Tradition', "initialized a Tradition object" );
is( $s->name, 'inline', "object has the right name" );
is( scalar $s->witnesses, 3, "object has three witnesses" );

my $wit_a = $s->witness('A');
is( ref( $wit_a ), 'Text::Tradition::Witness', "Found a witness A" );
if( $wit_a ) {
    is( $wit_a->sigil, 'A', "Witness A has the right sigil" );
}
is( $s->witness('X'), undef, "There is no witness X" );
ok( !exists $s->{'witnesses'}->{'X'}, "Witness key X not created" );

my $wit_d = $s->add_witness( 'sigil' => 'D', 'sourcetype' => 'plaintext',
	'string' => 'je suis depourvu de foi' );
is( ref( $wit_d ), 'Text::Tradition::Witness', "new witness created" );
is( $wit_d->sigil, 'D', "witness has correct sigil" );
is( scalar $s->witnesses, 4, "object now has four witnesses" );

try {
	$s->rename_witness( 'D', 'Invalid Sigil' );
	ok( 0, "Renamed witness with bad sigil" );
} catch ( Text::Tradition::Error $e ) {
	is( $s->witness('D'), $wit_d, "Held onto witness during bad rename" );
}

try {
	$s->rename_witness( 'D', 'Q' );
	ok( 1, "Rename of witness succeeded" );
	is( $s->witness('Q'), $wit_d, "Witness available under new sigil" );
	ok( !$s->has_witness('D'), "Witness no longer available under old sigil" );
} catch ( Text::Tradition::Error $e ) {
	ok( 0, "Failed to rename witness: " . $e->message );
}	

my $del = $s->del_witness( 'Q' );
is( $del, $wit_d, "Deleted correct witness" );
is( scalar $s->witnesses, 3, "object has three witnesses again" );

try {
	$s->rename_witness( 'A', 'WitA' );
	ok( 0, "Successfully renamed an already collated witness" );
} catch ( Text::Tradition::Error $e ) {
	is( $e->message, 'Cannot rename witness that has already been collated',
		"Refused to rename an already-collated witness" );
}
}




1;
