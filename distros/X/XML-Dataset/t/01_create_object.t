#!perl

use strict;
use warnings;
use Test::More tests => 3;

use_ok( 'XML::Dataset' );
my $parser = XML::Dataset->new;
ok( defined $parser, 'new() created an object' );
isa_ok( $parser, 'XML::Dataset' );
