#!/usr/bin/env perl

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.
use open     qw(:std :utf8); # Undeclared streams in UTF-8.

use File::Spec;

use File::Slurp::Tiny 'read_file';

use Tree::DAG_Node;

# ------------------------------------------------

my($node)            = Tree::DAG_Node -> new;
my($input_file_name) = File::Spec -> catfile('t', "tree.utf8.attributes.txt");
my($root)            = $node -> read_tree($input_file_name);

print "Output from draw_ascii_tree: \n";
print join("\n", @{$root -> draw_ascii_tree}), "\n";
print "\n";
print "Output from tree2string(): \n";
print join("\n", @{$root -> tree2string}), "\n";
print "\n";
print "Output from decode_lol(tree_to_lol): \n";
print join("\n", @{$root -> decode_lol($root -> tree_to_lol)}), "\n";
print "\n";
print "Output from tree_to_lol_notation({multiline => 0}): \n";
print $root -> tree_to_lol_notation({multiline => 0}), "\n";
print "\n";
print "Output from tree_to_lol_notation({multiline => 1}): \n";
print $root -> tree_to_lol_notation({multiline => 1}), "\n";
print "\n";
print "Output from decode_lol(tree_to_simple_lol): \n";
print join("\n", @{$root -> decode_lol($root -> tree_to_simple_lol)}), "\n";
print "\n";
print "Output from tree_to_simple_lol_notation({multiline => 0}): \n";
print $root -> tree_to_simple_lol_notation({multiline => 0}), "\n";
print "\n";
print "Output from tree_to_simple_lol_notation({multiline => 1}): \n";
print $root -> tree_to_simple_lol_notation({multiline => 1});
print "\n";
