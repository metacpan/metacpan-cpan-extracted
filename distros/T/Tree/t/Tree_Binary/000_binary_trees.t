use lib 't/lib';
use strict;
use warnings;

use Test::More;

use Tests qw( %runs );

plan tests => 28 + 15 * $runs{stats}{plan};

my $CLASS = 'Tree::Binary2';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

my $root = $CLASS->new( 'root' );
isa_ok( $root, $CLASS );
isa_ok( $root, 'Tree' );

is( $root->root, $root, "The root's root is itself" );
is( $root->value, 'root', "value() works" );

$runs{stats}{func}->( $root,
    height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
);

can_ok( $root, qw( left right ) );

my $left = $CLASS->new( 'left' );

$runs{stats}{func}->( $left,
    height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
);

is( $root->left(), '', "Calling left with no params is a getter" );
is( $root->left( $left ), $root, "Calling left as a setter chains" );
is( $root->left(), $left, "... and set the left" );

cmp_ok( $root->children, '==', 1, "children() works" );
ok( $root->has_child( $left ), "has_child(BOOL) works on left" );
is_deeply( [ $root->get_index_for( $left ) ], [ 0 ], "get_index_for works on left" );

$runs{stats}{func}->( $root,
    height => 2, width => 1, depth => 0, size => 2, is_root => 1, is_leaf => 0,
);

$runs{stats}{func}->( $left,
    height => 1, width => 1, depth => 1, size => 1, is_root => 0, is_leaf => 1,
);

is( $root->left( undef ), $root, "Calling left with undef as a param" );
is( $root->left(), '', "... unsets left" );

cmp_ok( $root->children, '==', 0, "children() works" );

$runs{stats}{func}->( $root,
    height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
);

$runs{stats}{func}->( $left,
    height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
);

my $right = $CLASS->new( 'right' );

$runs{stats}{func}->( $right,
    height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
);

is( $root->right(), '', "Calling right with no params is a getter" );
is( $root->right( $right ), $root, "Calling right as a setter chains" );
is( $root->right(), $right, "... and set the right" );

cmp_ok( $root->children, '==', 1, "children() works" );
ok( $root->has_child( $right ), "has_child(BOOL) works on right" );
is_deeply( [ $root->get_index_for( $right ) ], [ 1 ], "get_index_for works on right" );

$runs{stats}{func}->( $root,
    height => 2, width => 1, depth => 0, size => 2, is_root => 1, is_leaf => 0,
);

$runs{stats}{func}->( $right,
    height => 1, width => 1, depth => 1, size => 1, is_root => 0, is_leaf => 1,
);

is( $root->right( undef ), $root, "Calling right with undef as a param" );
is( $root->right(), '', "... unsets right" );

cmp_ok( $root->children, '==', 0, "children() works" );

$runs{stats}{func}->( $root,
    height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
);

$runs{stats}{func}->( $right,
    height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
);

$root->left( $left );
$root->right( $right );

cmp_ok( $root->children, '==', 2, "children() works" );
ok( $root->has_child( $left ), "has_child(BOOL) works on right" );
ok( $root->has_child( $right ), "has_child(BOOL) works on right" );
ok( $root->has_child( $left, $right ), "has_child(SCALAR) works on right" );

$runs{stats}{func}->( $root,
    height => 2, width => 2, depth => 0, size => 3, is_root => 1, is_leaf => 0,
);
$runs{stats}{func}->( $left, height => 1, width => 1, depth => 1, size => 1, is_root => 0, is_leaf => 1,);

$runs{stats}{func}->( $right,
    height => 1, width => 1, depth => 1, size => 1, is_root => 0, is_leaf => 1,
);

my $right2 = $right->clone;
$runs{stats}{func}->( $right2,
    height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
);
