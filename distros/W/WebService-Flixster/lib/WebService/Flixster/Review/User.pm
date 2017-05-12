# $Id: User.pm 7373 2012-04-09 18:00:33Z chris $

=head1 NAME

WebService::Flixster::Review::User

=cut

package WebService::Flixster::Review::User;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::Flixster WebService::Flixster::Movie WebService::Flixster::Reviews);

__PACKAGE__->mk_accessors(qw(
    id
    user
    score
    review
));


=head1 METHODS

=head2 id

=head2 user

=head2 score

=head2 review

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift;

    my $self = {};

    bless $self, $class;

    $self->id($data->{'id'});
    $self->user($data->{'user'}); # TODO: Parse
    $self->score($data->{'score'});
    $self->review($data->{'review'});

    return $self;
}

1;
