package UVTestHelpers;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
    pipepair
    socketpair_inet_stream
    socketpair_inet_dgram
);

use IO::Socket::INET;
use Socket qw( AF_INET SOCK_STREAM INADDR_LOOPBACK pack_sockaddr_in );

sub pipepair_base
{
    pipe ( my( $rd, $wr ) ) or die "Unable to pipe() - $!";
    return ( $rd, $wr );
}

# MSWin32's pipes are insufficient for what we need.
# MSWin32 also lacks a socketpair(), so we'll have to fake it up
*pipepair = ( $^O eq "MSWin32" ) ? \&socketpair_inet_stream : \&pipepair_base;

sub socketpair_inet_stream
{
    my ($rd, $wr);

    # Maybe socketpair(2) can do it?
    ($rd, $wr) = IO::Socket->socketpair(AF_INET, SOCK_STREAM, 0)
        and return ($rd, $wr);

    # If not, go the long way round
    my $listen = IO::Socket::INET->new(
        LocalHost => "127.0.0.1",
        LocalPort => 0,
        Listen    => 1,
    ) or die "Cannot listen - $@";

    $rd = IO::Socket::INET->new(
        PeerHost => $listen->sockhost,
        PeerPort => $listen->sockport,
    ) or die "Cannot connect - $@";

    $wr = $listen->accept or die "Cannot accept - $!";

    return ($rd, $wr);
}

sub socketpair_inet_dgram
{
    my ($rd, $wr);

    # Maybe socketpair(2) can do it?
    ($rd, $wr) = IO::Socket->socketpair(AF_INET, SOCK_DGRAM, 0)
        and return ($rd, $wr);

    # If not, go the long way round
    $rd = IO::Socket::INET->new(
        LocalHost => "127.0.0.1",
        LocalPort => 0,
        Proto     => "udp",
    ) or die "Cannot socket - $@";

    $wr = IO::Socket::INET->new(
        PeerHost => $rd->sockhost,
        PeerPort => $rd->sockport,
        Proto    => "udp",
    ) or die "Cannot socket/connect - $@";

    $rd->connect($wr->sockport, inet_aton($wr->sockhost)) or die "Cannot connect - $!";

    return ($rd, $wr);
}

1;
