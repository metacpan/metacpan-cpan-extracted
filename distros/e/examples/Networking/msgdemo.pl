
# 
# testmsg.pl - Used for testing the Msg.pm module
#    Invoke as testmsg.pl {-client|-server} 
#
use Msg;
use strict;

my $i = 0;
sub rcvd_msg_from_server {
    my ($conn, $msg, $err) = @_;
    if (defined $msg) {
        die "Strange... shouldn't really be coming here\n";
    }
}

my $incoming_msg_count=0;

sub rcvd_msg_from_client {
    my ($conn, $msg, $err) = @_;
    if (defined $msg) {
        ++$i;
        my $len = length ($msg);
        print "$i ($len)\n";
    }
}

sub login_proc {
    # Unconditionally accept
    \&rcvd_msg_from_client;
}

my $host = 'localhost';
my $port = 8080;
my $prog;
foreach $prog (@ARGV) {
   if ($prog eq '-server') {
       Msg->new_server($host, $port, \&login_proc);
       print "Server created. Waiting for events";
       Msg->event_loop();
   } elsif ($prog eq '-client') {
       my $conn = Msg->connect($host, $port,
                               \&rcvd_msg_from_server);
                               
       die "Client could not connect to $host:$port\n" unless $conn;
       print "Connection successful.\n";
       my $i;
       my $msg = " " x 10000;
       for ($i = 0; $i < 100; $i++) {
           print "Sending msg $i\n";
           $conn->send_now($msg);
       }
       $conn->disconnect();
       Msg->event_loop();
   }
}

