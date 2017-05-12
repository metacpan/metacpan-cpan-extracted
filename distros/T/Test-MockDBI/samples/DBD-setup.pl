# Create a sample database zipcodes.* using DBD::DBM,
# which ships with DBI.

# ------ use/require pragmas
use strict;                             # better compile-time checking
use warnings;                           # better run-time warnings
use DBI;                                # database interface


# ------ define variables
my $dbh = "";                           # DBI handle



# ------ create database sample table
$dbh = DBI->connect("dbi:DBM:");
$dbh->do(qq{
 CREATE TABLE
  zipcodes
 (
  last_modified TEXT
 )
});
$dbh->do(qq{
 INSERT INTO
  zipcodes
 VALUES
 (
  '1970-01-01'
 )
});
