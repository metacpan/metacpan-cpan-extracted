use DBI;
$dbname = 'DEMO732'; $user = 'scott'; 
$password = 'tiger'; $dbd = 'Oracle';
$dbh = DBI->connect ($dbname, $user, $password, $dbd); 
if (!$dbh) {
     print "Error connecting to database; $DBI::errstr\n";
}


$sth = $dbh->prepare(q{select name, age from emptable where age < 40});
$sth->execute();
die "Prepare error: $DBI::err .... $DBI::errstr" if $DBI::err;

$sth->bind_columns(undef, \($name, $age));
# Column binding is the most eficient way to fetch data
while($sth->fetch) {
    print "$name: $age\n";
}

$sth->finish();

