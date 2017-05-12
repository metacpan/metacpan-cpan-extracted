# $Id: Critic.pm 7373 2012-04-09 18:00:33Z chris $

=head1 NAME

WebService::Flixster::Review::Critic

=cut

package WebService::Flixster::Review::Critic;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::Flixster WebService::Flixster::Movie WebService::Flixster::Reviews);

__PACKAGE__->mk_accessors(qw(
    id
    name
    source
    rating
    review
    images
    url
));


=head1 METHODS

=head2 id

=head2 name

=head2 source

=head2 rating

=head2 review

=head2 images

=head2 url

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift;

    my $self = {};

    bless $self, $class;

    $self->id($data->{'id'});
    $self->name($data->{'name'});
    $self->source($data->{'source'});
    $self->rating($data->{'rating'});
    $self->review($data->{'review'});
    $self->images($data->{'images'}); # TODO: Parse me
    $self->url($data->{'url'});

    return $self;
}

1;
