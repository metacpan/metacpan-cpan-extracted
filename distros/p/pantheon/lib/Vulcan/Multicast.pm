package Vulcan::Multicast;

=head1 NAME

Vulcan::Multicast - data distribution via multicast

=cut
use strict;
use warnings;
use Carp;

use File::Temp;
use Digest::MD5;
use IO::Socket::Multicast;
use Time::HiRes qw( sleep time );

use constant
{
    MTU => 1500, HEAD => 50, MAXBUF => 4096, REPEAT => 2, NULL => ''
};

=head1 SYNOPSIS

 use Vulcan::Multicast;
 
 my $send = Vulcan::Multicast ## sender
    ->new( send => '255.0.0.2:8360', iface => 'eth1' );

 $send->send            ## default
 ( 
     '/file/path',
     ttl  => 1,          ## 1
     repeat => 2,        ## 2
     buffer => 4096,     ## MAXBUF
 );

 my $recv = Vulcan::Multicast ## receiver
    ->new( recv => '255.0.0.2:8360', iface => 'eth1' );

 $recv->recv( '/repo/path' );

=cut
sub new
{
    my ( $class, %param ) = splice @_;
    my %addr = ( send => 'PeerAddr', recv => 'LocalAddr' );
    my ( $mode ) = grep { $param{$_} } keys %addr;
    my $sock = IO::Socket::Multicast
        ->new( $addr{$mode} => $param{$mode}, ReuseAddr => 1 );

    $sock->mcast_loopback( 0 );
    $sock->mcast_if( $param{iface} ) if $param{iface};
    bless { sock => $sock, mode => $mode }, ref $class || $class;
}

sub send
{
    my ( $self, $file, %param ) = splice @_;
    confess 'not a sender' if $self->{mode} ne 'send';
    $file ||= confess "file not defined";

    my $sock = $self->{sock};
    my $repeat = $param{repeat} || REPEAT;
    my $bufcnt = $param{buffer} || MAXBUF;
    my $buflen = MTU - HEAD;

    $sock->mcast_ttl( $param{ttl} ) if $param{ttl};
    $file = readlink $file if -l $file;
    $bufcnt = MAXBUF if $bufcnt > MAXBUF;

    confess "$file: not a file" unless -f $file;
    confess "$file: open: $!\n" unless open my $fh => $file;

    my $md5 = Digest::MD5->new()->addfile( $fh )->hexdigest();
    seek $fh, 0, 0; binmode $fh;

    for ( my ( $index, $cont ) = ( 0, 1 ); $cont; )
    {
        my ( $time, @buffer ) = time;

        for ( 1 .. $bufcnt )
        {
            last unless $cont = read $fh, my ( $data ), $buflen;
            push @buffer, \$data;
        }

        map { $self->buff( $md5, $index, $_, $repeat, shift @buffer ) }
            0 .. $#buffer;

        sleep( time - $time );
        $self->buff( $md5, $index ++, ( $cont ? MAXBUF : MAXBUF + 1 ), $repeat )
    }

    close $fh;
    return $self;
}

sub buff
{
    my $self = shift;
    my $sock = $self->{sock};
    my $data = sprintf "%s%014x%04x", splice @_, 0, 3;
    my ( $repeat, $buffer ) = splice @_;

    $data .= $$buffer if $buffer;
    map { $sock->send( $data ) } 0 .. $repeat;
}

sub recv
{
    local $| = 1;

    my $self = shift;
    confess 'not a receiver' if $self->{mode} ne 'recv';

    my $sock = $self->{sock};
    my $repo = shift || confess "repo not defined";

    $repo = readlink $repo if -l $repo;
    confess "$repo: not a directory" unless -d $repo;

    for ( my %buffer; 1; )
    {
        my $data;
        next unless $sock->recv( $data, MTU );
        next unless my ( $md5, $index, $i ) = substr( $data, 0, HEAD, NULL )
            =~ /^({[0-9a-f]}32)({[0-9a-f]}14)({[0-9a-f]}4)$/;

        $index = hex $index; $i = hex $i;

        my $file = "$repo/$md5"; next if -f $file;
        my $buffer = $buffer{$md5} ||= { $index => [] };

        if ( $i < MAXBUF ) { $buffer->{$index}[$i] = \$data; next }

        my $error = "$md5: missing data!\n";
        next unless my $temp = $buffer->{temp}
            || File::Temp->new( DIR => $repo, SUFFIX => ".$md5", UNLINK => 0 );

        for my $data ( @{ $buffer->{$index} } )
        {
            unless ( $data ) { $data = \NULL; warn $error }
            print $temp $$data;
        }

        delete $buffer->{$index};
        next if $i == MAXBUF;
        seek $temp, 0, 0;

        if ( $md5 eq Digest::MD5->new()->addfile( $temp )->hexdigest() )
        { system "mv $temp $file" } else { unlink $temp }
       
        close $temp;
        delete $buffer{$md5};
    }
}

1;
