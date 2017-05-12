package Janus::Sequence::Conf;

=head1 NAME

Janus::Sequence::Conf - Load maintenence plugin configuration.

=head1 SYNOPSIS

 use Janus::Sequence::Conf;

 my $conf = Janus::Sequence::Conf->load( '/conf/file' );
 my ( $alpha, $omega ) = $conf->dump( 'alpha', 'omega' );

=head1 CONFIGURATION

YAML file that defines a HASH of HASH of HASH.

Top level HASH consists of HASH indexed by sequence names. Next level HASH
consists of HASH indexed by stage names. Third level HASH defines parameters
of each stage.

=cut
use strict;
use warnings;

use base qw( Janus::Conf );

=head1 METHODS

=head3 load( $file )

Load configuration from file. Returns object.

=cut
sub load
{
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
}

sub check
{
    my ( $self, $conf ) = splice @_;
    map { die "$_ is not HASH" if ref $conf->{$_} ne 'HASH' } keys %$conf;
}

1;
