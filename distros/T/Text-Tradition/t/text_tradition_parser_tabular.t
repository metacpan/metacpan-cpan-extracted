#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
use Test::More::UTF8;
use Text::Tradition;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
eval { no warnings; binmode $DB::OUT, ":utf8"; };

my $csv = 't/data/florilegium.csv';
my $t = Text::Tradition->new( 
    'name'  => 'inline', 
    'input' => 'Tabular',
    'file'  => $csv,
    'sep_char' => ',',
    );

is( ref( $t ), 'Text::Tradition', "Parsed florilegium CSV file" );

### TODO Check these figures
if( $t ) {
    is( scalar $t->collation->readings, 311, "Collation has all readings" );
    is( scalar $t->collation->paths, 361, "Collation has all paths" );
    is( scalar $t->witnesses, 13, "Collation has all witnesses" );
}

# Check that we have the right witnesses
my %seen_wits;
map { $seen_wits{$_} = 0 } qw/ A B C D E F G H K P Q S T /;
foreach my $wit ( $t->witnesses ) {
	$seen_wits{$wit->sigil} = 1;
}
is( scalar keys %seen_wits, 13, "No extra witnesses were made" );
foreach my $k ( keys %seen_wits ) {
	ok( $seen_wits{$k}, "Witness $k still exists" );
}

# Check that the witnesses have the right texts
foreach my $wit ( $t->witnesses ) {
	my $origtext = join( ' ', @{$wit->text} );
	my $graphtext = $t->collation->path_text( $wit->sigil );
	is( $graphtext, $origtext, "Collation matches original for witness " . $wit->sigil );
}

# Check that the a.c. witnesses have the right text
map { $seen_wits{$_} = 0 } qw/ A B C D F G H K S /;
foreach my $k ( keys %seen_wits ) {
	my $wit = $t->witness( $k );
	if( $seen_wits{$k} ) {
		ok( $wit->is_layered, "Witness $k got marked as layered" );
		ok( $wit->has_layertext, "Witness $k has an a.c. version" );
		my $origtext = join( ' ', @{$wit->layertext} );
		my $acsig = $wit->sigil . $t->collation->ac_label;
		my $graphtext = $t->collation->path_text( $acsig );
		is( $graphtext, $origtext, "Collation matches original a.c. for witness $k" );
	} else {
		ok( !$wit->is_layered, "Witness $k not marked as layered" );
		ok( !$wit->has_layertext, "Witness $k has no a.c. version" );
	}
}	

# Check that we only have collation relationships where we need them
is( scalar $t->collation->relationships, 3, "Redundant collations were removed" );

## Check excel parsing

my $xls = 't/data/armexample.xls';
my $xt = Text::Tradition->new(
	'name'  => 'excel test',
	'input' => 'Tabular',
	'file'  => $xls,
	'excel'   => 'xls'
	);

is( ref( $xt ), 'Text::Tradition', "Parsed test Excel 97-2004 file" );
my %xls_wits;
map { $xls_wits{$_} = 0 } qw/ Wit1 Wit2 Wit3 /;
foreach my $wit ( $xt->witnesses ) {
	$xls_wits{$wit->sigil} = 1;
}
is( scalar keys %xls_wits, 3, "No extra witnesses were made" );
foreach my $k ( keys %xls_wits ) {
	ok( $xls_wits{$k}, "Witness $k still exists" );
}
is( scalar $xt->collation->readings, 11, "Got correct number of test readings" );
is( scalar $xt->collation->paths, 13, "Got correct number of reading paths" );
is( $xt->collation->reading('r5.1')->text, "\x{587}", 
	"Correct decoding of at least one reading" );

my $xlsx = 't/data/armexample.xlsx';
my $xtx = Text::Tradition->new(
	'name'  => 'excel test',
	'input' => 'Tabular',
	'file'  => $xlsx,
	'excel'   => 'xlsx'
	);

is( ref( $xtx ), 'Text::Tradition', "Parsed test Excel 2007+ file" );
my %xlsx_wits;
map { $xlsx_wits{$_} = 0 } qw/ Wit1 Wit3 /;
$xlsx_wits{"\x{531}\x{562}2"} = 0;
foreach my $wit ( $xtx->witnesses ) {
	$xlsx_wits{$wit->sigil} = 1;
}
is( scalar keys %xlsx_wits, 3, "No extra witnesses were made" );
foreach my $k ( keys %xlsx_wits ) {
	ok( $xlsx_wits{$k}, "Witness $k still exists" );
}
is( scalar $xtx->collation->readings, 12, "Got correct number of test readings" );
is( scalar $xtx->collation->paths, 14, "Got correct number of reading paths" );
is( $xtx->collation->reading('r5.1')->text, "\x{587}", 
	"Correct decoding of at least one reading" );
}




1;
