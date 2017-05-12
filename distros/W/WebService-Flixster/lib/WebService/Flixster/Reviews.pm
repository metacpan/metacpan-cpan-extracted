# $Id: Reviews.pm 7373 2012-04-09 18:00:33Z chris $

=head1 NAME

WebService::Flixster::Reviews

=cut


package WebService::Flixster::Reviews;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::Flixster WebService::Flixster::Movie);

use WebService::Flixster::Review::Critic;
use WebService::Flixster::Review::Flixster;
use WebService::Flixster::Review::RottenTomatoes;
use WebService::Flixster::Review::User;

__PACKAGE__->mk_accessors(qw(
    critics
    flixster
    recent
    rottenTomatoes
));


=head1 METHODS

=head2 critics

=head2 flixster

=head2 recent

=head2 rottenTomatoes

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift;
    my $data2 = shift;

    my $self = {};

    bless $self, $class;

    # data is the reviews section from the main main, data2 is the reviews section from the reviews page.
    # It appears that the critic reviews on the main page are a selection, whilst those on the reviews page
    # are in reverse time order, up to 'limit' and starting at 'offset'.  TODO: Decide which (or both) of these
    # to use
    $self->critics( [ map { WebService::Flixster::Review::Critic->_new($ws, $_) } @{$data2->{'critics'}} ] );
    $self->flixster(WebService::Flixster::Review::Flixster->_new($ws, $data->{'flixster'}));
    $self->recent( [ map { WebService::Flixster::Review::User->_new($ws, $_) } @{$data->{'recent'}} ] );
    if (exists $data->{'rottenTomatoes'}) { $self->rottenTomatoes(WebService::Flixster::Review::RottenTomatoes->_new($ws, $data->{'rottenTomatoes'})); }

    return $self;
}

1;
