use DBI;
$dbname = 'DEMO732'; $user = 'scott'; 
$password = 'tiger'; $dbd = 'Oracle';
$dbh = DBI->connect ($dbname, $user, $password, $dbd); 
if (!$dbh) {
     print "Error connecting to database; $DBI::errstr\n";
}


$cur = $dbh->prepare('select name, age from emptable where age < 40');
$cur->execute();
die "Prepare error: $DBI::err .... $DBI::errstr" if $DBI::err;

while (($name, $age) = $cur->fetchrow) {
    print "Name:$name   Age: $age \n";
}
$cur->finish();

