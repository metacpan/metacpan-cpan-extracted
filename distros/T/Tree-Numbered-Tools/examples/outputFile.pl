#!/usr/bin/perl -w
use strict;
use Tree::Numbered::Tools;

# Demo for the readFile() and outputFile() methods.

# The source
my $filename = 'tree.txt';
my $use_column_names = 1;

# Create the tree object
my $tree = Tree::Numbered::Tools->readFile(
					   filename         => $filename,
					   use_column_names => $use_column_names,
					  );
my @column_names = $tree->getColumnNames();

# Append some extra nodes programatically
my $newnode = $tree;
foreach my $nodename ('Perl', 'Functions', 'RegExp') {
  my %hash = ();
  foreach my $column (@column_names) {
    if ($column eq 'Name') {
      $hash{Name} = $nodename;
    }
    else {
      $hash{$column} = "dummy $column";
    }
  }
  $newnode = $newnode->append(%hash);
}

# Print the tree structure using the file format
my $output = $tree->outputFile();
print $output;
