use lib 't/lib';
use strict;
use warnings;

use Test::More;

use Tests qw( %runs );

plan tests => 22 + 4 * $runs{stats}{plan};

my $CLASS = 'Tree';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

# Test plan:
# Add a single child, then retrieve it, then remove it.
# 1) Verify that one can retrieve a child added
# 2) Verify that the appropriate status methods reflect the change
# 3) Verify that the child can be removed
# 4) Verify that the appropriate status methods reflect the change

my $root = $CLASS->new();
isa_ok( $root, $CLASS );

my $child = $CLASS->new();
isa_ok( $child, $CLASS );

ok( $child->is_root, "The child is a root ... for now" );
ok( $child->is_leaf, "The child is also a leaf" );

ok( !$root->has_child( $child ), "The root doesn't have the child ... yet" );

is( $root->add_child( $child ), $root, "add_child() chains" );

cmp_ok( $root->children, '==', 1, "The root has one child" );
{
    my @children = $root->children;
    cmp_ok( @children, '==', 1, "The list of children is still 1 long" );
    is( $children[0], $child, "... and the child is correct" );
}

is( $root->children(0), $child, "You can also access the children by index" );
{
    my @children = $root->children(0);
    cmp_ok( @children, '==', 1, "The list of children by index is still 1 long" );
    is( $children[0], $child, "... and the child is correct" );
}

is( $child->parent, $root, "The child's parent is also set correctly" );
is( $child->root, $root, "The child's root is also set correctly" );

ok( $root->has_child( $child ), "The tree has the child" );

my ($idx) = $root->get_index_for( $child );
cmp_ok( $idx, '==', 0, "... and the child is at index 0 (scalar)" );

my @idx = $root->get_index_for( $child );
is_deeply( \@idx, [ 0 ], "... and the child is at index 0 (list)" );

$runs{stats}{func}->( $root,
    height => 2, width => 1, depth => 0, size => 2, is_root => 1, is_leaf => 0,
);

$runs{stats}{func}->( $child,
    height => 1, width => 1, depth => 1, size => 1, is_root => 0, is_leaf => 1,
);

is_deeply( [ $root->remove_child( $child ) ], [ $child ], "remove_child() returns the removed node" );

is( $child->parent, "", "The child's parent is now empty" );
is( $child->root, $child, "The child's root is now itself" );

cmp_ok( $root->children, '==', 0, "The root has no children" );

$runs{stats}{func}->( $root,
    height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
);

$runs{stats}{func}->( $child,
    height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
);
