#!/usr/bin/env perl
use warnings;
use v5.12;

use Data::Dumper;
$Data::Dumper::Indent = 0;

use Tree::Serial;
use Tree::DAG_Node;

my $lol = Tree::Serial->new({traversal => 2})->strs2lol([qw(1 2 4 . 7 . . . 3 5 . . 6 . .)]);

say Dumper($lol);
# $VAR1 = [[[['7'],'4'],'2'],[['5'],['6'],'3'],'1'];

my $tree = Tree::DAG_Node->lol_to_tree($lol);
my $diagram = $tree->draw_ascii_tree;
say map "$_\n", @$diagram; 

#         |
#        <1>
#     /-----\
#     |     |
#    <2>   <3>
#     |   /---\
#    <4>  |   |
#     |  <5> <6>
#    <7>
# 
