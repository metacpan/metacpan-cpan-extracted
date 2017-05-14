package DBI;
# Dummy DBI for testing Adaptors

$err = 0;
$errstr = "";

sub connect {
    bless {}, 'DBI';
}

sub do {
    my ($obj, $query) = @_;
    my ($rl_rows) = [];
    print STDERR "DBI ... $query\n";
    if ($query =~ /max.*id/) {
        $rl_rows->[0] = [100]; #
    } elsif ($query =~ /select/) {
        $cnt = $query =~ tr/,//;
        $rl_rows->[0] = [1 .. $cnt];
    } 
    $rl_rows;
}


1;