#!/usr/bin/perl -w
use strict;
use Tree::Numbered::Tools;

# Demo for the outputArray() method.

# The source
my $filename = 'tree.txt';
my $use_column_names = 1;

# Create the tree object
my $tree = Tree::Numbered::Tools->readFile(
					   filename         => $filename,
					   use_column_names => $use_column_names,
					 );

# Print the code to be used for cut n' paste in a Perl program.
print $tree->outputArray();
