use strict;
use warnings;


while (1)
{
    $_ = make_choice();
    /^1$/ and do { mysql(); last };
    /^2$/ and do { skip();  last };
}


sub make_choice
{
    print "\n\n";
    print "Choose which driver to test\n";
    print "[1] MySQL\n";
    print "[2] Skip Tests\n";
    my $choice = <STDIN>;
    chomp ($choice);
    return $choice;
}


sub mysql
{
    print "DSN String ['DBI:mysql:database=test']: ";
    my $dsn = <STDIN>;
    chomp ($dsn);
    $dsn = 'DBI:mysql:database=test' unless ($dsn);

    print "User ['root']: ";
    my $user = <STDIN>;
    chomp ($user);
    $user = 'root' unless ($user);

    print "Password [undef]: ";
    my $pass = <STDIN>;
    chomp ($pass);
    $pass = '' unless ($user);
    
    print "Writing driver info... ";
    open FP, ">t/driver.nfo" or die "Cannot write-open t/driver.nfo. Reason: $!";
    print FP <<EOF;
use TripleStore::Driver::MySQL;
\$VAR1 = new TripleStore::Driver::MySQL ('$dsn', '$user', '$pass');
EOF
    close FP;
    print "OK\n";
}


sub skip
{
    print "Skipping\n";
} 


1;


__END__
