#!/usr/bin/perl -w
use strict;
use Tree::Numbered::Tools;

# Another demo for the readFile() method, displaying a family tree.

my $filename = 'tree-family.txt';
my $use_columns = 1;
my $tree = Tree::Numbered::Tools->readFile(
					   filename         => $filename,
					   use_column_names => $use_columns,
					   );
print "This is my family tree:\n";
print "-----------------------\n";
# Print the tree
foreach ($tree->listChildNumbers) {
  my @fn = $tree->follow($_,"FirstName");
  my @ln = $tree->follow($_,"LastName");
  print "    " x (@fn - 1), , pop(@fn), " ", pop(@ln), "\n";
}
print "-----------------------\n";
# Print details about a node
my @val7 = $tree->follow(7,'Value');
my @ln7 = $tree->follow(7,'LastName');
my @fn7 = $tree->follow(7,'FirstName');
my $son3 = pop(@val7);
my $son3fn = pop(@fn7);
my $son3ln = pop(@ln7);
print "My $son3 is called $son3fn $son3ln.\n";
my @freds_children = $tree->listChildNumbers(7);
print "$son3fn has ", scalar(@freds_children), " kids.\n";
print "The column names in this tree are (ordered as listed in '".$tree->getSourceName."'):\n";
my @column_names = $tree->getColumnNames();
foreach (@column_names) {
  print "$_\n";
}
