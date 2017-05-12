#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 9;
use File::Spec::Functions;
use YAML::Tiny::Stream;

# Locate the test file
my $input = catfile( 't', 'data', 'sample.yml' );
ok( -f $input, 'Found sample .yml file' );





######################################################################
# Main Tests

# Create the parser
my $stream = YAML::Tiny::Stream->new($input);
isa_ok( $stream, 'YAML::Tiny::Stream' );

# Parse till we can't parse no more
my @yaml = ();
while ( my $document = $stream->fetch ) {
	isa_ok( $document, 'YAML::Tiny' );
	is( scalar(@$document), 1, 'Object contains one document' );
	push @yaml, $document;
}
is( scalar(@yaml), 3, 'Found three YAML documents' );
