#!/usr/bin/perl -w
use strict;
use Tree::Numbered::Tools;

# Demo for the convertFile2SQL() method, converts a file's content into SQL statements.

# Help message
sub usage
  {
    print "\n";
    print "Usage:\n";
    print "$0 mysql\n";
    print "or\n";
    print "$0 pgsql\n";
    print "\n";
    exit 1;
  }

# Check for command line argument.
if (!$ARGV[0])
  {
    usage();
  }

my $dbs = $ARGV[0];
SWITCH: for ($dbs) {
  # MySQL
  /^mysql$/i        && do {
    last SWITCH;
  };
  # PgSQL
  /^postgres$|^PostgreSQL$|^pgsql$|^pg$/i         && do {
    last SWITCH;
  };
  # DEFAULT
  print STDERR "Database server type '$dbs' is not supported.";
  usage;
}

# The source
my $filename = 'tree.txt';

# The output
my $use_column_names = 1;
my $table = 'treetest';
my $drop = 1;
print Tree::Numbered::Tools->convertFile2SQL(
					     filename         => $filename,
					     use_column_names => $use_column_names,
					     table            => $table,
					     dbs              => $dbs,
					     drop             => $drop,
					    );
