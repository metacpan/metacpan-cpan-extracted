#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

use Tree::Simple;
  use Tree::Simple::Visitor;

BEGIN {
	use_ok('Tree::Simple::Visitor');
};

# create a visitor instance
my $visitor = Tree::Simple::Visitor->new();

$visitor -> includeTrunk(1);

# create a tree to visit
my $tree = Tree::Simple -> new
	(
		'0.0',
		Tree::Simple -> ROOT
	) -> addChildren
		(
			Tree::Simple -> new('1.0'),
			Tree::Simple -> new('2.0') -> addChild
				(
					Tree::Simple -> new('2.1.0')
				),
			Tree::Simple -> new('3.0')
		);

# by default this will collect all the
# node values in depth-first order into
# our results

$tree->accept($visitor);

# get our results and print them

my($result) = join ', ', $visitor->getResults();

is($result, '0.0, 1.0, 2.0, 2.1.0, 3.0', 'Visit returns correct nodes');

