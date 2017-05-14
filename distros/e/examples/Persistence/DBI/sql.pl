use DBI;
$dbname = 'DEMO732'; $user = 'scott'; 
$password = 'tiger'; $dbd = 'Oracle';

$dbh = DBI->connect($dbname,$user,$password,$dbd) ||
       die "Error connecting $DBI::errstr\n";;

while(1) {
    print "SQL> ";                      # Prompt
    $stmt = <STDIN>;
    last unless defined($stmt);
    last if ($stmt =~ /^\s*exit/);
    chomp ($stmt);
    $stmt =~ s/;\s*$//;

    $sth = $dbh->prepare($stmt);
    if ($DBI::err) {
        print STDERR "$DBI::errstr\n";
        next;
    }
    $sth->execute() ;
    if ($DBI::err) {
        print STDERR "$DBI::errstr\n";
        next;
    }
    if ($stmt =~ /^\s*select/i) {
        my $rl_names = $sth->{NAME};         # ref. to list of col. names
        while (@results = $sth->fetchrow) {  # retrieve results
            if ($DBI::err) {
                print STDERR $DBI::errstr,"\n";
                last;
            }
            foreach $field_name (@$rl_names) {
                printf "%10s: %s\n", $field_name, shift @results;
            }
            print "\n";
        }
        $sth->finish;
    }
}
$dbh->commit;
