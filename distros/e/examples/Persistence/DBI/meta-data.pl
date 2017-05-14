use DBI;
$dbname = 'DEMO732'; $user = 'scott'; 
$password = 'tiger'; $dbd = 'Oracle';
$dbh = DBI->connect ($dbname, $user, $password, $dbd); 
if (!$dbh) {
     print "Error connecting to database; $DBI::errstr\n";
}


$sth = $dbh->prepare('select * from emptable where 1=0');
$sth->execute();
die "Prepare error: $DBI::err .... $DBI::errstr" if $DBI::err;
$rl_names = $sth->{NAME};         # ref. to list of col. names
$sth->finish;

print "Columns in emptable:\n\t";
$, = "\n\t";
print @$rl_names;

$dbh->disconnect();
