# $Id: Director.pm 7373 2012-04-09 18:00:33Z chris $

=head1 NAME

WebService::Flixster::Director

=cut

# TODO: Superclass this with Actor.
package WebService::Flixster::Director;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::Flixster WebService::Flixster::Movie);

__PACKAGE__->mk_accessors(qw(
    photo
    name
    id
));


=head1 METHODS

=head2 photo

=head2 name

=head2 id

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift;

    my $self = {};

    bless $self, $class;

    if (defined $data->{'photo'}) { $self->photo(WebService::Flixster::Photo->_new($ws, $data->{'photo'})); }
    $self->name($data->{'name'});
    # TODO: Parse this out into an object.
    $self->id($data->{'id'});

    return $self;
}

1;
