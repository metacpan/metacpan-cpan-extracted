use RPC; 

my $host = 'localhost';
my $port = 1300;
my $prog;

foreach $arg (@ARGV) {
    if ($arg eq '-server') {
        server_start();
    } elsif ($arg eq '-client') {
        client_start();
    }
}

#----------------------------------------------------------------------
# Server stuff
sub ask_sheep { 
    print STDERR "Question: @_\n";
    return "No";
}

sub add {
    my ($a, $b) = @_;
    return wantarray ? ('The result is ', $a+$b) : $a+$b;
}

sub server_start() {
    RPC->new_server($host, $port);
    print "RPC Server created\nStart the client now\n";
    RPC->event_loop();
}

#----------------------------------------------------------------------
# Client stuff
sub client_start() {
    $conn1 = RPC->connect($host, $port);
    print "Client RPC connection initialized. Sending msgs\n";
    my $i;
    my $answer;
    my $question = "Ba ba black sheep, have you any wool ?";
    print "Question: $question\n";
    $answer = $conn1->rpc('ask_sheep', $question);
    print "Answer:   $answer\n\n";

    print "Question: Sum of 10 and 34.5?\n";
    ($a, $b) = $conn1->rpc ('add', 10, 34.5);
    # Note: "add" in the server checks wantarray
    print "Answer:   $a $b\n";
}

exit(0);

