#!/usr/bin/perl -w
use strict;
use Tree::Numbered::Tools;

# Demo for the readFile() method without using column names.
# This demo creates a tree with automatically assigned names for the extra columns.
# It is recommended to use column names, see readFile.pl for an example using column names.

my $filename = 'tree-no-column-names.txt';
my $use_column_names = 0;
my $tree = Tree::Numbered::Tools->readFile(
					   filename         => $filename,
					   use_column_names => $use_column_names,
					  );

my @columns = $tree->getColumnNames();
print join("\n", @columns);

# Print the tree
foreach ($tree->listChildNumbers) {
  print $_, " ", join(' -- ', $tree->follow($_,"Value")), "\n";
}

