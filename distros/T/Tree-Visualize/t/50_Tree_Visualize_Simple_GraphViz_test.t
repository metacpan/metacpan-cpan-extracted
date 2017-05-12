#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

BEGIN {
    use_ok('Tree::Visualize');
    use_ok('Tree::Visualize::GraphViz::Layouts::Simple::Tree');
};

require "t/test_lib/tree_test_lib.pl";

my $num_nodes = 25;
$num_nodes = shift if @ARGV;
my $num_as_string = 0;
$num_as_string = shift if @ARGV;

lives_ok {
    my $tree = rand_tree_simple($num_nodes, $num_as_string);
    Tree::Visualize::GraphViz::Layouts::Simple::Tree->new()->draw($tree);         
} '... graph-viz works for random tree simple';

1;