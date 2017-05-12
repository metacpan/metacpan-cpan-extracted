#!/usr/bin/perl -w
use strict;
use DBI;
use Tree::Numbered::Tools;

# Demo for the convertDB2SQL() method, converts database reords from a database table to SQL syntax to be inserted into another table.

# Help message
sub usage
  {
    print "\n";
    print "Usage:\n";
    print "$0 mysql [database [user [password]]]\n";
    print "or\n";
    print "$0 pgsql [database [user [password]]]\n";
    print "Examples:\n";
    print "$0 mysql test root mysecret\n";
    print "$0 pgsql test pgsql mysecret\n";
    print "Note:\n";
    print "In this demo, the first argument (mysql or pgsql) just indicates the output SQL format.\n";
    print "\n";
    exit 1;
  }

# Check for command line argument.
if (!$ARGV[0])
  {
    usage();
  }

my $dbs = $ARGV[0];
my $user = '';
my $password = '';
my $database = '';
my $dbh_string = '';
SWITCH: for ($dbs) {
  # MySQL
  /^mysql$/i        && do {
    $database = $ARGV[1] || 'test';
    $user = $ARGV[2] || 'root';
    $password = $ARGV[3] || '';
    $dbh_string = "DBI:mysql:database=$database;host=localhost";
    last SWITCH;
  };
  # PgSQL
  /^postgres$|^PostgreSQL$|^pgsql$|^pg$/i         && do {
    $database = $ARGV[1] || 'test';
    $user = $ARGV[2] || 'pgsql';
    $password = $ARGV[3] || '';
    $dbh_string = "DBI:Pg:database=$database;host=localhost";
    last SWITCH;
  };
  # DEFAULT
  print STDERR "Database server type '$dbs' is not supported.";
  usage;
}

# The DB handle
my $dbh = DBI->connect($dbh_string, $user, $password) or die "DBI error: DBI->errstr\n";

# The source
my $table = 'treetest';

# The destination
my $table_dest = 'treetest2';

# The output
print Tree::Numbered::Tools->convertDB2SQL(
					   dbh           => $dbh,
					   table         => $table,
					   table_dest    => $table_dest,
					   dbs           => $dbs,
					   drop          => 1,
					  );
