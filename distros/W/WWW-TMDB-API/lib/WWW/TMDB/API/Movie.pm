package WWW::TMDB::API::Movie;

use strict;
use warnings;
our $VERSION = '0.04';

sub info {
    my $self = shift;
    my (%params) = @_;
    $self->{api}->send_api( [ 'movie', $params{ID} ],
        { ID => 1, language => 0 }, \%params );
}

sub search {
    my $self = shift;
    my (%params) = @_;
    $self->{api}->send_api( [ 'search', 'movies' ],
        { query => 1, page => 0, language => 0, 'include_adult' => 0 },
        \%params );
}

sub alternative_titles {
    my $self = shift;
    my (%params) = @_;
    $self->{api}->send_api( [ 'movie', $params{ID}, 'alternative_titles' ],
        { ID => 1, country => 0 }, \%params );
}

sub casts {
    my $self = shift;
    my (%params) = @_;
    $self->{api}->send_api( [ 'movie', $params{ID}, 'casts' ], { ID => 1 },
        \%params );
}

sub images {
    my $self = shift;
    my (%params) = @_;
    $self->{api}->send_api( [ 'movie', $params{ID}, 'images' ],
        { ID => 1, language => 0 }, \%params );
}

sub keywords {
    my $self = shift;
    my (%params) = @_;
    $self->{api}->send_api( [ 'movie', $params{ID}, 'keywords' ],
        { ID => 1 }, \%params );
}

sub releases {
    my $self = shift;
    my (%params) = @_;
    $self->{api}->send_api( [ 'movie', $params{ID}, 'releases' ],
        { ID => 1 }, \%params );
}

sub translations {
    my $self = shift;
    my (%params) = @_;
    $self->{api}->send_api( [ 'movie', $params{ID}, 'translations' ],
        { ID => 1 }, \%params );
}

sub trailers {
    my $self = shift;
    my (%params) = @_;
    $self->{api}->send_api( [ 'movie', $params{ID}, 'trailers' ],
        { ID => 1, language => 1 }, \%params );
}

sub latest {
    my $self = shift;
    my (%params) = @_;
    $self->{api}->send_api( [ 'latest', 'movie' ] );
}

1;

