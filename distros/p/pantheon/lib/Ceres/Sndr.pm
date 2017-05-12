package Ceres::Sndr;

=head1 NAME

Ceres::Sndr - Send pulse to receiver.

=cut
use strict;
use warnings;

use Carp;
use YAML::XS;
use IO::Socket;
use File::Temp;
use Digest::MD5;

our $CYCLE = 120;

=head1 CONFIGURATION

=head3 index

name of record that serves as an index, e.g. 'serial' or 'uuid'

=head3 code

path of the code file

=head3 data

path to dump data

=cut
sub new 
{
    my ( $class, %self ) = splice @_;
    map { $self{$_} || confess "$_ not defined" } qw( index code data );
    bless \%self, ref $class || $class;
}

sub run
{
    local $| = 1;

    my $self = shift;
    my %run = ( log => \*STDERR, cache => {}, @_ );

    confess "Cannot create socket: $@" unless my $sock =
        IO::Socket::INET->new( PeerAddr => delete $run{rcvr}, Proto => 'udp' );

    my ( $index, $code, $data ) = @$self{ qw( index code data ) };
    my @code = do $code;
    my $error = "invalid code $code";

    confess "$error: $@" if $@;

    for ( 1 .. @code / 2 ) ## load code in order
    {
        my ( $name, $code ) = splice @code, 0, 2;
        confess "$error: $name not CODE" if ref $code ne 'CODE';
        push @code, [ $name, $code ];
    }

    my $cycle = delete( $run{cycle} ) || $CYCLE;
    my $log = Vulcan::Logger->new( $run{log} );

    $run{log} = sub { $log->say( @_ ) };
    local $SIG{ALRM} = sub { die 'timeout' };

    for ( my ( $now, $prev, $curr, %data ) = time; $now; %data = () )
    {
        for ( @code )
        {
            my ( $name, $code ) = @$_;
            my $data = eval { alarm $cycle; &$code( %run ); alarm 0 };

            if ( $@ ) { $log->say( "$name: $@" ); alarm 0 }
            $data{$name} = $data if ref $data eq 'HASH';
        }

        confess "$index not defined" ## index must be defined
            unless my ( $data ) = grep { $_->{$index} } values %data;

        my $ctx = Digest::MD5->new;
        my $key = $ctx->add( $data->{$index} )->hexdigest; ## id

        $data = YAML::XS::Dump \%data;
        $curr = $ctx->reset->add( $data )->hexdigest; ## checksum
        $sock->send( "$key:$curr" );

        unless ( $prev && $prev eq $curr )
        {
            my $temp = File::Temp->new( UNLINK => 0 );
            print $temp $data;
            $prev = $curr;
            system sprintf "mv %s $data", $temp->filename();
        }

        my $due = $cycle + $now - time;
        sleep $due if $due > 0; ## wait until due to run again
    }
}

1;
