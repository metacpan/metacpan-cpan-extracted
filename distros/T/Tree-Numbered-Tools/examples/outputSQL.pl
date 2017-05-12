#!/usr/bin/perl -w
use strict;
use Tree::Numbered::Tools;

# Demo for the outputSQL() method, creates SQL statements using MySQL or PostgreSQL syntax.

# Check for command line arg
if (!$ARGV[0])
  {
    print "\n";
    print "Usage:\n";
    print "$0 mysql\n";
    print "or\n";
    print "$0 pgsql\n";
    print "\n";
    exit;
  }

my $dbs = $ARGV[0];

# The source
my $filename = 'tree.txt';
my $use_column_names = 1;

# Create the tree object
my $tree = Tree::Numbered::Tools->readFile(
					   filename         => $filename,
					   use_column_names => $use_column_names,
					 );

# Print the SQL statements
# MySQL SQL syntax by default if 'dbs' is omitted.
# Use 'dbs' for other database server types, curently only MySQL and PgSQL are supported.
# The 'dbs' argument is case-insensitive.
# Due to the various name used, valid arg values are: postgres PostgreSQL, PgSQL, Pg
my $table = 'treetest';
print $tree->outputSQL(
		       table => $table,
		       dbs   => $dbs,
		       drop  => 1,
		      );
