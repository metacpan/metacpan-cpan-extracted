#!perl -T

use 5.010;
use Test::More tests => 2;
use IO::Socket;

my $host = '127.0.0.1';
my $port = 6379;

my $sock = IO::Socket::INET->new(
    Proto    => "tcp",
    PeerAddr => $host,
    PeerPort => $port,
);

isa_ok( $sock, 'IO::Socket::INET' );
diag( 'Could not open socket: ' . $@ ) if $@;

my $got;
unless ($@) {
    print $sock "PING\r\n";
    shutdown $sock, 1;
    while (<$sock>) {
        $got .= $_;
    }
}

like( $got, qr/PONG/, 'testing connection string' );
1;
