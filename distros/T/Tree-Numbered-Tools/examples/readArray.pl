#!/usr/bin/perl -w
use strict;
use Tree::Numbered::Tools;

# Demo for the readArray() method.

my $arrayref = [
		[qw(serial parent Name URL)],
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


my $tree = Tree::Numbered::Tools->readArray(
					    arrayref         => $arrayref,
					    use_column_names => 1,
					   );

# Print column names
print "\nArray column names (omitting 'serial' and 'parent'):\n", join(' ', $tree->getColumnNames()), "\n";

# Print the tree
foreach ($tree->listChildNumbers) {
  print $_, " ", join(' -- ', $tree->follow($_,"Name")), "\n";
}

# # Print details about a node
 print "\nDetails about node 7:\n";
my @s7 = $tree->follow(7,'serial');
my @name7 = $tree->follow(7,'Name');
my @url7 = $tree->follow(7,'URL');
print  "serial: ", pop(@s7), "\n";
print  "Name: ", pop(@name7), "\n";
print  "URL: ", pop(@url7), "\n";
