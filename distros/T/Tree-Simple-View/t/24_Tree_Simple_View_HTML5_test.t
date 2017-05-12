#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tree::Simple;
use Tree::Simple::View::HTML;

# ---------------------------

my($tree) = Tree::Simple->new(Tree::Simple->ROOT)
				->addChildren
					(
						Tree::Simple->new("1")
							->addChildren
								(
									Tree::Simple->new("1.1"),
									Tree::Simple->new("1.2")
								),
						Tree::Simple->new("2")
							->addChildren
								(
									Tree::Simple->new("2.1")
								),
						Tree::Simple->new("3")
					);

isa_ok($tree, 'Tree::Simple');

can_ok("Tree::Simple::View::HTML", 'new');
can_ok("Tree::Simple::View::HTML", 'expandAll');

{
	my($tree_view) = Tree::Simple::View::HTML->new($tree, html5 => 1);

	isa_ok($tree_view, 'Tree::Simple::View::HTML');

	my($output) = $tree_view->expandAll();

	ok($output, '... make sure we got some output');

	my($expected) = <<EXPECTED;
<UL>
<LI>1
<UL>
<LI>1.1
</LI>
<LI>1.2
</LI>
</UL>
</LI>
<LI>2
<UL>
<LI>2.1
</LI>
</UL>
</LI>
<LI>3
</LI>
</UL>
EXPECTED

	chomp $expected;

	is($output, $expected, '... got what we expected');
}

{
	my($tree_view) = Tree::Simple::View::HTML->new($tree, html5 => 1);

	isa_ok($tree_view, 'Tree::Simple::View::HTML');

	$tree_view->includeTrunk(1);

	my($output) = $tree_view->expandAll();
	ok($output, '... make sure we got some output');

	my $expected = <<EXPECTED;
<UL>
<LI>root
<UL>
<LI>1
<UL>
<LI>1.1
</LI>
<LI>1.2
</LI>
</UL>
</LI>
<LI>2
<UL>
<LI>2.1
</LI>
</UL>
</LI>
<LI>3
</LI>
</UL>
</LI>
</UL>
EXPECTED

	chomp $expected;

	is($output, $expected, '... got what we expected');
}

done_testing();
