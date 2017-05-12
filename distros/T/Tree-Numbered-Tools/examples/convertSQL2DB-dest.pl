#!/usr/bin/perl -w
use strict;
use DBI;
use Tree::Numbered::Tools;

# Reads records using an SQL statement from a database table, and stores it in another database.
# This may be convienient migrating a MySQL table to a PostgreSQL table, for example.


# Help message
sub usage
  {
    print "\n";
    print "Usage:\n";
    print "$0 dbs1 database1 user1 password1 dbs2 database2 user2 password2\n";
    print "Examples:\n";
    print "$0 mysql test root mysqlpassword pgsql test pgsql pgsqlpassword\n";
    print "$0 pgsql test pgsql pgsqlpassword mysql test root mysqlpassword\n";
    print "\n";
    exit 1;
  }

# Check for command line argument.
my $dbs1 =         $ARGV[0] || usage();;
my $database1 =    $ARGV[1] || usage();;
my $user1 =        $ARGV[2] || usage();;
my $password1 =    $ARGV[3] || usage();;
my $dbs2 =         $ARGV[4] || usage();;
my $database2 =    $ARGV[5] || usage();;
my $user2 =        $ARGV[6] || usage();;
my $password2 =    $ARGV[7] || usage();;

my $dbh_string1 =  '';
my $dbh_string2 =  '';
SWITCH: for ($dbs1) {
  # MySQL
  /^mysql$/i        && do {
    $dbh_string1 = "DBI:mysql:database=$database1;host=localhost";
    last SWITCH;
  };
  # PgSQL
  /^postgres$|^PostgreSQL$|^pgsql$|^pg$/i         && do {
    $dbh_string1 = "DBI:Pg:database=$database1;host=localhost";
    last SWITCH;
  };
  # DEFAULT
  print STDERR "Database server type '$dbs1' is not supported.";
  usage;
}
SWITCH: for ($dbs2) {
  # MySQL
  /^mysql$/i        && do {
    $dbh_string2 = "DBI:mysql:database=$database2;host=localhost";
    last SWITCH;
  };
  # PgSQL
  /^postgres$|^PostgreSQL$|^pgsql$|^pg$/i         && do {
    $dbh_string2 = "DBI:Pg:database=$database2;host=localhost";
    last SWITCH;
  };
  # DEFAULT
  print STDERR "Database server type '$dbs2' is not supported.";
  usage;
}

# The DB handles
my $dbh = DBI->connect($dbh_string1, $user1, $password1) or die "DBI error: DBI->errstr\n";
my $dbh_dest = DBI->connect($dbh_string2, $user2, $password2) or die "DBI error: DBI->errstr\n";

# The source
my $sql = "SELECT serial, parent AS 'Parent', name AS 'Name', url as 'URL', color AS 'Color', permission AS 'Permission', visible as 'Visible' FROM treetest ORDER BY Serial";

# The destination (a different database handle)
my $table = 'treetest2';
my $drop = 1;
# The output (the created table and its records in a different destination database)
my $success = Tree::Numbered::Tools->convertSQL2DB(
						   dbh           => $dbh,
						   sql           => $sql,
						   dbh_dest      => $dbh_dest,
						   table         => $table,
						   drop          => $drop,
						  );
