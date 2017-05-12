#!/usr/bin/perl -w
use strict;
use Tree::Numbered::Tools;

# Demo for the readArray() method without using column names.

my $arrayref = [
		[1, 0, 'ROOT', 'ROOT'],
		[2, 1, 'File', 'file.pl'],
		[3, 2, 'New', 'file-new.pl'],
		[4, 3, 'Window', 'file-new-window.pl'],
		[5, 3, 'Template', 'file-new-template.pl'],
		[6, 2, 'Open', 'file-open.pl'],
		[7, 2, 'Save', 'file-save.pl'],
		[8, 2, 'Close', 'file-close.pl'],
		[9, 2, 'Exit', 'file-exit.pl'],
		[10, 1, 'Edit', 'edit.pl'],
		[11, 10, 'Undo', 'edit-undo.pl'],
		[12, 10, 'Cut', 'edit-cut.pl'],
		[13, 10, 'Copy', 'edit-copy.pl'],
		[14, 10, 'Paste', 'edit-paste.pl'],
		[15, 10, 'Find', 'edit-find.pl'],
		[16, 1, 'View', 'view.pl'],
		[17, 16, 'Toolbars', 'view-toolbars.pl'],
		[18, 17, 'Navigation', 'view-toolbars-navigation.pl'],
		[19, 17, 'Location', 'view-toolbars-location.pl'],
		[20, 17, 'Personal', 'view-toolbars-personal.pl'],
		[21, 16, 'Reload', 'view-reload.pl'],
		[22, 16, 'Source', 'view-source.pl'],
	       ];

my $use_column_names = 0;

my $tree = Tree::Numbered::Tools->readArray(
					    arrayref         => $arrayref,
					    use_column_names => $use_column_names,
					   );

my @columns = $tree->getColumnNames();

# Print the tree
foreach ($tree->listChildNumbers) {
  print $_, " ", join(' -- ', $tree->follow($_,"Value")), "\n";
}

# # Print details about a node
my $node = 7;
print "\nDetails about node $node:\n";
foreach my $column (@columns) {
  my @values = $tree->follow($node, $column);
  print  "$column: ", pop(@values), "\n";
}
