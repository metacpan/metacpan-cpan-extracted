package WebService::Spotify;
use Moo;
use Method::Signatures;
use LWP::UserAgent;
use URI::QueryParam;
use JSON;
use Data::Dumper;

our $VERSION = '1.003';

has 'prefix' => ( is => 'rw', default => 'https://api.spotify.com/v1/' );
has 'auth'   => ( is => 'rw' );
has 'trace'  => ( is => 'rw', default => 0 );

has 'user_agent' => (
  is => 'rw',
  default => sub { 
    my $ua = LWP::UserAgent->new;
    $ua->agent("WebService::Spotify/$VERSION");
    return $ua;
  }
);

method get ($method, %args) {
  my $uri      = $self->_uri( $method, %args );
  my $headers  = $self->_auth_headers;
  my $response = $self->user_agent->get( $uri->as_string, %$headers );
  
  $self->_log("GET", $uri->as_string);
  $self->_log("RESP", $response->content);

  return $response->content ? from_json($response->content) : undef;
}

method post ($method, $payload, %args) {
  my $uri      = $self->_uri( $method, %args );
  my $headers  = $self->_auth_headers;
  $headers->{'Content-Type'} = 'application/json';
  my $response = $self->user_agent->post( $uri->as_string, %$headers, Content => to_json($payload) );
  
  $self->_log("POST", $uri->as_string);
  $self->_log("HEAD", Dumper $headers);
  $self->_log("DATA", Dumper $payload);
  $self->_log("RESP", $response->content);

  return $response->content ? from_json($response->content) : undef;
}

method put ($method, $payload, %args) {
  my $uri     = $self->_uri( $method, %args );
  my $headers = $self->_auth_headers;
  $headers->{'Content-Type'} = 'application/json';
  my $response = $self->user_agent->put( $uri->as_string, %$headers, Content => to_json($payload) );

  $self->_log("PUT",  $uri->as_string);
  $self->_log("HEAD", Dumper $headers);
  $self->_log("DATA", Dumper $payload);
  $self->_log("RESP", $response->content);

  return $response->content ? from_json($response->content) : $response->is_success;
}

method next ($result) {
   return $self->get($result->{next}) if $result->{next};
}

method previous ($result) {
   return $self->get($result->{previous}) if $result->{previous};
}

method track ($track) {
  my $track_id = $self->_get_id('track', $track);
  return $self->get("tracks/$track_id");
}

method tracks ($tracks) {  
  my @track_ids = map { $self->_get_id('track', $_) } @$tracks;
  return $self->get('tracks/?ids=' . join(',', @track_ids));
}

method artist ($artist) {
  my $artist_id = $self->_get_id('artist', $artist);
  return $self->get("artists/$artist_id");
}

method artists ($artists) {  
  my @artist_ids = map { $self->_get_id('artist', $_) } @$artists;
  return $self->get('artists/?ids=' . join(',', @artist_ids));
}

method artist_albums ($artist, :$album_type, :$country, :$limit = 20, :$offset = 0) {
  my $artist_id = $self->_get_id('artist', $artist);
  my %options;
  $options{album_type} = $album_type if $album_type;
  $options{country}    = $country    if $country;
  return $self->get("artists/$artist_id/albums", %options, limit => $limit, offset => $offset);
}

method artist_top_tracks ($artist, :$country = 'US') {
  my $artist_id = $self->_get_id('artist', $artist);
  return $self->get("artists/$artist_id/top-tracks", country => $country);
}

method album ($album) {
  my $album_id = $self->_get_id('album', $album);
  return $self->get("albums/$album_id");
}

method album_tracks ($album) {
  my $album_id = $self->_get_id('album', $album);
  return $self->get("albums/$album_id/tracks");
}

method albums ($albums) {
  my @album_ids = map { $self->_get_id('album', $_) } @$albums;
  return $self->get('albums/?ids=' . join(',', @album_ids));
}

method search ($q, :$limit = 10, :$offset = 0, :$type = 'track') {
  return $self->get('search', q => $q, limit => $limit, offset => $offset, type => $type);
}

method user ($user_id) {
  return $self->get("users/$user_id");
}

method user_playlists ($user_id) {
  return $self->get("users/$user_id/playlists");
}

method user_playlist ($user_id, :$playlist_id, :$fields) {
  my $method = $playlist_id ? "playlists/$playlist_id" : "starred";
  return $self->get("users/$user_id/$method", fields => $fields);
}

