#! /usr/local/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Velocis::SQL;
$loaded = 1;
print "ok 1\n";


print "Revision: $Velocis::SQL::VERSION\n";

$conn = db_connect("db-one","khera","Pr1nces")
  or die "could not connect -- ($Velocis::errorstate) $Velocis::errorstr";

$q = execute $conn "SELECT * FROM cbd WHERE item='aaa' and issue_date=19960715";

$q || die "Error in query -- ($Velocis::errorstate) $Velocis::errorstr";
$cols = $q->numcolumns();

print "Query has $cols columns\n";

print "yep\n" if (7 == SQL_REAL);
print "nope\n" if (7 != SQL_REAL);

foreach (0..$cols) {		# goes one extra to test error checking
  print "Column name: ", $q->columnname($_),
  " Type: ", $q->columntype($_),
  " Length: ", $q->columnlength($_),"\n";
}

$" = ', ';
while (@a = $q->fetchrow()) {
  print "@a\n";
}

undef $q;
undef $conn;

exit(0);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

