# This test and corresponding fix was submitted by HDP to fix RT #16889

use 5.006;

use strict;
use warnings FATAL => 'all';

use Test::More tests => 6;

use_ok( 'Tree::Binary2' );

my $tree = Tree::Binary2->new('root');
$tree->left(Tree::Binary2->new('left'));
$tree->right(Tree::Binary2->new('right'));

my $clone = $tree->clone;

use Data::Dumper;

is($clone->left->value, $tree->left->value, "clone has same value as original")
    or diag Dumper($clone, $tree);

is(
    scalar @{ $tree->{_children} }, 2,
    "original tree still has 2 children",
);

is(
    scalar @{ $clone->{_children} }, 2,
    "clone also has 2 children",
);

is(
    $clone->left->parent,
    $clone,
    "left child of clone has correct parent",
);

is(
    $clone->right->parent,
    $clone,
    "right child of clone has correct parent",
);

__END__
