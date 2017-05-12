#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 31;
use Test::Exception;

BEGIN {
    use_ok('Tree::Simple::View');
}

use Tree::Simple;

# make a tree
my $tree = Tree::Simple->new(Tree::Simple->ROOT);
isa_ok($tree, 'Tree::Simple');

# make a configuration
my %config = ( test => "test" );

# create my tree view (base class so it will die alot)
can_ok("Tree::Simple::View", 'new');

throws_ok {
    Tree::Simple::View->new()
} "Tree::Simple::View::AbstractClass", '... cannot create a Tree::Simple::View instance';

{
    package My::Tree::Simple::View;
    use parent 'Tree::Simple::View';
}

my $tree_view = My::Tree::Simple::View->new($tree, %config);
isa_ok($tree_view, 'My::Tree::Simple::View');
isa_ok($tree_view, 'Tree::Simple::View');

# check the exceptions thrown in the constructor/initializer
throws_ok {
    My::Tree::Simple::View->new()
} "Tree::Simple::View::InsufficientArguments", '... this should die from bad input';

throws_ok {
    My::Tree::Simple::View->new("Fail")
} "Tree::Simple::View::InsufficientArguments", '... this should die from bad input';

throws_ok {
    My::Tree::Simple::View->new([])
} "Tree::Simple::View::InsufficientArguments", '... this should die from bad input';

throws_ok {
    My::Tree::Simple::View->new(bless({}, "Fail"))
} "Tree::Simple::View::InsufficientArguments", '... this should die from bad input';

# test my accessors

can_ok($tree_view, 'getTree');
is($tree_view->getTree(), $tree, '... our tree is the same');

can_ok($tree_view, 'getConfig');
is_deeply($tree_view->getConfig(), \%config, '... our configs are the same');

can_ok($tree_view, 'setPathComparisonFunction');

throws_ok {
    $tree_view->setPathComparisonFunction()
} "Tree::Simple::View::InsufficientArguments", '... this should die from bad input';

# test the expandAll

can_ok($tree_view, 'expandAll');
throws_ok {
    $tree_view->expandAll();
} "Tree::Simple::View::AbstractMethod", '... this should die because it calls an abstract method';

# test the *Simple and *Complex versions of it

can_ok($tree_view, 'expandAllSimple');
throws_ok {
    $tree_view->expandAllSimple();
} "Tree::Simple::View::AbstractMethod", '... this should die because it calls an abstract method';

can_ok($tree_view, 'expandAllComplex');
throws_ok {
    $tree_view->expandAllComplex();
} "Tree::Simple::View::AbstractMethod", '... this should die because it calls an abstract method';

# test expandPath

can_ok($tree_view, 'expandPath');
throws_ok {
    $tree_view->expandPath();
} "Tree::Simple::View::AbstractMethod", '... this should die because it calls an abstract method';

# test the *Simple and *Complex versions of it

can_ok($tree_view, 'expandPathSimple');
throws_ok {
    $tree_view->expandPathSimple();
} "Tree::Simple::View::AbstractMethod", '... this should die because it calls an abstract method';

can_ok($tree_view, 'expandPathComplex');
throws_ok {
    $tree_view->expandPathComplex();
} "Tree::Simple::View::AbstractMethod", '... this should die because it calls an abstract method';

# now we need to check that expandPath and expandAll
# work as expected without a configuration present

my $tree_view2 = My::Tree::Simple::View->new($tree);
isa_ok($tree_view2, 'Tree::Simple::View');

throws_ok {
    $tree_view2->expandPath();
} "Tree::Simple::View::AbstractMethod", '... this should die because it calls an abstract method';

throws_ok {
    $tree_view2->expandAll();
} "Tree::Simple::View::AbstractMethod", '... this should die because it calls an abstract method';



