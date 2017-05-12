# $Id: Flixster.pm 7373 2012-04-09 18:00:33Z chris $

=head1 NAME

WebService::Flixster::Review::Flixster

=cut

package WebService::Flixster::Review::Flixster;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::Flixster WebService::Flixster::Movie WebService::Flixster::Reviews);

__PACKAGE__->mk_accessors(qw(
    average
    likeability
    numNotIntersted
    numScores
    numWantToSee
    popcornScore
));


=head1 METHODS

=head2 average

=head2 likeability

=head2 numNotIntersted

=head2 numScores

=head2 numWantToSee

=head2 popcornScore

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift;

    my $self = {};

    bless $self, $class;

    $self->average($data->{'average'});
    $self->likeability($data->{'likeability'});
    $self->numNotIntersted($data->{'numNotIntersted'});
    $self->numScores($data->{'numScores'});
    $self->numWantToSee($data->{'numWantToSee'});
    $self->popcornScore($data->{'popcornScore'});

    return $self;
}

1;
