use DBI;
$dbname = 'DEMO732'; $user = 'scott'; 
$password = 'tiger'; $dbd = 'Oracle';
$dbh = DBI->connect ($dbname, $user, $password, $dbd); 
if (!$dbh) {
     print "Error connecting to database; $DBI::errstr\n";
}

# Create a table 
$dbh->do("create table emptable (id   char(15), 
                                 name char(40),
                                 age  integer)");

# Ignore error if it says table already created
# (Error #955 is the corresponding Oracle error
die "Error: $DBI::err .... $DBI::errstr" if $DBI::err && ($DBI::err != 955);

$sth = $dbh->prepare ('insert into emptable (id, name, age)
                                     values (?,  ?,    ?  )');
die "Error: $DBI::err .... $DBI::errstr" if $DBI::err;


#$sth->execute(200, "foobar", 45);
#die "Error: $DBI::err .... $DBI::errstr" if $DBI::err;
@ARGV = ("dbi.dat");
while (defined($line = <>)) {
    chomp($line);
    ($id, $name, $age) = split (/\t/, $line); # id, name, age separated by tab
    $sth->execute($id, $name, $age);
    die "Error: $DBI::err .... $DBI::errstr" if $DBI::err;
}


