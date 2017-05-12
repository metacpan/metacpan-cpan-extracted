package WebService::SetlistFM;
use JSON::XS;
use Cache::LRU;
use Net::DNS::Lite;
use Furl;
use URI;
use URI::QueryParam;
use Carp;
use Moo;
use namespace::clean;
our $VERSION = "0.04";


$Net::DNS::Lite::CACHE = Cache::LRU->new( size => 512 );


has 'http' => (
    is => 'rw',
    required => 1,
    default  => sub {
        my $http = Furl::HTTP->new(
            inet_aton => \&Net::DNS::Lite::inet_aton,
            agent => 'WebService::SetlistFM/' . $VERSION,
            headers => [ 'Accept-Encoding' => 'gzip',],
        );
        return $http;
    },
);


sub artist {
    my $self = shift;
    my $mbid = shift;
    return $self->request("artist/$mbid.json");
} 

sub city {
    my $self = shift;
    my $geoid = shift;
    return $self->request("city/$geoid.json");
} 

sub search_artists {
    my $self = shift;
    my $query_param = shift;
    return $self->request("search/artists.json", $query_param);
} 

sub search_cities {
    my $self = shift;
    my $query_param = shift;
    return $self->request("search/cities.json", $query_param);
} 

sub search_countries {
    my $self = shift;
    my $query_param = shift;
    return $self->request("search/countries.json", $query_param);
} 

sub search_setlists {
    my $self = shift;
    my $query_param = shift;
    return $self->request("search/setlists.json", $query_param);
} 

sub search_venues {
    my $self = shift;
    my $query_param = shift;
    return $self->request("search/venues.json", $query_param);
} 

sub setlist {
    my $self = shift;
    my $setlist_id = shift;
    return $self->request("setlist/$setlist_id.json");
} 

sub user {
    my $self = shift;
    my $user_id = shift;
    return $self->request("user/$user_id.json");
} 

sub venue {
    my $self = shift;
    my $venue_id = shift;
    return $self->request("venue/$venue_id.json");
} 

sub artist_setlists {
    my $self = shift;
    my $mbid = shift;
    my $query_param = shift;
    return $self->request("artist/$mbid/setlists.json", $query_param);
} 

sub setlist_lastfm {
    my $self = shift;
    my $lastfm_event_id = shift;
    return $self->request("setlist/lastFm/$lastfm_event_id.json");
} 

sub setlist_version {
    my $self = shift;
    my $version_id = shift;
    return $self->request("setlist/version/$version_id.json");
} 

sub user_attended {
    my $self = shift;
    my $user_id = shift;
    return $self->request("user/$user_id/attended.json");
} 

sub user_edited {
    my $self = shift;
    my $user_id = shift;
    return $self->request("user/$user_id/edited.json");
} 

sub venue_setlists {
    my $self = shift;
    my $venue_id = shift;
    return $self->request("venue/$venue_id/setlists.json");
} 

sub artist_tour {
    my $self = shift;
    my $mbid = shift;
    my $tour = shift;
    return $self->request("artist/$mbid/tour/$tour.json");
} 


sub request {
    my ( $self, $path, $query_param ) = @_;

    my $query = URI->new;
    map { $query->query_param( $_, $query_param->{$_} ) } keys %$query_param;

    my ($minor_version, $status_code, $message, $headers, $content) = 
        $self->http->request(
            scheme => 'http',
            host => 'api.setlist.fm',
            path_query => "rest/0.1/$path$query",
            method => 'GET',
        );

    return decode_json( $content );

}


1;
__END__

=encoding utf-8

=head1 NAME

WebService::SetlistFM - A simple and fast interface to the L<http://www.setlist.fm> API

=head1 SYNOPSIS

    use WebService::SetlistFM;

    my $setlistfm = new WebService::SetlistFM;
    my $data = $setlistfm->artist('65f4f0c5-ef9e-490c-aee3-909e7ae6b2ab');
    $data = $setlistfm->search_artists({
        'artistName' => 'Metallica',
        'artistMbid' => '65f4f0c5-ef9e-490c-aee3-909e7ae6b2ab',
    });

=head1 DESCRIPTION

The module provides a simple interface to the L<http://www.setlist.fm> API.

=head1 METHODS

These methods usage: L<http://api.setlist.fm/docs/>

=head3 artist

    my $data = $setlistfm->artist('65f4f0c5-ef9e-490c-aee3-909e7ae6b2ab');

=head3 city

    my $data = $setlistfm->city('5392171');

=head3 search_artists

    my $data = $setlistfm->search_artists({
        'artistName' => 'Metallica',
        'artistMbid' => '65f4f0c5-ef9e-490c-aee3-909e7ae6b2ab',
    });

=head3 search_cities

    my $data = $setlistfm->search_cities({ name => 'Shibuya' });

=head3 search_countries

    my $data = $setlistfm->search_countries();

=head3 search_setlists

    my $data = $setlistfm->search_setlists({
        artistName => 'Megadeth',
        year => 2014,
    });

=head3 search_venues

    my $data = $setlistfm->search_venues({name => 'Shibuya'});

=head3 setlist

    my $data = $setlistfm->setlist('3bd6440c');

=head3 user

    my $data = $setlistfm->user('fuzy');

=head3 venue

    my $data = $setlistfm->venue('33d6d4ac');

=head3 artist_setlists

    my $data = $setlistfm->artist_setlists('65f4f0c5-ef9e-490c-aee3-909e7ae6b2ab');

=head3 setlist_lastfm

    my $data = $setlistfm->setlist_lastfm('999009');

=head3 setlist_version

    my $data = $setlistfm->setlist_version('6bd45a36');

=head3 user_attended

    my $data = $setlistfm->user_attended('fuzy');

=head3 user_edited

    my $data = $setlistfm->user_edited('fuzy');

=head3 venue_setlists

    my $data = $setlistfm->venue_setlists('33d6d4ac');

=head3 artist_tour

    my $data = $setlistfm->artist_tour(
        '65f4f0c5-ef9e-490c-aee3-909e7ae6b2ab', 
        'World Magnetic'
    );

=head1 SEE ALSO

L<http://api.setlist.fm/docs/>

=head1 LICENSE

Copyright (C) Hondallica.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hondallica E<lt>hondallica@gmail.comE<gt>

=cut

