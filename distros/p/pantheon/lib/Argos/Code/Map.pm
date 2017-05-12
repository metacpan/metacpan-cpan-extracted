package Argos::Code::Map;

=head1 NAME

Argos::Code::Map - Implements Argos::Code

=head1 SYNOPSIS

 use Argos::Code::Map;

 my $map = Argos::Code::Map->new( '/code/file' );

 $map->run( cache => {}, queue => [ .. ], .. );

=cut
use strict;
use warnings;
use threads;
use YAML::XS;

use base qw( Argos::Code );

=head1 METHODS

=head3 run( %param )

Run map code. Returns invoking object. The following may be defined in %param.

 queue : ( required ) a pair of Thread::Queue objects.
 error : ( 'error' ) error condidtion.

=cut
sub run
{
    my $self = shift;
    my %run = ( error => 'error', $self->param( @_ ) );
    my ( $queue, $error ) = delete @run{ 'queue', 'error' };
    my ( $batch, $cache, $result );

    while ( 1 )
    {
        eval
        {
            local $SIG{ALRM} = sub { die 'timeout' if $batch };
            local $SIG{KILL} = sub { $batch = []; die 'killed' };

            while ( sleep 1 )
            {
                next unless $queue->[0]->pending();
                last if ( $batch, $cache ) = $queue->[0]->dequeue_nb( 2 );
            }

            $result = &$self
            (
                %run, batch => YAML::XS::Load( $batch ),
                cache => YAML::XS::Load( $cache ),
            );
        };

        $result = { $error => { $@ => YAML::XS::Load( $batch ) } } if $@;
        $queue->[1]->enqueue( threads->tid(), YAML::XS::Dump( $result || {} ) );
    }
}

1;
