#!/usr/bin/perl -w
use strict;
use DBI;
use Tree::Numbered::Tools;

# This examples 

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

# The SQL statement
# Easy mapping to columns using the SQL 'AS' syntax. (The column 'serial' must always exist and be lower case, though.)
my $sql = "

SELECT serial, parent AS 'Parent', name AS 

'Name', url as 'URL', color AS 'Color', 

permission AS 'Permission', visible as 'Visible' FROM treetest ORDER BY Serial





";

# Get the tree
my $tree = Tree::Numbered::Tools->readSQL(
					  dbh => $dbh,
					  sql => $sql,
					 );

# Print the tree
print "Nodes:\n";
foreach ($tree->listChildNumbers) {
  print $_, " ", join(' -- ', $tree->follow($_,"Name")), "\n";
}

# Print column names
print "\nSQL statement columns (omitting 'serial' and 'parent'):\n", join(' ', $tree->getColumnNames()), "\n";

# # # Print details about a node
print "\nDetails about node 7:\n";
my @name7 = $tree->follow(7,'Name');
my @url7 = $tree->follow(7,'URL');
print  "Name: ", pop(@name7), "\n";
print  "URL: ", pop(@url7), "\n";

