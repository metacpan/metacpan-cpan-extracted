#!/usr/bin/perl

use strict;
use warnings;

#use Data::TreeDumper;

use Test::More;
use Tree::Simple;

# ---------------

my($root) = Tree::Simple -> new('Root', Tree::Simple -> ROOT);

isa_ok($root, 'Tree::Simple');

$root -> generateChild('Child 1.0');
$root -> generateChild('Child 2.0');

my($grand_childs_name) = 'Grandchild 1.1';

$root -> getChild(0) -> generateChild($grand_childs_name);

#note DumpTree($root);

my($name);

for my $i (1 .. 2)
{
	isa_ok($root -> getChild($i - 1), 'Tree::Simple', "Child $i");

	$name = $root -> getChild($i - 1) -> getNodeValue;

	ok($name eq "Child $i.0", "Retrieved value of Child $i ($name)");
}

isa_ok($root -> getChild(0) -> getChild(0), 'Tree::Simple', 'Child 1 of Child 1');

$name = $root -> getChild(0) -> getChild(0) -> getNodeValue;

ok($name eq $grand_childs_name, "Retrieved name of Child 1 of Child 1 ($name)");

done_testing;
