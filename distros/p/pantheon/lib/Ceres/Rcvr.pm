package Ceres::Rcvr;

=head1 NAME

Ceres::Rcvr - Process pulse from sender.

=cut
use strict;
use warnings;

use Carp;
use threads;
use IO::Socket;
use Thread::Queue;

use Ceres::DBI::Index;

use constant MAXBUF => 65;

=head1 CONFIGURATION

=head3 port

UDP port to listen on

=head3 dbpath

database path

=cut
sub new 
{
    my ( $class, %self ) = splice @_;
    map { $self{$_} || confess "$_ not defined" } qw( dbpath port );
    bless \%self, ref $class || $class;
}

sub run
{
    my $self = shift;
    my $db = Ceres::DBI::Index->new( $self->{dbpath} ),
    my $queue = Thread::Queue->new();
    my $sock = IO::Socket::INET->new( LocalPort => $self->{port}, Proto => 'udp' );

    threads::async
    {
        while ( $sock->recv( my $msg, MAXBUF ) )
        {
            $queue->enqueue( $sock->peername, $1, $2 )
                if $msg =~ /^([0-9a-f]{32}):([0-9a-f]{32})$/;
        }
    }->detach;

    while ( my @info = $queue->dequeue( 3 ) )
    {
        $db->update( @info ) if
            $info[0] = gethostbyaddr( ( sockaddr_in $info[0] )[1], AF_INET );
    }
}

1;
