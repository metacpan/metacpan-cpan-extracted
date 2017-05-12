#!/usr/bin/perl -w

use DBI;

print "Content-type: text/html\n\n";

## mysql user database name
$db ="mysql";
## mysql database user name
$user = "root";

## mysql database password
$pass = "password";

## user hostname : This should be .localhost. but it can be diffrent too
$host="localhost";

## SQL query
$query = "show tables";

$dbh = DBI->connect("DBI:mysql:$db:$host", $user, $pass);
$sqlQuery  = $dbh->prepare($query)
or die "Can't prepare $query: $dbh->errstr\n";

$rv = $sqlQuery->execute
or die "can't execute the query: $sqlQuery->errstr";

print "<h3>********** My Perl DBI Test ***************</h3>";
print "<p>Here is a list of tables in the MySQL database $db</p>";
while (@row= $sqlQuery->fetchrow_array()) {
my $tables = $row[0];
print "$tables\n<br>";
}

$rc = $sqlQuery->finish;
exit(0);
