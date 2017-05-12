#!perl

use strict;
use warnings;

use Test::More tests => 27;

use_ok( 'Tie::MooseObject' );

my $p = Point->new( x => 1, y => 20 );
my $t = Tie::MooseObject->new( object => $p );
isa_ok( $t, 'Tie::MooseObject' );
can_ok( $t, 'is' );
can_ok( $t, 'write_loop' );
can_ok( $t, 'object' );

my %p;
ok( my $o = tie( %p, 'Tie::MooseObject', object => $p, is => 'rw' ), 'tie() returns true' );
isa_ok( $o, 'Tie::MooseObject' );
ok( exists( $p{get_x} ), 'EXISTS with separate reader/writer' );
ok( exists( $p{y} ), 'EXISTS with combined reader/writer' );
is( $p{get_x}, 1, 'FETCH with separate reader/writer' );
is( $p{y}, 20, 'FETCH with combined reader/writer' );
ok( !eval { delete( $p{y} ); 1 }, 'DELETE throws error' );
ok( !eval { %p = (); 1 }, 'CLEAR throws error' );

$p{set_x} = 2;
is( $p{get_x}, 2, 'STORE with separate reader/writer' );
$p{y} = 10;
is( $p{y}, 10, 'STORE with combined reader/writer' );
ok( !eval { $p{x} = 10; 1 }, 'STORE only allows reader/writer method access' );
isnt( $p{get_x}, 10, 'STORE only allows reader/writer method access' );
is( scalar( keys %p ), 2, 'SCALAR returns correct count on readwrite hash' );
my @keys = sort keys %p;
is_deeply( \@keys, [ qw/get_x y/ ], 'keys() returns the keys in readwrite hash' );
my @values = sort { $a <=> $b } values %p;
is_deeply( \@values, [ 2, 10 ], 'values() returns the values in readonly hash' );
$o->is( 'ro' );
ok( !eval { $p{set_x} = 22; 1 }, 'STORE on readonly throws error, separate reader/writer');
isnt( $p{get_x}, 22, 'STORE on readonly doesn\'t store' );
ok( !eval { $p{y} = 20; 1 }, 'STORE on readonly throws error, combined reader/writer');
isnt( $p{y}, 20, 'STORE on readonly doesn\'t store' );
is( scalar( keys %p ), 2, 'SCALAR returns correct count on readonly' );
@keys = sort keys %p;
is_deeply( \@keys, [ qw/get_x y/ ], 'keys() returns the keys in readonly hash' );
@values = sort { $a <=> $b } values %p;
is_deeply( \@values, [ 2, 10 ], 'values() returns the values in readonly hash' );

BEGIN {
use MooseX::Declare;
class Point {

    has 'x' => (
        is => 'rw',
        isa => 'Int',
        predicate => 'has_x',
        reader => 'get_x',
        writer => 'set_x'
    );
    has 'y' => ( isa => 'Int', is => 'rw' );

}
}
