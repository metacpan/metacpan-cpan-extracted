package WebService::MusixMatch;
use JSON::XS;
use Cache::LRU;
use Net::DNS::Lite;
use Furl;
use URI;
use URI::QueryParam;
use Carp;
use Moo;
use namespace::clean;
our $VERSION = "0.06";


$Net::DNS::Lite::CACHE = Cache::LRU->new( size => 512 );

has 'api_key' => (
    is => 'rw',
    isa => sub { $_[0] },
    required => 1,
    default => sub { $ENV{MUSIXMATCH_API_KEY} },
);

has 'http' => (
    is => 'rw',
    required => 1,
    default  => sub {
        my $http = Furl::HTTP->new(
            inet_aton => \&Net::DNS::Lite::inet_aton,
            agent => 'WebService::MusixMatch/' . $VERSION,
            headers => [ 'Accept-Encoding' => 'gzip',],
        );
        return $http;
    },
);


my @methods = (
    'chart.artists.get',
    'chart.tracks.get',
    'track.search',
    'track.get',
    'track.subtitle.get',
    'track.lyrics.get',
    'track.snippet.get',
    'track.lyrics.post',
    'track.lyrics.feedback.post',
    'matcher.lyrics.get',
    'matcher.track.get',
    'matcher.subtitle.get',
    'artist.get',
    'artist.search',
    'artist.albums.get',
    'artist.related.get',
    'album.get',
    'album.tracks.get',
    'tracking.url.get',
    'catalogue.dump.get',
);


for my $method (@methods) {
    my $code = sub {
        my ($self, %query_param) = @_;
        return $self->request($method, \%query_param);
    };
    no strict 'refs';
    my $method_name = $method;
    $method_name =~ s|\.|_|g;
    *{$method_name} = $code; 
}


sub request {
    my ( $self, $path, $query_param ) = @_;

    my $query = URI->new;
    $query->query_param( 'apikey', $self->api_key );
    $query->query_param( 'format', 'json' );
    map { $query->query_param( $_, $query_param->{$_} ) } keys %$query_param;

    my ($minor_version, $status_code, $message, $headers, $content) = 
        $self->http->request(
            scheme => 'http',
            host => 'api.musixmatch.com',
            path_query => "ws/1.1/$path$query",
            method => 'GET',
        );

    my $data = decode_json( $content );
    if ( $data->{message}{header}{status_code} != 200 ) {
        confess $data->{message}{header}{status_code};
    } else {
        return $data;
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

WebService::MusixMatch - A simple and fast interface to the Musixmatch API

=head1 SYNOPSIS

    use WebService::MusixMatch;

    my $mxm = new WebService::MusixMatch(apikey => 'YOUR_API_KEY');

    my $data = $mxm->chart_artist_get( country => 'JP' );
    $data = $mxm->track_search( q => 'One', f_artist_id => 64 );
    $data = $mxm->matcher_track_get(
        q_artist => 'Metallica',
        q_album => 'Master of Puppets',
        q_track => 'One',
    );
    $data = $mxm->artist_search(q_artist => 'Metallica');

=head1 DESCRIPTION

The module provides a simple interface to the MusixMatch API. To use this module, you must first sign up at L<https://developer.musixmatch.com> to receive an API key.

=head1 METHODS

These methods usage: L<https://developer.musixmatch.com/documentation/api-methods>

=head3 chart_artists_get

=head3 chart_tracks_get

=head3 track_search

=head3 track_get

=head3 track_subtitle_get

=head3 track_lyrics_get

=head3 track_snippet_get

=head3 track_lyrics_post

=head3 track_lyrics_feedback_post

=head3 matcher_lyrics_get

=head3 matcher_track_get

=head3 matcher_subtitle_get

=head3 artist_get

=head3 artist_search

=head3 artist_albums_get

=head3 artist_related_get

=head3 album_get

=head3 album_tracks_get

=head3 tracking_url_get

=head3 catalogue_dump_get


=head1 SEE ALSO

L<https://developer.musixmatch.com>

=head1 LICENSE

Copyright (C) Hondallica.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hondallica E<lt>hondallica@gmail.comE<gt>

=cut

