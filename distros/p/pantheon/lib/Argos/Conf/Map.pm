package Argos::Conf::Map;

=head1 NAME

Argos::Conf::Map - Implements Argos::Conf

=head1 SYNOPSIS

 use Argos::Conf::Map;

 my $conf = Argos::Conf::Map->new( '/conf/file' )->dump( 'foo' );

=cut
use strict;
use warnings;

use base qw( Argos::Conf );

=head1 CONFIGURATION

YAML file that defines sets of watcher parameters index by names.
Each set defines the following parameters:

 target : targets of watcher, to be devided into batches.
 map : name of map code.
 batch : name of batch code.

And I<optional> parameters:

 thread : number of threads. ( default 1 ).
 interval : time per iteration. ( default 0 : run back to back )

=cut
our @PARAM = qw( target map batch );
our %PARAM = ( thread => 1, interval => 0 );

sub check
{
    my ( $self, $conf ) = splice @_;
    map { die "$_ not defined" if ! $conf->{$_} } @PARAM;
    map { $conf->{$_} ||= $PARAM{$_} } keys %PARAM;
    $conf->{interval} = $self->time( $conf->{interval} );
}

1;
