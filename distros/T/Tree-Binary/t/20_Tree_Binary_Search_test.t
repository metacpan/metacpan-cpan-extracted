use strict;
use warnings;

use Test::More tests => 43;
use Test::Exception;

BEGIN {
    use_ok('Tree::Binary::Search');
}

can_ok("Tree::Binary::Search", 'new');

my $btree = Tree::Binary::Search->new();

isa_ok($btree, 'Tree::Binary::Search');

can_ok($btree, 'insert');
can_ok($btree, 'select');
can_ok($btree, 'update');
can_ok($btree, 'exists');
can_ok($btree, 'max_key');
can_ok($btree, 'min_key');
can_ok($btree, 'max');
can_ok($btree, 'min');
can_ok($btree, 'size');
can_ok($btree, 'height');

can_ok($btree, 'useNumericComparison');
$btree->useNumericComparison();

ok(!$btree->exists(0), '... no keys yet exist');

$btree->insert(9 => 'A');
$btree->insert(7 => 'B');
$btree->insert(14 => 'C');
$btree->insert(8 => 'D');
$btree->insert(6 => 'E');
$btree->insert(2 => 'F');
$btree->insert(18 => 'G');
$btree->insert(11 => 'H');
$btree->insert(1 => 'I');
$btree->insert(4 => 'J');
$btree->insert(3 => 'K');
$btree->insert(20 => 'L');

throws_ok {
    $btree->insert(9 => 'X');
} qr/Illegal Operation/, '... this should die';

ok($btree->exists(11), '... this key exists');
ok(!$btree->exists(30), '... this key does not exists');
ok(!$btree->exists(0), '... this key does not exists');

is($btree->select(7),  'B', '... found what we were looking for');
is($btree->select(14), 'C', '... found what we were looking for');
is($btree->select(8),  'D', '... found what we were looking for');
is($btree->select(6),  'E', '... found what we were looking for');
is($btree->select(2),  'F', '... found what we were looking for');
is($btree->select(18), 'G', '... found what we were looking for');
is($btree->select(11), 'H', '... found what we were looking for');
is($btree->select(1),  'I', '... found what we were looking for');
is($btree->select(4),  'J', '... found what we were looking for');
is($btree->select(3),  'K', '... found what we were looking for');
is($btree->select(20), 'L', '... found what we were looking for');

throws_ok {
    $btree->select(100);
} qr/Key Does Not Exist/, '... this should die';

$btree->update(18 => 'Z');
$btree->update(11 => 'X');

is($btree->select(18), 'Z', '... found what we were looking for');
is($btree->select(11), 'X', '... found what we were looking for');

is($btree->max_key(), '20', '... got the max key');
is($btree->min_key(), '1',  '... got the min key');
is($btree->max(), 'L', '... got the max value');
is($btree->min(), 'I', '... got the min value');

cmp_ok($btree->size(), '==', 12, '... we have 12 nodes in the tree');
cmp_ok($btree->height(), '==', 6, '... the tree is 6 nodes tall');

## test some misc. items

{
    # create a subclass of Tree::Binary::Search::Node
    # to test the root feature of the Tree::Binary::Search
    # constructor
    {
        package BinaryTreeNode;
        @BinaryTreeNode::ISA = qw(Tree::Binary::Search::Node);
    }

    my $btree2 = Tree::Binary::Search->new("BinaryTreeNode");
    isa_ok($btree2, 'Tree::Binary::Search');

    # use this because I haven't yet
    can_ok($btree2, 'useStringComparison');
    $btree2->useStringComparison();

    # insert 3 things to give the comparison
    # routine some exercise
    $btree2->insert(A => 'a');
    $btree2->insert(B => 'b');
    $btree2->insert(BinaryTreeNode->new(C => 'c'));

    # now check that our subclass came out right
    my $tree = $btree2->getTree();
    isa_ok($tree, 'BinaryTreeNode');
    isa_ok($tree, 'Tree::Binary::Search::Node');

}
