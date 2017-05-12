#!perl

use warnings;
use strict;

use Test::More tests => 40;

BEGIN { use_ok('Tree::Predicate', ':logical'); }

my $tree;
my @t;

$tree = AND('a', 'b');
isa_ok($tree, 'Tree::Predicate');
@t = $tree->split;
is(scalar(@t), 1, 'AND-split cardinality');
is_deeply($t[0], $tree, 'AND-split equality');
is($tree->as_string, '(a AND b)', 'AND test');
$tree->negate;
is($tree->as_string, '(NOT(a) OR NOT(b))', 'negated AND');
@t = $tree->split;
is(scalar(@t), 2);
is($t[0]->as_string, 'NOT(a)');
is($t[1]->as_string, 'NOT(b)');

$tree = OR('c', 'd');
isa_ok($tree, 'Tree::Predicate');
is($tree->as_string, '(c OR d)', 'OR test');
@t = $tree->split;
is(scalar(@t), 2, 'OR-split cardinality');
isa_ok($t[0], 'Tree::Predicate::Leaf');
is($t[0]->as_string, 'c');
isa_ok($t[1], 'Tree::Predicate::Leaf');
is($t[1]->as_string, 'd');
$tree->negate;
is($tree->as_string, '(NOT(c) AND NOT(d))', 'negated OR');

$tree = NOT('x');
isa_ok($tree, 'Tree::Predicate');
is($tree->as_string, 'NOT(x)', 'NOT test');
$tree->negate;
is($tree->as_string, 'x', 'negated NOT');

$tree = AND(OR('a', 'b'), OR('c', 'd'));
is($tree->as_string, '((a OR b) AND (c OR d))', 'AND-OR test');
@t = $tree->split;
is(scalar(@t), 4, 'AND-OR split cardinality');
is($t[0]->as_string, '(a AND c)');
is($t[1]->as_string, '(a AND d)');
is($t[2]->as_string, '(b AND c)');
is($t[3]->as_string, '(b AND d)');
$tree->negate;
is($tree->as_string, '((NOT(a) AND NOT(b)) OR (NOT(c) AND NOT(d)))', 'negated AND-OR');
$tree->negate;
is($tree->as_string, '((a OR b) AND (c OR d))', 'double negative');

$tree = AND('a', OR('b', 'c'));
is($tree->as_string, '(a AND (b OR c))', 'mixed tree');
$tree->negate;
is($tree->as_string, '(NOT(a) OR (NOT(b) AND NOT(c)))', 'negated mixed tree');

# test adjustment
$tree = AND(AND('a', 'b'), AND('c', 'd'));
is($tree->as_string, '(a AND b AND c AND d)', 'after AND adjustment');

$tree = AND(NOT(OR('a', 'b')), AND('c', 'd'));
is($tree->as_string, '(NOT(a) AND NOT(b) AND c AND d)', 'more complicated post-adjustment');

# single operand stuff
$tree = OR('x');
isa_ok($tree, 'Tree::Predicate::Leaf');
is($tree->as_string, 'x', 'single operand OR');
$tree = OR($tree);
isa_ok($tree, 'Tree::Predicate::Leaf');
is($tree->as_string, 'x', 'sing operand OR');
$tree = OR(AND(qw(a b)));
is($tree->{OP}, 'AND');
is($tree->as_string, '(a AND b)', 'single operand OR');

$tree = AND(OR(qw(a b c)), OR(qw(d e f)), OR(qw(g h i)));
@t = $tree->split;
is(@t, 27);
$tree = AND(OR(qw(a b c)), OR(qw(d e f)), OR(qw(g h i)), OR(qw(j k l)));
eval { @t = $tree->split };
like($@, qr/\Atoo many children/);
