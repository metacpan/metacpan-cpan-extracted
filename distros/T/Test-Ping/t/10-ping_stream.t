#!perl -T

# this is a (little) cleaner version of a Net::Ping test(s)
# original name: 300_ping_stream.t

use strict;
use warnings;

use Test::More tests => 22;
use Test::Ping;

SKIP: {
    if ( $ENV{'PERL_CORE'} ) {
        if ( ! $ENV{'PERL_TEST_Net_Ping'} ) {
            skip 'Network depedent test', 22;
        }

        chdir 't' if -d 't';
        @INC = qw(../lib);
    }

    eval 'require Socket' || skip 'No Socket', 22;

    if ( my $port = getservbyname( 'echo', 'tcp' ) ) {
        socket(
            *ECHO,
            &Socket::PF_INET(),
            &Socket::SOCK_STREAM(),
            ( getprotobyname 'tcp' )[2],
        );
        my $connect = connect(
            *ECHO,
            scalar &Socket::sockaddr_in(
                $port, &Socket::inet_aton('localhost')
            ),
        );

        if ( ! $connect ) {
            skip "Loopback tcp echo service is off ($!)", 22;
        }

        close *ECHO;
    } else {
        skip 'No echo port', 22;
    }

    # Test of stream protocol using loopback interface.
    #
    # NOTE:
    #   The echo service must be enabled on localhost
    #   to really test the stream protocol ping.  See
    #   the end of this document on how to enable it.

    create_ping_object_ok( 'stream', 'Create new ping object on stream' );
    ping_ok( 'localhost', 'Attempt to connect to the echo port' );

    for ( 1 .. 20 ) {
        select undef, undef, undef, 0.1;
        ping_ok( 'localhost', "[$_] Try several pings while it is connected" );
    }
}

__END__

A simple xinetd configuration to enable the echo service can easily be made.
Just create the following file before restarting xinetd:

/etc/xinetd.d/echo:

# description: An echo server.
service echo
{
        type            = INTERNAL
        id              = echo-stream
        socket_type     = stream
        protocol        = tcp
        user            = root
        wait            = no
        disable         = no
}


Or if you are using inetd, before restarting, add
this line to your /etc/inetd.conf:

echo   stream  tcp     nowait  root    internal

