#!/usr/bin/perl -w
use strict;
use Tree::Numbered::Tools;

# Demo for the readFile() method without using column names.
# This demo creates a simple tree without any extra columns.
# You are encouraged to use column names, see readFile.pl for an example.

my $filename = 'tree-simple.txt';
my $use_column_names = 0;
my $tree = Tree::Numbered::Tools->readFile(
					   filename         => $filename,
					   use_column_names => $use_column_names,
					  );

# Print the tree
# The root node, which is not included in the text file.
my $root = $tree->getSubTree(1);
print 1, " ", $root->getValue, "\n";
# The tree itself, as defined in the text file.
foreach ($tree->listChildNumbers) {
  print $_, " ", join(' -- ', $tree->follow($_,"Value")), "\n";
}

