#!/usr/bin/perl -T

use Test::Requires qw(
  Moose::Util::TypeConstraints
  MooseX::Types::Moose
  MooseX::Types::Structured
);

use strict;
use warnings;

use Test::More tests => 9;
use Test::Builder::Tester;

use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw( Any ArrayRef Int Str );
use MooseX::Types::Structured qw( Tuple );

BEGIN { use_ok 'Test::Mocha' }

my $mock = mock;

$mock->set( ['foo'] );
$mock->set( [ 'foo', 'bar' ] );
$mock->set( +1, 'not an int' );
$mock->set( -1, 'negative' );

is( $mock->foo( 1, Int ),
    undef,
    'Type constraints can be passed as method arguments to mock methods' );

# This test checks that mock args are not treated as Moose Type objects
# since mocks are meant to isa() anything
is( $mock->foo( 1, mock ),
    undef, 'mocks can be passed as method arguments to mock methods' );

stub { $mock->set(Any) } returns 'any';
is( $mock->set(1), 'any', 'stub() accepts type constraints' );

test_out('ok 1 - set(Int) was called 1 time(s)');
called_ok { $mock->set(Int) };
test_test('called_ok() accepts type constraints');

my $positive_int = subtype 'PositiveInt', as Int, where { $_ > 0 };
test_out('ok 1 - set(PositiveInt, Str) was called 1 time(s)');
called_ok { $mock->set( $positive_int, Str ) };
test_test('self-defined type constraint works');

test_out('ok 1 - set(ArrayRef[Str]) was called 2 time(s)');
called_ok { $mock->set( ArrayRef [Str] ) } &times(2);
test_test('parameterized type works');

test_out('ok 1 - set(ArrayRef|Int) was called 3 time(s)');
called_ok { $mock->set( ArrayRef | Int ) } &times(3);
test_test('type union works');

test_out(
    'ok 1 - set(MooseX::Types::Structured::Tuple[Str,Str]) was called 1 time(s)'
);
called_ok { $mock->set( Tuple [ Str, Str ] ) };
test_test('structured type works');
