package WWW::TMDB::API::Person;

use strict;
use warnings;

our $VERSION = '0.04';

sub info {
    my $self = shift;
    my (%params) = @_;
    $self->api->send_api( [ 'person', $params{ID} ], { ID => 1 }, \%params );
}

sub credits {
    my $self = shift;
    my (%params) = @_;
    $self->api->send_api( [ 'person', $params{ID}, 'credits' ],
        { ID => 1, language => 0 }, \%params );
}

sub images {
    my $self = shift;
    my (%params) = @_;
    $self->api->send_api( [ 'person', $params{ID}, 'images' ],
        { ID => 1 }, \%params );
}

sub search {
    my $self = shift;
    my (%params) = @_;
    $self->api->send_api( [ 'search', 'person' ],
        { query => 1, page => 0 }, \%params );
}
1;

