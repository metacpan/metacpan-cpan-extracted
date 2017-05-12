#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

BEGIN {
    use_ok('Tree::Visualize');
    use_ok('Tree::Visualize::ASCII::Layouts::Simple::TopDown');
};

require "t/test_lib/tree_test_lib.pl";

my $num_nodes = 10;
$num_nodes = shift if @ARGV;
my $num_as_string = 0;
$num_as_string = shift if @ARGV;


lives_ok {
    my $tree = rand_tree_simple($num_nodes);    
    Tree::Visualize::ASCII::Layouts::Simple::TopDown->new()->draw($tree)->getAsString();
} '... works with random simple tree';


lives_ok {
    my $tree = Tree::Simple->new("test")
                        ->addChildren(
                            Tree::Simple->new("test-1")
                                ->addChildren(
                                    Tree::Simple->new("test-1-1")
                                    ),
                            Tree::Simple->new("test-2"),
                            Tree::Simple->new("test-3")
                            );
    Tree::Visualize::ASCII::Layouts::Simple::TopDown->new()->draw($tree);                            
} '... works with fixed simple tree';
1;