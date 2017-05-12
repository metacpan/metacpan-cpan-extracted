#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

BEGIN {
    use_ok('Tree::Visualize');
};

require "t/test_lib/tree_test_lib.pl";

my $fixed_tree = <<TREE;
                                      +---+                                            
                  +-------------------| 7 |--------------------+                       
                  |                   +---+                    |                       
                +---+                                       +----+                     
       +--------| 3 |-------+                     +---------| 11 |---------+           
       |        +---+       |                     |         +----+         |           
     +---+                +---+                 +---+                   +----+         
  +--| 1 |--+          +--| 5 |--+           +--| 9 |---+            +--| 13 |---+     
  |  +---+  |          |  +---+  |           |  +---+   |            |  +----+   |     
+---+     +---+      +---+     +---+       +---+     +----+       +----+      +----+   
| 0 |     | 2 |      | 4 |     | 6 |       | 8 |     | 10 |       | 12 |      | 14 |   
+---+     +---+      +---+     +---+       +---+     +----+       +----+      +----+   
TREE
chomp($fixed_tree);

my $btree = balanced_tree_binary();
isa_ok($btree, 'Tree::Binary::Search');

my $viz;
lives_ok {
    $viz = Tree::Visualize->new($btree, 'ASCII', 'TopDown');
} '... created the visualizer ok';
isa_ok($viz, 'Tree::Visualize');

my $drawing;
lives_ok {
    $drawing = $viz->draw();
} '... drew the tree ok';
ok(defined($drawing), '... we got a drawing');
is($drawing, $fixed_tree, '... draws the tree correctly');

1;
