package Foo;

use Test::More tests => 4;
use warnings;
use strict;
use Carp qw{ confess };

use base qw{ YAML::Accessor };

our $yml = './testdata/testdata.yaml';

ok( -e $yml );

# Standard constructor
my $ya = Foo->new(
	file => $yml,          # Can be a filehandle.
	autocommit => 0,       # This is a default. Can be 1 (true).
	readonly   => 1,       # This is a default. Can be 1 (true).
	damian     => 1,       # See below. Can be 0 (false).
);

ok( $ya );

my $fh;

open $fh, "+<", $yml
	or die $!;

ok( $fh );

$ya = Foo->new(
	file       => $fh,     # Can be a filehandle.
	autocommit => 0,       # This is a default. Can be 1 (true).
	readonly   => 1,       # This is a default. Can be 1 (true).
	damian     => 1,       # See below. Can be 0 (false).
);

ok( $ya );
