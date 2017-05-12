package TestServer;

use strict;
use base qw(Net::Server::Single);

sub process_request {
    my $self = shift;

    print "HTTP/1.0 200 OK\n";
    print "Content-Length: 2\n";
    print "\n";
    print "OK";
    exit(0);
}
1;
