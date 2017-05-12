#!/usr/bin/perl

##
## Tests for accessors::rw
##

use strict;
use warnings;

use Test::More tests => 6;
use Carp;

BEGIN { use_ok( "accessors::rw" ) };

my $time = shift || 0.5;

my $foo = bless {}, 'Foo';
can_ok( $foo, 'bar' );
can_ok( $foo, 'baz' );

is( $foo->bar( 'set' ), 'set', 'set foo->bar' );
is( $foo->baz( 2 ), 2,         'set foo->baz' );
is( $foo->bar, 'set',          'get foo->bar' );

# no sense benchmarking this as it inherits from accessors::classic.

package Foo;
use accessors::rw qw( bar baz );
