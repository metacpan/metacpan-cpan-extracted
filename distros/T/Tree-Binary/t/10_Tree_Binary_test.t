use strict;
use warnings;

use Test::More tests => 61;

BEGIN {
    use_ok('Tree::Binary');
}

can_ok("Tree::Binary", 'new');
can_ok("Tree::Binary", 'setLeft');
can_ok("Tree::Binary", 'setRight');

my $btree = Tree::Binary->new("/")
                        ->setLeft(
                            Tree::Binary->new("+")
                                        ->setLeft(
                                            Tree::Binary->new("2")
                                        )
                                        ->setRight(
                                            Tree::Binary->new("2")
                                        )
                        )
                        ->setRight(
                            Tree::Binary->new("*")
                                        ->setLeft(
                                            Tree::Binary->new("4")
                                        )
                                        ->setRight(
                                            Tree::Binary->new("5")
                                        )
                        );
isa_ok($btree, 'Tree::Binary');

## informational methods

can_ok($btree, 'isRoot');
ok($btree->isRoot(), '... this is the root');

can_ok($btree, 'isLeaf');
ok(!$btree->isLeaf(), '... this is not a leaf node');
ok($btree->getLeft()->getLeft()->isLeaf(), '... this is a leaf node');

can_ok($btree, 'hasLeft');
ok($btree->hasLeft(), '... this has a left node');

can_ok($btree, 'hasRight');
ok($btree->hasRight(), '... this has a right node');

## accessors

can_ok($btree, 'getUID');

{
    my $UID = $btree->getUID();
    like("$btree", qr/$UID/, '... our UID is derived from the stringified object');
}

can_ok($btree, 'getNodeValue');
is($btree->getNodeValue(), '/', '... got what we expected');

{
    can_ok($btree, 'getLeft');
    my $left = $btree->getLeft();

    isa_ok($left, 'Tree::Binary');

    is($left->getNodeValue(), '+', '... got what we expected');

    can_ok($left, 'getParent');

    my $parent = $left->getParent();
    isa_ok($parent, 'Tree::Binary');

    is($parent, $btree, '.. got what we expected');
}

{
    can_ok($btree, 'getRight');
    my $right = $btree->getRight();

    isa_ok($right, 'Tree::Binary');

    is($right->getNodeValue(), '*', '... got what we expected');

    can_ok($right, 'getParent');

    my $parent = $right->getParent();
    isa_ok($parent, 'Tree::Binary');

    is($parent, $btree, '.. got what we expected');
}

## mutators

can_ok($btree, 'setUID');
$btree->setUID("Our UID for this tree");

is($btree->getUID(), 'Our UID for this tree', '... our UID is not what we expected');

can_ok($btree, 'setNodeValue');
$btree->setNodeValue('*');

is($btree->getNodeValue(), '*', '... got what we expected');


{
    can_ok($btree, 'removeLeft');
    my $left = $btree->removeLeft();
    isa_ok($left, 'Tree::Binary');

    ok(!$btree->hasLeft(), '... we dont have a left node anymore');
    ok(!$btree->isLeaf(), '... and we are not a leaf node');

    $btree->setLeft($left);

    ok($btree->hasLeft(), '... we have our left node again');
    is($btree->getLeft(), $left, '... and it is what we told it to be');
}

{
    # remove left leaf
    my $left_leaf = $btree->getLeft()->removeLeft();
    isa_ok($left_leaf, 'Tree::Binary');

    ok($left_leaf->isLeaf(), '... our left leaf is a leaf');

    ok(!$btree->getLeft()->hasLeft(), '... we dont have a left leaf node anymore');

    $btree->getLeft()->setLeft($left_leaf);

    ok($btree->getLeft()->hasLeft(), '... we have our left leaf node again');
    is($btree->getLeft()->getLeft(), $left_leaf, '... and it is what we told it to be');
}

{
    can_ok($btree, 'removeRight');
    my $right = $btree->removeRight();
    isa_ok($right, 'Tree::Binary');

    ok(!$btree->hasRight(), '... we dont have a right node anymore');
    ok(!$btree->isLeaf(), '... and we are not a leaf node');

    $btree->setRight($right);

    ok($btree->hasRight(), '... we have our right node again');
    is($btree->getRight(), $right, '... and it is what we told it to be')
}

{
    # remove right leaf
    my $right_leaf = $btree->getRight()->removeRight();
    isa_ok($right_leaf, 'Tree::Binary');

    ok($right_leaf->isLeaf(), '... our right leaf is a leaf');

    ok(!$btree->getRight()->hasRight(), '... we dont have a right leaf node anymore');

    $btree->getRight()->setRight($right_leaf);

    ok($btree->getRight()->hasRight(), '... we have our right leaf node again');
    is($btree->getRight()->getRight(), $right_leaf, '... and it is what we told it to be');
}

# some of the recursive informational methods

{

    my $btree = Tree::Binary->new("o")
                            ->setLeft(
                                Tree::Binary->new("o")
                                    ->setLeft(
                                        Tree::Binary->new("o")
                                    )
                                    ->setRight(
                                        Tree::Binary->new("o")
                                            ->setLeft(
                                                Tree::Binary->new("o")
                                                    ->setLeft(
                                                        Tree::Binary->new("o")
                                                            ->setRight(Tree::Binary->new("o"))
                                                    )
                                            )
                                    )
                            )
                            ->setRight(
                                Tree::Binary->new("o")
                                            ->setLeft(
                                                Tree::Binary->new("o")
                                                    ->setRight(
                                                        Tree::Binary->new("o")
                                                            ->setLeft(
                                                                Tree::Binary->new("o")
                                                            )
                                                            ->setRight(
                                                                Tree::Binary->new("o")
                                                            )
                                                    )
                                            )
                                            ->setRight(
                                                Tree::Binary->new("o")
                                                    ->setRight(Tree::Binary->new("o"))
                                            )
                            );
    isa_ok($btree, 'Tree::Binary');

    can_ok($btree, 'size');
    cmp_ok($btree->size(), '==', 14, '... we have 14 nodes in the tree');

    can_ok($btree, 'height');
    cmp_ok($btree->height(), '==', 6, '... the tree is 6 nodes tall');

}

