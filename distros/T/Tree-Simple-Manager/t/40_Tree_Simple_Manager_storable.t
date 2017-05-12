#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;

BEGIN {
    use_ok('Tree::Simple::Manager');
}

{

    my $tree_manager = Tree::Simple::Manager->new(
        'Test Tree' => {
            tree_root       => Tree::Simple->new(Tree::Simple->ROOT),
            tree_file_path  => "t/test.tree",
            tree_cache_path => "t/test.tree.cache",
            }
        );
    isa_ok($tree_manager, 'Tree::Simple::Manager');
    
    ok(!$tree_manager->isTreeLoadedFromCache('Test Tree'), '... tree is not loaded from Cache');
    
    my $tree = $tree_manager->getRootTree("Test Tree");
    isa_ok($tree, 'Tree::Simple');

    my @nodes;
    $tree->traverse(sub {
        my $t = shift;
        push @nodes => $t->getNodeValue;
    });

    is_deeply( 
    \@nodes,     
    [qw/O I I.I I.II I.II.I II II.I II.I.I III III.I III.II IV/],
    '... got all the right nodes for the tree');

}

{

    my $tree_manager = Tree::Simple::Manager->new(
        'Test Tree' => {
            tree_root       => Tree::Simple->new(Tree::Simple->ROOT),
            tree_file_path  => "t/test.tree",
            tree_cache_path => "t/test.tree.cache",
            }
        );
    isa_ok($tree_manager, 'Tree::Simple::Manager');
    
    ok($tree_manager->isTreeLoadedFromCache('Test Tree'), '... tree *is* loaded from Cache');    
    
    my $tree = $tree_manager->getRootTree("Test Tree");
    isa_ok($tree, 'Tree::Simple');

    my @nodes;
    $tree->traverse(sub {
        my $t = shift;
        push @nodes => $t->getNodeValue;
    });

    is_deeply( 
    \@nodes,     
    [qw/O I I.I I.II I.II.I II II.I II.I.I III III.I III.II IV/],
    '... got all the right nodes for the tree');

}

use File::stat;
my $t = stat('t/test.tree')->mtime - 10;
utime $t, $t, 't/test.tree.cache';

{

    my $tree_manager = Tree::Simple::Manager->new(
        'Test Tree' => {
            tree_root       => Tree::Simple->new(Tree::Simple->ROOT),
            tree_file_path  => "t/test.tree",
            tree_cache_path => "t/test.tree.cache",
            }
        );
    isa_ok($tree_manager, 'Tree::Simple::Manager');
    
    ok(!$tree_manager->isTreeLoadedFromCache('Test Tree'), '... tree is not loaded from Cache');
    
    my $tree = $tree_manager->getRootTree("Test Tree");
    isa_ok($tree, 'Tree::Simple');

    my @nodes;
    $tree->traverse(sub {
        my $t = shift;
        push @nodes => $t->getNodeValue;
    });

    is_deeply( 
    \@nodes,     
    [qw/O I I.I I.II I.II.I II II.I II.I.I III III.I III.II IV/],
    '... got all the right nodes for the tree');

}

{

    my $tree_manager = Tree::Simple::Manager->new(
        'Test Tree' => {
            tree_root       => Tree::Simple->new(Tree::Simple->ROOT),
            tree_file_path  => "t/test.tree",
            tree_cache_path => "t/test.tree.cache",
            }
        );
    isa_ok($tree_manager, 'Tree::Simple::Manager');
    
    ok($tree_manager->isTreeLoadedFromCache('Test Tree'), '... tree *is* loaded from Cache');    
    
    my $tree = $tree_manager->getRootTree("Test Tree");
    isa_ok($tree, 'Tree::Simple');

    my @nodes;
    $tree->traverse(sub {
        my $t = shift;
        push @nodes => $t->getNodeValue;
    });

    is_deeply( 
    \@nodes,     
    [qw/O I I.I I.II I.II.I II II.I II.I.I III III.I III.II IV/],
    '... got all the right nodes for the tree');

}

unlink 't/test.tree.cache';
