#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

BEGIN {
    use_ok('Tree::Visualize');
    use_ok('Tree::Visualize::ASCII::Layouts::Binary::Diagonal');   
};

require "t/test_lib/tree_test_lib.pl";

my $fixed_tree = <<TREE;
(7)-------------(11)-----(13)-(14)
 |                |        |      
 |                |      (12)     
 |                |               
 |              (9)-(10)          
 |               |                
 |              (8)               
 |                                
(3)-----(5)-(6)                   
 |       |                        
 |      (4)                       
 |                                
(1)-(2)                           
 |                                
(0)                               
TREE
chomp($fixed_tree);

my $btree = balanced_tree_binary();
isa_ok($btree, 'Tree::Binary::Search');

my $viz = Tree::Visualize::ASCII::Layouts::Binary::Diagonal->new();
isa_ok($viz, 'Tree::Visualize::ASCII::Layouts::Binary::Diagonal');
isa_ok($viz, 'Tree::Visualize::ASCII::Layouts::Binary');
isa_ok($viz, 'Tree::Visualize::Layout::ILayout');

is($viz->draw($btree)->getAsString(), $fixed_tree, '... draws the tree correctly');    




1;