#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 12;
use Scalar::Util qw( blessed );

use ok 'Test::Mocha';

# ----------------------
# creating a mock

my $mock = mock();
ok( $mock, 'mock() creates a simple mock' );

# ----------------------
# mocks pretend to be anything you want

ok( $mock->isa('Bar'),  'mock can isa(Anything)' );
ok( $mock->does('Baz'), 'mock can does(Anything)' );
ok( $mock->DOES('Baz'), 'mock can DOES(Anything)' );

# ----------------------
# mocks accept any method calls

my $calls   = $mock->__calls;
my $coderef = $mock->can('foo');
ok( $coderef, 'mock can(anything)' );
is( ref($coderef), 'CODE', '... and can() returns a coderef' );
is( $coderef->( $mock, 1 ),
    undef, '... and can() coderef returns undef by default' );
is(
    $calls->[-1]->stringify_long,
    sprintf( 'foo(1) called at %s line %d', __FILE__, __LINE__ - 4 ),
    '... and method call is recorded'
);

is( $mock->foo( bar => 1 ),
    undef, 'mock accepts any method call, returning undef by default' );
is(
    $calls->[-1]->stringify_long,
    sprintf( 'foo(bar: 1) called at %s line %d', __FILE__, __LINE__ - 4 ),
    '... and method call is recorded'
);

$mock->DESTROY;
isnt( $calls->[-1]->stringify, 'DESTROY()', 'DESTROY() is not AUTOLOADed' );
