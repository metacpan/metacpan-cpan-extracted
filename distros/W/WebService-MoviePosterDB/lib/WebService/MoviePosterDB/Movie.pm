# $Id: Movie.pm 6486 2011-06-13 13:42:02Z chris $

=head1 NAME

WebService::MoviePosterDB::Movie

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

package WebService::MoviePosterDB::Movie;

use strict;
use warnings;

our $VERSION = '0.18';

use Carp;
our @CARP_NOT = qw(WebService::MoviePosterDB);

use base qw(Class::Accessor);

__PACKAGE__->mk_accessors(qw(
    imdb
    title
    year
    page
    posters
));

use WebService::MoviePosterDB::Poster;

sub _new {
    my $class = shift;
    my $json = shift;
    my $self = {};

    if (defined $json->{'errors'}) { croak join("; ", map {s/\.*$//; $_} @{$json->{'errors'}}); }

    bless $self, $class;

    $self->imdb($json->{'imdb'});
    $self->title($json->{'title'});
    $self->year($json->{'year'});
    $self->page($json->{'page'});
    $self->posters( [ map { WebService::MoviePosterDB::Poster->_new($_) } @{$json->{'posters'}} ] );

    return $self;
}

=head1 METHODS

=head2 tconst()

=cut

sub tconst {
    my $self = shift;
    return sprintf("tt%07d", $self->imdb());
}

=head2 imdbid()

=cut

sub imdbid {
    my $self = shift;
    return $self->tconst();
}

=head2 imdb()

=head2 title()

=head2 year()

=head2 page()

=head2 posters()

=cut

1;
