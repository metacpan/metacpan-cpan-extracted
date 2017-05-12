use strict;
use warnings;
use Test::More;
use WebService::LastFM;
use Data::Dumper;

my $username = $ENV{WEBSERVICE_LASTFM_TEST_USERNAME};
my $password = $ENV{WEBSERVICE_LASTFM_TEST_PASSWORD};

if ($username && $password) {
    plan tests => 30
}
else {
    plan skip_all => "Set ENV:WEBSERVICE_LASTFM_TEST_USERNAME/PASSWORD";
}

my $lastfm;
isa_ok(($lastfm = WebService::LastFM->new(
    username => $username,
    password => $password,
)), 'WebService::LastFM');

my $stream_info;
isa_ok( ( $stream_info = $lastfm->get_session() ), 'WebService::LastFM::Session');
my $session_key;
ok( $session_key = $stream_info->session, 'Get the Session key' );
like( $session_key, qr/[a-z0-9]{32}/, "Does the Session key look right: $session_key" );
my $playlist;
isa_ok( ( $playlist = $lastfm->get_new_playlist() ), 'WebService::LastFM::Playlist' );
my $track_count;
ok( $track_count = $playlist->tracks_left(), "Get the track count" );
ok( $track_count > 0, "We have $track_count tracks");
my $track;
ok( $track = $playlist->get_next_track(), "Get the next track" );
isa_ok( $track, 'WebService::LastFM::Track' );
ok( $track_count - 1 == scalar( @{ $playlist->tracks() } ), "Did the queue shorten?" );
ok( $track_count - 1 ==  $playlist->tracks_left(),          "Did the track count decrement?" );
my $location;
ok( $location =  $track->location, "Location of track: $location" );
ok( ref( $location ) eq '', "It's a scalar");
my $title;
ok( $title =  $track->title, "Title of track: $title" );
ok( ref( $title ) eq '' , "It's a scalar");
my $creator;
ok( $creator =  $track->creator, "Creator of track: $creator" );
ok( ref( $creator ) eq '' , "It's a scalar");

print "exhast the track list\n";
while ( my $track = $playlist->get_next_track() ) {
  #print scalar @{ $playlist->tracks() } ." tracks left \n"
}

#get new list
print "get a new list\n";
isa_ok( ( $playlist = $lastfm->get_new_playlist() ), 'WebService::LastFM::Playlist' );
ok( $track_count = $playlist->tracks_left(), "Get the track count" );
ok( $track_count > 0, "We have $track_count tracks");
ok( $track = $playlist->get_next_track(), "Get the next track" );
isa_ok( $track, 'WebService::LastFM::Track' );
ok( $track_count - 1 == scalar( @{ $playlist->tracks() } ), "Did the queue shorten?" );
ok( $track_count - 1 ==  $playlist->tracks_left(),          "Did the track count decrement?" );
ok( $location =  $track->location, "Location of track: $location" );
ok( ref( $location ) eq '', "It's a scalar");
ok( $title =  $track->title, "Title of track: $title" );
ok( ref( $title ) eq '' , "It's a scalar");
ok( $creator =  $track->creator, "Creator of track: $creator" );
ok( ref( $creator ) eq '' , "It's a scalar");


