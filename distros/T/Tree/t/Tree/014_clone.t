use strict;
use warnings;

use Test::More tests => 20;
use Test::Deep;

use Scalar::Util qw( refaddr );

my $CLASS = 'Tree';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

my $tree = $CLASS->new( 'foo' );
my $clone = $tree->clone;

isa_ok( $clone, $CLASS );
isnt( refaddr($clone), refaddr($tree), "The clone is a different reference from the tree" );
cmp_deeply( $clone, $tree, "The clone has all the same info as the tree" );

$tree->set_value( 'bar' );

ok( !eq_deeply( $clone, $tree ), "The tree changed, but the clone didn't track" );

$tree->set_value( 'foo' );

cmp_deeply( $clone, $tree, "The tree changed back, so they're equivalent" );

my $child = $CLASS->new;
$tree->add_child( $child );

ok( !eq_deeply( $clone, $tree ), "The tree added a child, but the clone didn't track" );

my $clone2 = $tree->clone;

cmp_deeply( $clone2, $tree, "Cloning with children works" );
my $cloned_child = $clone->children(0);
isnt( refaddr($cloned_child), refaddr($child), "The cloned child is a different reference from the child" );

my $grandchild = $CLASS->new;
$child->add_child( $grandchild );

my $clone3 = $tree->clone;
cmp_deeply( $clone3, $tree, "Cloning with grandchildren works" );

my $clone4 = $child->clone;
ok( !eq_deeply( $clone4, $child ), "Even though the child is cloned, the parentage is not" );
ok( $clone4->is_root, "... all clones are roots" );

my $clone5 = $CLASS->clone;
isa_ok( $clone5, $CLASS );

my $tree2 = $CLASS->new('foo');
my $clone6 = $tree2->clone('bar');

ok(!eq_deeply( $clone6, $tree2 ), "By passing a value into clone(), it sets the value of the clone" );
is( $clone6->value, 'bar', "The clone's value should be 'bar'" );
is( $tree2->value, 'foo', "... but the tree's value should still be 'foo'" );

my $clone7 = $tree2->new;
cmp_deeply( $clone, $tree2, "Calling new() with an object wraps clone()" );

my $clone8 = $tree2->new( 'bar' );
ok(!eq_deeply( $clone8, $tree2 ), "By passing a value into an object calling new(), it sets the value of the clone" );
is( $clone8->value, 'bar', "The clone's value should be 'bar'" );
is( $tree2->value, 'foo', "... but the tree's value should still be 'foo'" );
