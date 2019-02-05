#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More 1.001002 tests => 20;
use Test::Builder::Tester;

use Type::Utils -all;
use Types::Standard -all;

use ok 'Test::Mocha';

my $mock = mock;

$mock->set('foo');
$mock->set('foobar');
$mock->set( +1, 'not an int' );
$mock->set( -1, 'negative' );
$mock->set( [qw( foo bar )] );

is( $mock->foo( 1, Int ),
    undef,
    'Type constraints can be passed as method arguments to mock methods' );

# This test checks that mock args are not treated as Type::Tiny objects
# since mocks are meant to isa() anything
is( $mock->foo( 1, mock ),
    undef, 'mocks can be passed as method arguments to mock methods' );

test_out(
    qr/ok 1 - set\(StrMatch\[\(\?.*:\^foo\)\]\) was called 2 time\(s\)\s?/);
called_ok { $mock->set( StrMatch [qr/^foo/] ) } &times(2);
test_test('parameterized type works');

test_out('ok 1 - set(Int, ~Int) was called 2 time(s)');
called_ok { $mock->set( Int, ~Int ) } &times(2);
test_test('type negation works');

test_out('ok 1 - set(Int|Str) was called 2 time(s)');
called_ok { $mock->set( Int | Str ) } &times(2);
test_test('type union works');

test_out(
    qr/ok 1 - set\(StrMatch\[\(\?.*:\^foo\)\]\&StrMatch\[\(\?.*:bar\$\)\]\) was called 1 time\(s\)\s?/
);
called_ok {
    $mock->set( ( StrMatch [qr/^foo/] ) & ( StrMatch [qr/bar$/] ) );
};
test_test('type intersection works');

test_out('ok 1 - set(Tuple[Str,Str]) was called 1 time(s)');
called_ok { $mock->set( Tuple [ Str, Str ] ) };
test_test('structured type works');

my $positive_int = declare 'PositiveInt', as Int, where { $_ > 0 };
test_out('ok 1 - set(PositiveInt, Str) was called 1 time(s)');
called_ok { $mock->set( $positive_int, Str ) };
test_test('self-defined type constraint works');

# -----------------------
# slurpy type constraints

test_out('ok 1 - set({ slurpy: ArrayRef }) was called 5 time(s)');
called_ok { $mock->set( slurpy ArrayRef ) } &times(5);
test_test('slurpy ArrayRef works');

test_out('ok 1 - set({ slurpy: Tuple[Defined,Defined] }) was called 2 time(s)');
called_ok { $mock->set( slurpy Tuple [ Defined, Defined ] ) } &times(2);
test_test('slurpy Tuple works');

test_out('ok 1 - set({ slurpy: HashRef }) was called 2 time(s)');
called_ok { $mock->set( slurpy HashRef ) } &times(2);
test_test('slurpy HashRef works');

test_out('ok 1 - set({ slurpy: Dict[-1=>Str] }) was called 1 time(s)');
called_ok { $mock->set( slurpy Dict [ -1 => Str ] ) } &times(1);
test_test('slurpy Dict works');

test_out('ok 1 - set({ slurpy: Map[PositiveInt,Str] }) was called 1 time(s)');
called_ok { $mock->set( slurpy Map [ $positive_int, Str ] ) } &times(1);
test_test('slurpy Map works');

# slurpy matches with empty argument list
$mock->bar();
test_out('ok 1 - bar({ slurpy: ArrayRef }) was called 1 time(s)');
called_ok { $mock->bar( slurpy ArrayRef ) };
test_test('slurpy ArrayRef matches no arguments');

test_out('ok 1 - bar({ slurpy: HashRef }) was called 1 time(s)');
called_ok { $mock->bar( slurpy HashRef ) };
test_test('slurpy HashRef matches no arguments');

# custom slurpy types
test_out('ok 1 - set({ slurpy: ArrayRef }) was called 5 time(s)');
called_ok { $mock->set(SlurpyArray) } &times(5);
test_test('SlurpyArray works');

test_out('ok 1 - set({ slurpy: HashRef }) was called 2 time(s)');
called_ok { $mock->set(SlurpyHash) } &times(2);
test_test('SlurpyHash works');

test_out('ok 1 - bar({ slurpy: ArrayRef }) was called 1 time(s)');
called_ok { $mock->bar(SlurpyArray) };
test_test('SlurpyArray matches no arguments');

test_out('ok 1 - bar({ slurpy: HashRef }) was called 1 time(s)');
called_ok { $mock->bar(SlurpyHash) };
test_test('SlurpyHash matches no arguments');
