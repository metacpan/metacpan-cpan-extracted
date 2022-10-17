use strict;

use Data::Dumper  qw( Dumper );
use JSON::MaybeXS qw( decode_json );
use Test::More;
use Test::RequiresInternet (
    'accounts.spotify.com' => 443,
    'api.spotify.com'      => 443,
    'www.spotify.com'      => 80,
);
use Try::Tiny    qw( catch try );
use WWW::Spotify ();

my $obj = WWW::Spotify->new();

sub show_and_pause {
    if ( $obj->debug() == 1 ) {
        my $show = shift;
        print Dumper($show);
        sleep 5;
    }
}

my $result;

#SKIP: {

#    skip 'No SPOTIFY_CLIENT_ID', 5 unless $ENV{SPOTIFY_CLIENT_ID};
$obj->force_client_auth(1);

ok( $obj->force_client_auth() == 1 );

#------------------#

$obj->force_client_auth(0);

ok( $obj->force_client_auth() == 0 );

#------------------#

=pod
$result = $obj->search(
    'tania bowra',
    'artist',
    { limit => 15, offset => 0 }
);

show_and_pause($result);

ok( is_valid_json($result), 'search' );
=cut

#------------------#

$result = $obj->album('0sNOF9WDwhWunNAHPD3Baj');

ok( is_valid_json( $result, 'album' ), 'album' );

show_and_pause($result);

#------------------#

$result = $obj->albums(
    '41MnTivkwTO3UUJ8DrqEJJ,6JWc4iAiJ9FjyK0B59ABb4,6UXCm6bOO4gFlDQZV5yL37');

ok( is_valid_json( $result, 'albums' ), 'albums (multiple ids)' );

show_and_pause($result);

#------------------#

=pod
$result = $obj->albums(
    [
        '41MnTivkwTO3UUJ8DrqEJJ', '6JWc4iAiJ9FjyK0B59ABb4',
        '6UXCm6bOO4gFlDQZV5yL37'
    ]
);

ok(
    is_valid_json( $result, 'ablums' ),
    "albums (multiple ids) as array ref"
);

show_and_pause($result);

#------------------#

$result = $obj->albums_tracks(
    '6akEvsycLGftJxYudPjmqK',
    {
        limit  => 5,
        offset => 1

    }
);

ok( is_valid_json( $result, 'albums_tracks' ), "albums_tracks" );

show_and_pause($result);

#------------------#

$result = $obj->artist('0LcJLqbBmaGUft1e9Mm8HV');

ok( is_valid_json( $result, 'artist' ), "artist" );

show_and_pause($result);

#------------------#

my $artists_multiple = '0oSGxfWSnnOXhD2fKuz2Gy,3dBVyJ7JuOMt4GE9607Qin';

$result = $obj->artists($artists_multiple);

ok( is_valid_json( $result, 'artists' ), "artists ( $artists_multiple )" );

show_and_pause($result);

#------------------#

$result = $obj->artist_albums(
    '1vCWHaC5f2uS3yhpwWbIA6',
    {
        album_type => 'single',

        # country => 'US',
        limit  => 2,
        offset => 0
    }
);
ok( is_valid_json( $result, 'artist_albums' ), "artist_albums" );

show_and_pause($result);

#------------------#

$result = $obj->track('0eGsygTp906u18L0Oimnem');

ok( is_valid_json( $result, 'track' ), "track returned valid json" );

show_and_pause($result);

#------------------#

$result = $obj->tracks('0eGsygTp906u18L0Oimnem,1lDWb6b6ieDQ2xT7ewTC3G');

ok( is_valid_json( $result, 'tracks' ), "tracks returned valid json" );

show_and_pause($result);

#------------------#

$result = $obj->artist_top_tracks(
    '43ZHCT0cAZBISjO8DG9PnE', 'SE'

);

show_and_pause($result);

ok( is_valid_json( $result, 'artist_top_tracks' ), "artist_top_tracks call" );

#------------------#

$result = $obj->artist_related_artists('43ZHCT0cAZBISjO8DG9PnE');

show_and_pause($result);

ok(
    is_valid_json( $result, 'artist_related_artists' ),
    "artist_related_artists call"
);

#------------------#

# need a test user?
# spotify:user:elainelin
$result = $obj->user('glennpmcdonald');

ok( is_valid_json( $result, 'user' ), "user (glennpmcdonald)" );

show_and_pause($result);

#------------------#

$result = $obj->search(
    'tania bowra',
    'artist',
    { limit => 15, offset => 0 }
);

my $image_url = $obj->get('artists.items[0].images[0].url');

ok( defined $image_url );

show_and_pause($result);

# }
=cut

sub is_valid_json {
    my $json = shift;
    my $decoded;
    try {
        $decoded = decode_json($json);
    }
    catch {
        diag 'could not decode JSON';
        diag $json;
        diag $_;
    };

    return defined $decoded;
}

done_testing();
