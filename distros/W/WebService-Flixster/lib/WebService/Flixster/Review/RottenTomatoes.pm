# $Id: RottenTomatoes.pm 7373 2012-04-09 18:00:33Z chris $

=head1 NAME

WebService::Flixster::Review::RottenTomatoes

=cut

package WebService::Flixster::Review::RottenTomatoes;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::Flixster WebService::Flixster::Movie WebService::Flixster::Reviews);

__PACKAGE__->mk_accessors(qw(
    certifiedFresh
    rating
));


=head1 METHODS

=head2 certifiedFresh

=head2 rating

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift;

    my $self = {};

    bless $self, $class;

    $self->certifiedFresh(!!$data->{'certifiedFresh'});
    $self->rating($data->{'rating'});

    return $self;
}

1;
