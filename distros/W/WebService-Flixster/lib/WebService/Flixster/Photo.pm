# $Id: Photo.pm 7373 2012-04-09 18:00:33Z chris $

=head1 NAME

WebService::Flixster::Photo

=cut


package WebService::Flixster::Photo;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::Flixster WebService::Flixster::Movie);

__PACKAGE__->mk_accessors(qw(
    lthumbnail
    thumbnail
    type
    url
));


=head1 METHODS

=head2 lthumbnail

=head2 thumbnail

=head2 type

=head2 url

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift;

    my $self = {};

    bless $self, $class;

    if (defined $data->{'lthumbnail'}) { $self->lthumbnail($data->{'lthumbnail'}); }
    if (defined $data->{'thumbnail'}) { $self->lthumbnail($data->{'thumbnail'}); }
    if (defined $data->{'type'}) { $self->type($data->{'type'}); }
    if (defined $data->{'url'}) { $self->url($data->{'url'}); }

    return $self;
}

1;
