package Argos::Conf::Reduce;

=head1 NAME

Argos::Conf::Reduce - Implements Argos::Conf

=head1 SYNOPSIS

 use Argos::Conf::Reduce;

 my $conf = Argos::Conf::Reduce->new ( '/conf/file' )->dump( 'foo' );

=cut
use strict;
use warnings;

use base qw( Argos::Conf );

=head1 CONFIGURATION

YAML file that defines sets of reduce parameters index by names.
Each set defines the following parameters:

 stat : status to alert.
 freq : alert frequency.
 tier : tiers of escalation.
 code : name of alert code.

And I<optional> parameters:

 rate : sample rate.
      ( default to half of alert frequency. ) 
 esc  : number of alerts before escalating.
      ( default 0 ) no escalation, alert all tiers.
=cut

our @PARAM = qw( stat tier code freq );
our %PARAM = ( esc => 0, rate => 0 );

sub check
{
    my ( $self, $conf ) = @_;
    map { die "$_ not defined" if ! $conf->{$_} } @PARAM;
    map { $conf->{$_} ||= $PARAM{$_} } keys %PARAM;

    my ( $rate, $freq ) = $self->time( @$conf{ 'rate', 'freq' } );
    $rate = int( $freq / 2 ) || 1 if ! $rate || $rate >= $freq;
    @$conf{ 'rate', 'freq' } = ( $rate, $freq );

    my $tier = $conf->{tier};
    for my $i ( 0 .. @$tier - 1 )
    {
        my $t = $tier->[$i];
        $t = $tier->[$i] = [ $t ] unless my $ref = ref $t;
        die "tier $i is not ARRAY" if $ref ne 'ARRAY';
        push @$t, @{ $tier->[ $i - 1 ] } if $i;
    }
}

1;
