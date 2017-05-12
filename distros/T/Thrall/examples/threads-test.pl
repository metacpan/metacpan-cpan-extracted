#!/usr/bin/perl

use strict;
use threads;
require Socket;

sub process_connection {
    my ($sock) = @_;

    setsockopt $sock, Socket::IPPROTO_TCP(), Socket::TCP_NODELAY(), 1
        or die "setsockopt: $!";

    while (my $line = <$sock>) {
        $line =~ s/\015?\012$//;
        if ($line =~ /^$/) {
            print $sock "HTTP/1.0 200 OK\015\012Content-Type: text/plain\015\012\015\012Hello, world!\015\012";
            last;
        };
    };
    close $sock;
}

socket my $server, Socket::AF_INET(), Socket::SOCK_STREAM(), 0 or die "socket: $!";
setsockopt $server, Socket::SOL_SOCKET(), Socket::SO_REUSEADDR(), pack("l", 1) or die "setsockopt: $!";
bind $server, Socket::pack_sockaddr_in($ARGV[0] || 5000, "\x00\x00\x00\x00") or die "bind: $!";
listen $server, Socket::SOMAXCONN() or die "listen: $!";

sub worker {
    my ($n, $server) = @_;
    while(accept my $client, $server) {
        process_connection($client);
    }
}

for my $n (1..20) {
    my $thr = threads->create(\&worker, $n, $server);
}

foreach my $thr (threads->list) {
    $thr->join;
}
