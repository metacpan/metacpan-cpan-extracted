# $Id: Poster.pm 7373 2012-04-09 18:00:33Z chris $

=head1 NAME

WebService::Flixster::Poster

=cut


package WebService::Flixster::Poster;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::Flixster WebService::Flixster::Movie);

__PACKAGE__->mk_accessors(qw(
    detailed
    original
    profile
    thumbnail
));


=head1 METHODS

=head2 detailed

=head2 original

=head2 profile

=head2 thumbnail

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift;

    my $self = {};

    bless $self, $class;

    $self->detailed($data->{'detailed'});
    $self->original($data->{'original'});
    $self->profile($data->{'profile'});
    $self->thumbnail($data->{'thumbnail'});

    return $self;
}

1;
