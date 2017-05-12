#!/usr/bin/perl

use warnings;
use strict;
use Benchmark qw(:all);

use Tree::Easy;
use Tree::Fast;
use Tree::Node;

sub make_easy_tree
{
    my $tree = Tree::Easy->new('foo');
    my $node = $tree->push_new('bar');
    $node = $node->push_new('baz');
    $tree->traverse( sub {}, -1 );
    $tree->search('foo');
    return $tree;
}

sub make_fast_tree
{
    my $tree = Tree::Fast->new('foo');
    my $node  = Tree::Fast->new('bar');
    $tree->add_child( {}, $node );
    $node->add_child( {}, Tree::Fast->new('baz') );
    my $traverser = $tree->traverse();
    while ($traverser->()) { ; }

    my $searcher = $tree->traverse();
    while ( my $node = $searcher->() ) {
        last if $node->value eq 'foo';
    }
    return $tree;
}

sub traverse_tree_node
{
    my $node = shift;
    for my $child ( $node->get_children ) {
        next unless defined $child;
        traverse_tree_node($child);
    }
}

sub search_tree_node
{
    my ($node, $findme) = @_;

    for my $child ( $node->get_children ) {
        next unless defined $child;
        return 1 if ( search_tree_node($child, $findme) );
    }

    return 1 if ( $node->value && $node->value eq $findme );
    return 0
}

sub make_tree_node
{
    my $tree = Tree::Node->new(1);
    my $bar = Tree::Node->new(1);
    $tree->set_value('foo');
    $bar->set_value('bar');
    $tree->set_child(0, $bar);
    my $baz = Tree::Node->new(1);
    $baz->set_value('baz');
    $bar->set_child(0, $baz);

    traverse_tree_node($tree);
    search_tree_node($tree, 'baz');

    return $tree;
}

cmpthese( 100000,
         { 'Tree::Easy' => \&make_easy_tree,
           'Tree::Fast' => \&make_fast_tree,
           'Tree::Node' => \&make_tree_node,
          }
         );

