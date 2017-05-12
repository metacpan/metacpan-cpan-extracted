use strict;

use Test::More tests => 23;
use Tree::RedBlack;

my $tree = Tree::RedBlack->new();
isa_ok($tree, 'Tree::RedBlack');

is($tree->root, undef);

is($tree->find(42), undef);
is($tree->max, undef);
is($tree->min, undef);

$tree->insert(3, 'cat');
is($tree->find(3), 'cat');

is($tree->min->val, 'cat');

is($tree->max->val, 'cat');

is($tree->find(42), undef);

$tree->insert(3, 'dog');
is($tree->find(3), 'dog');

$tree->insert(4);

is($tree->max->val, undef);
is($tree->find(4), undef);
isa_ok($tree->node(4), 'Tree::RedBlack::Node');

$tree->insert(7, 'dude');

$tree->insert(5, 'really');

$tree->insert(6, 'cool');

is($tree->min->val, 'dog');
is($tree->max->val, 'dude');

is($tree->find(5), 'really');

$tree->delete(3);
is($tree->min->val, undef);

is($tree->node(14), undef);


my $tree2 = Tree::RedBlack->new();
$tree2->cmp(sub { $_[0] <=> $_[1] });
$tree2->insert(10);
$tree2->insert(2);
is($tree2->max->key, 10);
is($tree2->min->key, 2);

is($tree2->node(10), $tree2->max);
is($tree2->node(2), $tree2->min);

SKIP: {
  skip 'delete not working correctly' => 1;
  $tree2->delete(10);
  is($tree2->max->key, 2);
};
