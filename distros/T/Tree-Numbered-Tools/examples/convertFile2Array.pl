#!/usr/bin/perl -w
use strict;
use Tree::Numbered::Tools;

# Demo for the convertFile2Array() method, converts a file's content into a Perl code snippet for creating an array.

# The source
my $filename = 'tree.txt';

# The output
my $use_column_names = 1;
print Tree::Numbered::Tools->convertFile2Array(
					       filename         => $filename,
					       use_column_names => $use_column_names,
					      );
