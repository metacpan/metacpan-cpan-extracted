#!/usr/bin/perl
#
# Copyright (C) 2011 by Opera Software Australia Pty Ltd
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
use strict;
use warnings;
package Tree::Interval::Test;
use base qw(Test::Unit::TestCase);
use Tree::Interval;
use Data::Dumper;

sub dump_node
{
    my ($node, $prefix) = @_;

    dump_node($node->left, "    $prefix")
	if $node->left;
    printf "%s{ col %d low %d high %d val \"%s\" }\n",
	$prefix, $node->color, $node->low, $node->high, $node->val;
    dump_node($node->right, "    $prefix")
	if $node->right;
}

sub dump_tree
{
    my ($tree) = @_;
    printf "\n";
    dump_node($tree->root, "");
    printf "\n";
}

sub test_basic
{
    my ($self) = @_;

    my $tree = Tree::Interval->new();
    $tree->insert(1,10,'foo');
    $tree->insert(11,20,'bar');
    $tree->insert(41,50,'foonly');
    $tree->insert(51,60,'spack');
    $tree->insert(31,40,'quux');
    $tree->insert(61,70,'meh');
    $tree->insert(21,30,'baz');

#     dump_tree($tree);

    $self->assert_null($tree->find(0));
    $self->assert_str_equals('foo', $tree->find(1));
    $self->assert_str_equals('foo', $tree->find(2));
    $self->assert_str_equals('foo', $tree->find(3));
    $self->assert_str_equals('foo', $tree->find(8));
    $self->assert_str_equals('foo', $tree->find(9));
    $self->assert_str_equals('foo', $tree->find(10));
    $self->assert_str_equals('bar', $tree->find(11));
    $self->assert_str_equals('bar', $tree->find(20));
    $self->assert_str_equals('baz', $tree->find(21));
    $self->assert_str_equals('baz', $tree->find(30));
    $self->assert_str_equals('quux', $tree->find(31));
    $self->assert_str_equals('quux', $tree->find(40));
    $self->assert_str_equals('foonly', $tree->find(41));
    $self->assert_str_equals('foonly', $tree->find(50));
    $self->assert_str_equals('spack', $tree->find(51));
    $self->assert_str_equals('spack', $tree->find(60));
    $self->assert_str_equals('meh', $tree->find(61));
    $self->assert_str_equals('meh', $tree->find(70));
    $self->assert_null($tree->find(71));
    $self->assert_null($tree->find(100));

    my (@v) = $tree->values();
    $self->assert_deep_equals([ qw(foo bar baz quux foonly spack meh) ], \@v);
}

sub test_overlapping
{
    my ($self) = @_;

    my $tree = Tree::Interval->new();
    $tree->insert(20,30,'foo');

    eval
    {
	$tree->insert(19,31,'bar');
    };
    $self->assert($@ =~ m/overlapping/i);

    eval
    {
	$tree->insert(19,21,'bar');
    };
    $self->assert($@ =~ m/overlapping/i);

    eval
    {
	$tree->insert(21,29,'bar');
    };
    $self->assert($@ =~ m/overlapping/i);

    eval
    {
	$tree->insert(29,31,'bar');
    };
    $self->assert($@ =~ m/overlapping/i);
}

1;
