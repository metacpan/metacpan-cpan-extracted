use lib 't/lib';
use strict;
use warnings;

use Test::More;

use Tests qw( %runs );

plan tests => 27 + 15 * $runs{stats}{plan};

my $CLASS = 'Tree';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

# Test Plan:
# 1) Add two children at once to a root node.
# 2) Verify
# 3) Remove one child
# 4) Verify that the other child is still a child of the root
# 5) Add the removed child back, then remove both to test removing multiple children

my $root = $CLASS->new( '1' );
isa_ok( $root, $CLASS );

my $child1 = $CLASS->new( '1.1' );
isa_ok( $child1, $CLASS );

my $child2 = $CLASS->new( '1.2' );
isa_ok( $child2, $CLASS );

$runs{stats}{func}->( $root,
    height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
);

$runs{stats}{func}->( $child1,
    height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
);

$runs{stats}{func}->( $child2,
    height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
);

is( $root->add_child( $child1, $child2 ), $root, "add_child(\@many) still chains" );

$runs{stats}{func}->( $root,
    height => 2, width => 2, depth => 0, size => 3, is_root => 1, is_leaf => 0,
);

$runs{stats}{func}->( $child1,
    height => 1, width => 1, depth => 1, size => 1, is_root => 0, is_leaf => 1,
);

$runs{stats}{func}->( $child2,
    height => 1, width => 1, depth => 1, size => 1, is_root => 0, is_leaf => 1,
);

cmp_ok( $root->children, '==', 2, "The root has two children" );

ok( $root->has_child( $child1 ), "The root has child1" );
ok( $root->has_child( $child2 ), "The root has child2" );
ok( $root->has_child( $child1, $child2 ), "The root has both children" );

my @v = $root->children(1, 0);
cmp_ok( @v, '==', 2, "Accessing children() by index out of order gives both back" );
is( $v[0], $child2, "... the first child is correct" );
is( $v[1], $child1, "... the second child is correct" );

$root->remove_child( $child1 );
cmp_ok( $root->children, '==', 1, "After removing child1, the root has one child" );
my @children = $root->children;
is( $children[0], $child2, "... and the right child is still there" );

ok( !$root->has_child( $child1 ), "The root doesn't have child1" );
ok( $root->has_child( $child2 ), "The root has child2" );
ok( !$root->has_child( $child1, $child2 ), "The root doesn't have both children" );
ok( !$root->has_child( $child2, $child1 ), "The root doesn't have both children (reversed)" );

$runs{stats}{func}->( $root,
    height => 2, width => 1, depth => 0, size => 2, is_root => 1, is_leaf => 0,
);

$runs{stats}{func}->( $child1,
    height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
);

$runs{stats}{func}->( $child2,
    height => 1, width => 1, depth => 1, size => 1, is_root => 0, is_leaf => 1,
);

$root->add_child( $child1 );
cmp_ok( $root->children, '==', 2, "Adding child1 back works as expected" );

$runs{stats}{func}->( $root,
    height => 2, width => 2, depth => 0, size => 3, is_root => 1, is_leaf => 0,
);

$runs{stats}{func}->( $child1,
    height => 1, width => 1, depth => 1, size => 1, is_root => 0, is_leaf => 1,
);

$runs{stats}{func}->( $child2,
    height => 1, width => 1, depth => 1, size => 1, is_root => 0, is_leaf => 1,
);

{
    my $mirror = $root->clone->mirror;
    my @children = $root->children;
    my @reversed_children = $mirror->children;

    is( $children[0]->value, $reversed_children[1]->value );
    is( $children[1]->value, $reversed_children[0]->value );
}

my @removed = $root->remove_child( $child1, $child2 );
is( $removed[0], $child1 );
is( $removed[1], $child2 );
cmp_ok( $root->children, '==', 0, "remove_child(\@many) works" );

$runs{stats}{func}->( $root,
    height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
);

$runs{stats}{func}->( $child1,
    height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
);

$runs{stats}{func}->( $child2,
    height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
);


# Test various permutations of the return values from remove_child()
{
    $root->add_child( $child1, $child2 );
    my @removed = $root->remove_child( $child2, $child1 );
    is( $removed[0], $child2 );
    is( $removed[1], $child1 );
}

{
    $root->add_child( $child1, $child2 );
    my $removed = $root->remove_child( $child2, $child1 );
    is( $removed, 2 );
}
