#!perl -w

# This program check if we are able to talk to ourself.  Misconfigured
# systems that can't talk to their own 'hostname' was the most commonly
# reported libwww-failure.

use strict;
require IO::Socket;

if ( @ARGV >= 2 && $ARGV[0] eq "--port" )
{
    my $port = $ARGV[1];
    require Sys::Hostname;
    my $host = Sys::Hostname::hostname();
    if (
         my $socket = IO::Socket::INET->new( PeerAddr => "$host:$port",
                                             Timeout  => 5 )
       )
    {
        require IO::Select;
        if ( IO::Select->new($socket)->can_read(1) )
        {
            my ( $n, $buf );
            if ( $n = sysread( $socket, $buf, 512 ) )
            {
                exit if $buf eq "Hi there!\n";
                die "Seems to be talking to the wrong server at $host:$port, got \"$buf\"\n";
            }
            elsif ( defined $n )
            {
                die "Immediate EOF from server at $host:$port\n";
            }
            else
            {
                die "Can't read from server at $host:$port: $!";
            }
        }
        die "No response from server at $host:$port\n";
    }
    die "Can't connect: $@\n";
}

# server code
my $socket = IO::Socket::INET->new( Listen  => 1,
                                    Timeout => 5 );
my $port = $socket->sockport;
open( CLIENT, qq("$^X" "$0" --port $port |) ) || die "Can't run $^X $0: $!\n";

if ( my $client = $socket->accept )
{
    print $client "Hi there!\n";
    close($client) || die "Can't close socket: $!";
}
else
{
    warn "Test server timeout\n";
}

exit if close(CLIENT);
die "Can't wait for client: $!" if $!;
die "The can-we-talk-to-ourself test failed.\n";
