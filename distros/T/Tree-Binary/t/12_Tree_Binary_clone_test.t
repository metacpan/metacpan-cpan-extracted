use strict;
use warnings;

use Test::More tests => 47;

BEGIN {
    use_ok('Tree::Binary');
}

## ----------------------------------------------------------------------------
# NOTE:
# This specifically tests the details of the cloning functions
## ----------------------------------------------------------------------------

my $btree = Tree::Binary->new("ROOT");

my $test = "test";

my $SCALAR_REF = \$test;
my $REF_TO_REF = \$SCALAR_REF;
my $ARRAY_REF = [ 1, 2, 3, 4 ];
my $HASH_REF = { one => 1, two => 2 };
my $CODE_REF = sub { "code ref test" };
my $REGEX_REF = qr/^reg-ex ref/;
my $SUB_TREE = Tree::Binary->new("sub tree test");
my $MISC_OBJECT = bless({}, "Misc");

$btree->setLeft(Tree::Binary->new("non-ref")
                            ->setLeft(Tree::Binary->new($SCALAR_REF)
                                                  ->setLeft(Tree::Binary->new($MISC_OBJECT))
                                                  ->setRight(Tree::Binary->new($REF_TO_REF))
                            )
                            ->setRight(Tree::Binary->new($CODE_REF))
                )
      ->setRight(Tree::Binary->new($ARRAY_REF)
                            ->setRight(Tree::Binary->new($HASH_REF))
                            ->setLeft(Tree::Binary->new($REGEX_REF)
                                                   ->setRight(Tree::Binary->new($SUB_TREE))
                            )
                );

my $clone = $btree->clone();

# make sure all the parentage is correct
ok(!defined($clone->getParent()), '... the clones parent is not defined');

isnt($clone, $btree, '... these should be refs');

is($clone->getLeft()->getNodeValue(), $btree->getLeft()->getNodeValue(), '... these should be the same value');

is($clone->getLeft()->getParent(), $clone, '... the parentage should be correct');

# they should both be scalar refs
is(ref($clone->getLeft()->getLeft()->getNodeValue()), "SCALAR", '... these should be scalar refs');
is(ref($btree->getLeft()->getLeft()->getNodeValue()), "SCALAR", '... these should be scalar refs');
# but different ones
isnt($clone->getLeft()->getLeft()->getNodeValue(), $btree->getLeft()->getLeft()->getNodeValue(),
	'... these should be different scalar refs');
# with the same value
is(${$clone->getLeft()->getLeft()->getNodeValue()}, ${$btree->getLeft()->getLeft()->getNodeValue()},
	'... these should be the same value');

is($clone->getLeft()->getLeft()->getParent(), $clone->getLeft(), '... the parentage should be correct');

# they should both be array refs
is(ref($clone->getRight()->getNodeValue()), "ARRAY", '... these should be array refs');
is(ref($btree->getRight()->getNodeValue()), "ARRAY", '... these should be array refs');
# but different ones
isnt($clone->getRight()->getNodeValue(), $btree->getRight()->getNodeValue(),
	'... these should be different array refs');
# with the same value
is_deeply($clone->getRight()->getNodeValue(), $btree->getRight()->getNodeValue(),
	'... these should have the same contents');

is($clone->getRight()->getParent(), $clone, '... the parentage should be correct');

# they should both be hash refs
is(ref($clone->getRight()->getRight()->getNodeValue()), "HASH", '... these should be hash refs');
is(ref($btree->getRight()->getRight()->getNodeValue()), "HASH", '... these should be hash refs');
# but different ones
isnt($clone->getRight()->getRight()->getNodeValue(), $btree->getRight()->getRight()->getNodeValue(),
	'... these should be different hash refs');
# with the same value
is_deeply($clone->getRight()->getRight()->getNodeValue(), $btree->getRight()->getRight()->getNodeValue(),
	'... these should have the same contents');

is($clone->getRight()->getRight()->getParent(), $clone->getRight(), '... the parentage should be correct');

