#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tree::Simple;

# ---------------------------

my($tree) = Tree::Simple->new(Tree::Simple->ROOT)
				->addChildren
					(
						Tree::Simple->new("A")
							->addChildren
								(
									Tree::Simple->new("A.1"),
									Tree::Simple->new("A.2")
								),
						Tree::Simple->new("B")
							->addChildren
								(
									Tree::Simple->new("B.1")
								),
						Tree::Simple->new("C")
					);

isa_ok($tree, 'Tree::Simple');

my(@kids) = $tree->getAllChildren;

ok(scalar(@kids) == 3, 'Root has 3 children: ' . join(', ', map{$_->getNodeValue} @kids) );

my(@expected_sibling_count) = (2, 2, 2);

for my $i (0 .. $#kids)
{
	ok($kids[$i]->getSiblingCount == $expected_sibling_count[$i], 'getSiblingCount() (' . $kids[$i]->getNodeValue .  ') returns correct value');
}

ok($kids[0]->getChild(1)->getSiblingCount == 1, $kids[0]->getChild(1)->getNodeValue . ' has 1 sibling');
ok($kids[1]->getChild(0)->getSiblingCount == 0, $kids[1]->getChild(0)->getNodeValue . ' has 0 siblings');

my(@expected_first_child) = (1, 0, 0);

for my $i (0 .. $#kids)
{
	ok($kids[$i]->isFirstChild == $expected_first_child[$i], 'isFirstChild() (' . $kids[$i]->getNodeValue .  ') returns correct value');
}

my(@expected_last_child) = (0, 0, 1);

for my $i (0 .. $#kids)
{
	ok($kids[$i]->isLastChild == $expected_last_child[$i], 'isLastChild() (' . $kids[$i]->getNodeValue .  ') returns correct value');
}

ok($kids[1]->getChild(0)->isFirstChild == 1, $kids[1]->getChild(0)->getNodeValue . ' is the first child');
ok($kids[1]->getChild(0)->isLastChild == 1, $kids[1]->getChild(0)->getNodeValue . ' is the last child');

done_testing();
