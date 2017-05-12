#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
	use_ok('Tree::Simple');
};

# -------------------------

my $n0 = Tree::Simple->new("0");
my $n00= Tree::Simple->new("0");
my $n01= Tree::Simple->new("0");
my $n02= Tree::Simple->new("0");
my $n03= Tree::Simple->new("0");

$n0->addChild($n00);
$n0->addChildren(($n01, $n02, $n03));

#diag 'Auto width: ', $n0->getWidth();

is($n0 -> getWidth, 4, 'Auto-calculated width is correct');

$n0->fixWidth();

#diag 'Fixed width: ', $n0->getWidth();

is($n0 -> getWidth, 4, 'Fixed width is correct');
