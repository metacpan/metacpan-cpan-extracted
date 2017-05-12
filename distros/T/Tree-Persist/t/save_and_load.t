use strict;
use warnings;

use File::Spec::Functions qw( catfile );
use File::Temp;

use Test::File;
use Test::File::Contents;

use Test::More;

# ---------------------------------------------

eval "use XML::Parser";

plan skip_all => "XML::Parser required for testing File plugin" if $@;
plan tests    => 7;

# The EXLOCK option is for BSD-based systems.

my $in_dir    = catfile( qw( t datafiles ) );
my $out_dir   = File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);

plan skip_all => "Temp dir is un-writable" if (! -w $out_dir);

use_ok( 'Tree' );

my $CLASS = 'Tree::Persist';

use_ok( $CLASS ) || Test::More->builder->BAILOUT( "Cannot load $CLASS" );

my $file_name = catfile( $out_dir, 'save4.xml' );

{
	file_not_exists_ok( $file_name, "$file_name file doesn't exist yet" );

	my($tree) =
	Tree->new( 'A' )->add_child
	(
		Tree->new( 'B' ),
		Tree->new( 'C' )->add_child
		(
			Tree->new( 'D' ),
		),
		Tree->new( 'E' ),
	);

	my($writer) = $CLASS -> create_datastore
	({
		class    => 'Tree::Persist::File::XMLWithSingleQuotes',
		filename => $file_name,
		tree     => $tree,
	});

	file_exists_ok( $file_name, "$file_name file exists");
}

{
	my($reader) = $CLASS -> connect
	({
		class    => 'Tree::Persist::File::XMLWithSingleQuotes',
		filename => $file_name,
	});

	my($tree) = $reader -> tree();
	my(@kids) = $tree -> children;

	isa_ok( $tree, 'Tree' );
	is( $tree->value,      'A', "The tree's root value was loaded correctly" );
	is( $kids[2] -> value, 'E', "The tree's 3rd child value was loaded correctly" );
}