# they should both be code refs
is(ref($clone->getLeft()->getRight()->getNodeValue()), "CODE", '... these should be code refs');
is(ref($btree->getLeft()->getRight()->getNodeValue()), "CODE", '... these should be code refs');
# and still the same
is($clone->getLeft()->getRight()->getNodeValue(), $btree->getLeft()->getRight()->getNodeValue(),
	'... these should be the same code refs');

is($clone->getLeft()->getRight()->getNodeValue()->(), $CODE_REF->(), '... this is equal');

is($clone->getLeft()->getRight()->getParent(), $clone->getLeft(), '... the parentage should be correct');

# they should both be reg-ex refs
is(ref($clone->getRight()->getLeft()->getNodeValue()), "Regexp", '... these should be reg-ex refs');
is(ref($btree->getRight()->getLeft()->getNodeValue()), "Regexp", '... these should be reg-ex refs');
# and still the same
is($clone->getRight()->getLeft()->getNodeValue(), $btree->getRight()->getLeft()->getNodeValue(),
	'... these should be the same reg-ex refs');

is($clone->getRight()->getLeft()->getParent(), $clone->getRight(), '... the parentage should be correct');

# they should both be misc object refs
is(ref($clone->getLeft()->getLeft()->getLeft()->getNodeValue()), "Misc", '... these should be misc object refs');
is(ref($btree->getLeft()->getLeft()->getLeft()->getNodeValue()), "Misc", '... these should be misc object refs');
# and still the same
is($clone->getLeft()->getLeft()->getLeft()->getNodeValue(), $btree->getLeft()->getLeft()->getLeft()->getNodeValue(),
	'... these should be the same misc object refs');

is($clone->getLeft()->getLeft()->getLeft()->getParent(), $clone->getLeft()->getLeft(), '... the parentage should be correct');

# they should both be misc object refs
is(ref($clone->getLeft()->getLeft()->getRight()->getNodeValue()), "REF", '... these should be ref to ref refs');
is(ref($btree->getLeft()->getLeft()->getRight()->getNodeValue()), "REF", '... these should be ref to ref refs');
# and still the same
isnt(${$clone->getLeft()->getLeft()->getRight()->getNodeValue()}, ${$btree->getLeft()->getLeft()->getRight()->getNodeValue()},
	'... these should be the same REF refs');
# and still the same
is(${${$clone->getLeft()->getLeft()->getRight()->getNodeValue()}}, ${${$btree->getLeft()->getLeft()->getRight()->getNodeValue()}},
	'... these should be the same REF refs');

is($clone->getLeft()->getLeft()->getRight()->getParent(), $clone->getLeft()->getLeft(), '... the parentage should be correct');

# they should both be Tree::Binary objects
is(ref($clone->getRight()->getLeft()->getRight()->getNodeValue()), "Tree::Binary", '... these should be Tree::Binary');
is(ref($btree->getRight()->getLeft()->getRight()->getNodeValue()), "Tree::Binary", '... these should be Tree::Binary');
# but different ones
isnt($clone->getRight()->getLeft()->getRight()->getNodeValue(), $btree->getRight()->getLeft()->getRight()->getNodeValue(),
	'... these should be different Tree::Binary objects');
# with the same value
is($clone->getRight()->getLeft()->getRight()->getNodeValue()->getNodeValue(), $btree->getRight()->getLeft()->getRight()->getNodeValue()->getNodeValue(),
	'... these should have the same contents');

is($clone->getRight()->getLeft()->getRight()->getParent(), $clone->getRight()->getLeft(), '... the parentage should be correct');

# test cloneShallow

my $shallow_clone = $btree->cloneShallow();

isnt($shallow_clone, $btree, '... these should be refs');

is_deeply(
		[ $shallow_clone->getLeft(), $shallow_clone->getRight() ],
		[ $btree->getLeft(), $btree->getRight() ],
		'... the children are the same');

my $sub_tree = $btree->getRight()->getLeft()->getRight();
my $sub_tree_clone = $sub_tree->cloneShallow();
# but different ones
isnt($sub_tree_clone->getNodeValue(), $sub_tree->getNodeValue(),
	'... these should be different Tree::Binary objects');
# with the same value
is($sub_tree_clone->getNodeValue()->getNodeValue(), $sub_tree->getNodeValue()->getNodeValue(),
	'... these should have the same contents');

