#!/usr/bin/perl -w
use strict;
use Tree::Numbered::Tools;

# Demo for the readArray() method.

# Array not ordered by parent will FAIL with 1.01 but will WORK with 1.02.
my $arrayref_unsorted = [
                         [qw(serial parent name url)],
                         [1, 0, 'ROOT', 'ROOT'],
                         [2, 3, 'Search', 'search.pl'],            # notice this one has a parent to the next  line
                         [3, 1, 'Edit', 'edit.pl'],
                        ];

my $use_column_names = 1;

my $tree = Tree::Numbered::Tools->readArray(
					    arrayref         => $arrayref_unsorted,
					    use_column_names => $use_column_names,
					   );

# Print the tree
foreach ($tree->listChildNumbers) {
  print $_, " ", join(' -- ', $tree->follow($_,"name")), "\n";
}

# # Print details about a node
 print "\nDetails about node 3:\n";
my @name3 = $tree->follow(3,'name');
my @url3 = $tree->follow(3,'url');
print  "Name: ", pop(@name3), "\n";
print  "URL: ", pop(@url3), "\n";