method user_playlist_create ($user_id, $name, :$public = 1) {
  my $data = { 'name' => $name, 'public' => $public };
  return $self->post("users/$user_id/playlists", $data);
}

method user_playlist_add_tracks ($user_id, $playlist_id, $tracks, :$position) {
  my %options;
  $options{position} = $position if $position;
  return $self->post("users/$user_id/playlists/$playlist_id/tracks", $tracks, %options);
}

method user_playlist_replace_tracks ($user_id, $playlist_id, $tracks) {
  return $self->put("users/$user_id/playlists/$playlist_id/tracks", { 'uris' => $tracks });
}

method me {
  return $self->get('me/');
}

method _log (@strings) {
  print join(' ', @strings) . "\n" if $self->trace;
}

method _auth_headers {
  return $self->auth ? { 'Authorization' =>  'Bearer ' . $self->auth } : undef;
}

method _uri ($method, %args) {
  my $base_uri = $method =~ /^http/ ? $method : $self->prefix . $method;

  my $uri = URI->new( $base_uri );
  $uri->query_param( $_, $args{$_} ) for keys %args;

  return $uri;
}

method _get_id ($type, $id) {
  my @fields = split /:/, $id;
  if (@fields == 3) {
    warn "expected id of type $type but found type $fields[2] id" if $type ne $fields[1];
    return $fields[2];
  }

  @fields = split /\//, $id;
  if (@fields >= 3) {
    warn "expected id of type $type but found type $fields[-2] id" if $type ne $fields[-2];
    return $fields[-1];
  }

  return $id;
}

1; 

=head1 NAME

WebService::Spotify - A simple interface to the  L<Spotify Web API|https://developer.spotify.com/web-api/>

=head1 SYNOPSIS

  my $spotify = WebService::Spotify->new;
  my $results = $spotify->search('weezer', limit => 20);
  say $_->{name} for @{$results->{tracks}->{items}};
  

More examples can be found in the /eg directory.


=head1 DESCRIPTION

=head1 METHODS

See L<Method::Signatures> for details of the parameter spec used below. 

Refer to the L<Spotify API documentation|https://developer.spotify.com/spotify-web-api/> for details on the methods and parameters.

Methods that take item IDs (such as the track, album and artist methods) accept URN, URL or simple ID types. The following 3 ids are all acceptable IDs:

 http://open.spotify.com/track/3HfB5hBU0dmBt8T0iCmH42
 spotify:track:3HfB5hBU0dmBt8T0iCmH42
 3HfB5hBU0dmBt8T0iCmH42

The following methods are supported:

=head2 album ($album_id)

returns a single album given the album's ID, URN or URL

=head2 album_tracks ($album_id)

Get Spotify catalog information about an album's tracks

=head2 albums (\@albums)

returns a list of albums given the album IDs, URNs, or URLs

=head2 artist ($artist_id)

returns a single artist given the artist's ID, URN or URL

=head2 artist_albums ($artist, :$album_type, :$country, :$limit = 20, :$offset = 0)

Get Spotify catalog information about an artist’s albums

=head2 artist_top_tracks ($artist, :$country = 'US')

Get Spotify catalog information about an artist’s top 10 tracks by country.

=head2 artists (\@artists)

returns a list of artists given the artist IDs, URNs, or URLs

=head2 me()

returns info about me

=head2 next ($result)

returns the next result given a result

=head2 previous ($result)

returns the previous result given a result

=head2 search ($q, limit => 10, offset => 0, type => 'track')

searches for an item

=head2 track ($track_id)

returns a single track given the track's ID, URN or URL

=head2 tracks (\@track_ids)

returns a list of tracks given the track IDs, URNs, or URLs

=head2 user ($user_id)

Gets basic profile information about a Spotify User

=head2 user_playlist ($user_id, :$playlist_id, :$fields)

Gets playlist of a user

=head2 user_playlist_add_tracks ($user_id, $playlist_id, $tracks, :$position)

Adds tracks to a playlist

=head2 user_playlist_create ($user_id, $name, :$public = 1)

Creates a playlist for a user

=head2 user_playlists ($user_id)

Gets playlists of a user


=head1 AUTHOR

Nick Langridge <nickl@cpan.org>

=head1 CREDITS

This module was ported from L<Spotipy|https://github.com/plamere/spotipy>, a Python wrapper for the Spotify Web API

=head1 LICENSE

This module is free software; you can redistribute it or 
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<WebService::EchoNest> - wrapper for the EchoNest API which has some integration with the Spotify Web API

L<Net::Spotify> - wrapper for the old Spotify metadata API

