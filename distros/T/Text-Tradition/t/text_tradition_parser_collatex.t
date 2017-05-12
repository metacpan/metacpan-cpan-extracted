#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
use Text::Tradition;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
eval { no warnings; binmode $DB::OUT, ":utf8"; };

# Test a simple CollateX input
my $cxfile = 't/data/Collatex-16.xml';
my $t = Text::Tradition->new( 
    'name'  => 'inline', 
    'input' => 'CollateX',
    'file'  => $cxfile,
    );

is( ref( $t ), 'Text::Tradition', "Parsed a CollateX input" );
if( $t ) {
    is( scalar $t->collation->readings, 26, "Collation has all readings" );
    is( scalar $t->collation->paths, 32, "Collation has all paths" );
    is( scalar $t->witnesses, 3, "Collation has all witnesses" );
    
    # Check an 'identical' node
    my $transposed = $t->collation->reading( 'n15' );
    my @related = $transposed->related_readings;
    is( scalar @related, 1, "Reading links to transposed version" );
    is( $related[0]->id, 'n18', "Correct transposition link" );
}

# Now test a CollateX result with a.c. witnesses

my $ct = Text::Tradition->new( 
	name => 'florilegium',
	input => 'CollateX',
	file => 't/data/florilegium_cx.xml' );

is( ref( $ct ), 'Text::Tradition', "Parsed the CollateX input" );
if( $ct ) {
    is( scalar $ct->collation->readings, 309, "Collation has all readings" );
    is( scalar $ct->collation->paths, 361, "Collation has all paths" );
    is( scalar $ct->witnesses, 13, "Collation has correct number of witnesses" );
    
    my %layered = ( E => 1, P => 1, Q => 1, T => 1 );
    foreach my $w ( $ct->witnesses ) {
    	is( $w->is_layered, $layered{$w->sigil}, 
    		"Witness " . $w->sigil . " has correct layered setting" );
    }
    
    my $pseq = $ct->witness('P')->text;
    my $pseqac = $ct->witness('P')->layertext;
    is( scalar @$pseq, 264, "Witness P has correct number of tokens" );
    is( scalar @$pseqac, 261, "Witness P (a.c.) has correct number of tokens" );
}
    
}




1;
