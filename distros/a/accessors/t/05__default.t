#!/usr/bin/perl

##
## Tests for accessors.pm
##

use strict;
use warnings;

use Test::More tests => 6;
use Carp;

BEGIN { use_ok( "accessors" ) };

## use default style:
my $foo = bless {}, 'Foo';
can_ok( $foo, 'bar' );
can_ok( $foo, 'baz' );

ok( $foo->bar( 1 ), 'set default' );
is( $foo->bar, 1 ,  'get default' );
ok( !$foo->baz,     'get default');

package Foo;
use accessors qw( bar baz );
