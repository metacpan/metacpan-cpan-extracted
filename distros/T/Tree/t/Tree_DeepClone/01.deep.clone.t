use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 5;

use Tree::DeepClone;

# -----------------------

my(@alphabet)	= (qw/a b c d e f g h i j k l m n o p q r s t u v w x y z/);
my($tree)		= Tree::DeepClone -> new('root');

$tree->add_child({}, map {Tree::DeepClone -> new($_)} 1..3);

my(@raw_tree);
my($value);

for ($tree -> traverse)
{
	$value = $_ -> value;

	$_ -> meta({$value => ($value eq 'root') ? 'z' : $alphabet[$value - 1]});

	push @raw_tree, ${$_ -> meta}{$value};
}

my($clone) = $tree -> clone;

my(@cloned_tree);

for ($clone -> traverse)
{
	$value = $_ -> value;

	push @cloned_tree, ${$_ -> meta}{$value};
}

ok($#raw_tree == $#cloned_tree, 'Cloned node count correct');

for my $i (0 .. $#raw_tree)
{
	ok($raw_tree[$i] eq $cloned_tree[$i], 'Cloned node meta value correct');
}
