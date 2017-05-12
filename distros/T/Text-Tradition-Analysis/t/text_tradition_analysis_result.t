#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
use Set::Scalar;
use Test::More::UTF8;
use Text::Tradition;
use TryCatch;
use_ok( 'Text::Tradition::Analysis::Result' );

# Make a problem with a graph and a set of groupings

my $datafile = 't/data/florilegium_tei_ps.xml';
my $tradition = Text::Tradition->new( 'input' => 'TEI',
                                      'name' => 'flortest',
                                      'file' => $datafile );
my $s = $tradition->add_stemma( 'dotfile' => 't/data/florilegium.dot' );

my $sets = [ [ qw/ D Q / ], [ qw/ F H / ], [ qw/ A B C P S T / ] ];
my $extant = {};
foreach my $set ( @$sets ) {
	map { $extant->{$_} = 1 } @$set;
}
my $sitgraph = $s->editable( { extant => $extant } );
my $result = Text::Tradition::Analysis::Result->new(
	graph => $sitgraph,
	setlist => $sets );
is( ref( $result ), 'Text::Tradition::Analysis::Result', "Got a Result object" );
is( $result->graph, $sitgraph, "Got identical graph string back" );
is( $result->status, "new", "Calculation status of result set correctly" );
my @rsets = $result->sets;
is( $rsets[0], '(A B C P S T)', "First set is biggest set" );
is( $rsets[1], '(D Q)', "Second set is by alphabetical order" );
is( $rsets[2], '(F H)', "Second set is by alphabetical order" );

# Add some calculation values
$result->is_genealogical( 1 );
$result->record_grouping( [ qw/ 4 5 D Q / ] );
try {
	$result->record_grouping( [ qw/ 3 4 D H / ] );
	ok( 0, "Recorded a grouping that does not match the input sets" );
} catch ( Text::Tradition::Error $e ) {
	like( $e->message, qr/Failed to find witness set that is a subset of/, 
		"Correct error thrown on bad record_grouping attempt" );
}
# Test manually setting an out-of-range group
try {
	$result->_set_grouping( 3, Set::Scalar->new( qw/ X Y / ) );
	ok( 0, "Set a grouping at an invalid index" );
} catch ( Text::Tradition::Error $e ) {
	is( $e->message, 'Set / group index 3 out of range for set_grouping', 
		"Caught attempt to set grouping at invalid index" );
}
$result->record_grouping( [ qw/ 3 F H / ] );
my $gp1 = $result->grouping(1);
is( $result->minimum_grouping_for( $rsets[1] ), $gp1, 
	"Found a minimum grouping for D Q" );
is( "$gp1", "(4 5 D Q)", "Retrieved minimum grouping is correct" );
is( $result->minimum_grouping_for( $rsets[0] ), $rsets[0], 
	"Default minimum grouping found for biggest group" );
$result->record_grouping( [ qw/ 1 α δ A B C P S T / ] );
my %classes = (
	α => 'source',
	3 => 'source',
	4 => 'source' );
foreach my $gp ( $result->groupings ) {
	map { my $c = $classes{$_} || 'copy'; $result->set_class( $_, $c ) } @$gp;
}
foreach my $gp ( $result->groupings ) {
	foreach my $wit ( @$gp ) {
		my $expected = $classes{$wit} || 'copy';
		is( $result->class( $wit ), $expected, "Got expected witness class for $wit" );
	}
}

# Now write it out to JSON
my $struct = $result->TO_JSON;
my $newresult = Text::Tradition::Analysis::Result->new( $struct );
is( $result->object_key, $newresult->object_key, 
	"Object key stayed constant on export/import" );
my $problem = Text::Tradition::Analysis::Result->new( graph => $sitgraph, setlist => $sets );
is( $problem->object_key, $result->object_key, 
	"Object key stayed constant for newly created problem" );
}




1;
