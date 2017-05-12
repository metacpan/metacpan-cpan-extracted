#perl
use warnings;
use strict;

use Test::More tests => 10;

BEGIN { use_ok('Tree::Predicate::Leaf'); }

my $leaf;

$leaf = Tree::Predicate::Leaf->new('foo');
isa_ok($leaf, 'Tree::Predicate::Leaf');
isa_ok($leaf, 'Tree::Predicate');
is($leaf->as_string, 'foo');
$leaf->negate;
is($leaf->as_string, 'NOT(foo)');
$leaf->negate;
is($leaf->as_string, 'foo');

$leaf = Tree::Predicate::Leaf->new('bar', negated => 1);
isa_ok($leaf, 'Tree::Predicate::Leaf');
is($leaf->as_string, 'NOT(bar)');
$leaf->negate;
is($leaf->as_string, 'bar');

is($leaf->operands, undef);
