use lib 't/lib';
use strict;
use warnings;

use Test::More;

use Tests qw( %runs );

plan tests => 41 + 3 * $runs{stats}{plan};

my $CLASS = 'Tree';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

# Test Plan:
# 1) Add two children to a root node to make a 3-level tree.
# 2) Verify that all state is correctly reported
# 3) Remove the mid-level node
# 4) Verify that all state is correctly reported
# 5) Re-add the mid-level node
# 6) Verify that all state is correctly reported

my $root = $CLASS->new;
isa_ok( $root, $CLASS );

my $child1 = $CLASS->new;
isa_ok( $child1, $CLASS );

my $child2 = $CLASS->new;
isa_ok( $child2, $CLASS );

$root->add_child( $child1 );
$child1->add_child( $child2 );

cmp_ok( $root->children, '==', 1, "The root has one child" );
cmp_ok( $child1->children, '==', 1, "The child1 has one child" );
cmp_ok( $child2->children, '==', 0, "The child2 has zero children" );

$runs{stats}{func}->( $root,
    height => 3, width => 1, depth => 0, size => 3, is_root => 1, is_leaf => 0,
);

$runs{stats}{func}->( $child1,
    height => 2, width => 1, depth => 1, size => 2, is_root => 0, is_leaf => 0,
);

$runs{stats}{func}->( $child2,
    height => 1, width => 1, depth => 2, size => 1, is_root => 0, is_leaf => 1,
);

is( $child1->root, $root, "The child1's root is the root" );
is( $child2->root, $root, "The child2's root is the root" );

$root->remove_child( $child1 );

cmp_ok( $root->height, '==', 1, "The root's height is one after removal." );
cmp_ok( $child1->height, '==', 2, "The child1's height is two." );
cmp_ok( $child2->height, '==', 1, "The child2's height is one." );

cmp_ok( $root->width, '==', 1, "The root's width is one." );
cmp_ok( $child1->width, '==', 1, "The child1's width is one." );
cmp_ok( $child2->width, '==', 1, "The child2's width is one." );

is( $child1->root, $child1, "The child1's root is the child1" );
is( $child2->root, $child1, "The child2's root is the child1" );

$root->add_child( $child1 );

cmp_ok( $root->height, '==', 3, "The root's height is three." );
cmp_ok( $child1->height, '==', 2, "The child1's height is two." );
cmp_ok( $child2->height, '==', 1, "The child2's height is one." );

cmp_ok( $root->width, '==', 1, "The root's width is one." );
cmp_ok( $child1->width, '==', 1, "The child1's width is one." );
cmp_ok( $child2->width, '==', 1, "The child2's width is one." );

is( $child1->root, $root, "The child1's root is the root" );
is( $child2->root, $root, "The child2's root is the root" );

$child1->remove_child( $child2 );

cmp_ok( $root->height, '==', 2, "The root's height is two." );
cmp_ok( $child1->height, '==', 1, "The child1's height is one." );
cmp_ok( $child2->height, '==', 1, "The child2's height is one." );

cmp_ok( $root->width, '==', 1, "The root's width is one." );
cmp_ok( $child1->width, '==', 1, "The child1's width is one." );
cmp_ok( $child2->width, '==', 1, "The child2's width is one." );

is( $child1->root, $root, "The child1's root is the root" );
is( $child2->root, $child2, "The child2's root is the root" );

# Test 4-level trees and how root works

my @nodes = map { $CLASS->new } 1 .. 4;
$nodes[2]->add_child( $nodes[3] );
$nodes[1]->add_child( $nodes[2] );
$nodes[0]->add_child( $nodes[1] );

is( $nodes[0]->root, $nodes[0], "The root is correct for level 0" );
is( $nodes[1]->root, $nodes[0], "The root is correct for level 1" );
is( $nodes[2]->root, $nodes[0], "The root is correct for level 2" );
is( $nodes[3]->root, $nodes[0], "The root is correct for level 3" );

$nodes[0]->remove_child( 0 );
is( $nodes[0]->root, $nodes[0], "The root is correct for level 0" );
is( $nodes[1]->root, $nodes[1], "The root is correct for level 1" );
is( $nodes[2]->root, $nodes[1], "The root is correct for level 2" );
is( $nodes[3]->root, $nodes[1], "The root is correct for level 3" );
