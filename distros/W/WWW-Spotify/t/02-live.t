use strict;

use Data::Dumper;

use Test::More;
use Test::RequiresInternet (
    'accounts.spotify.com' => 443,
    'api.spotify.com'      => 443,
    'www.spotify.com'      => 80,
);
use WWW::Spotify;

SKIP: {
    skip 'No SPOTIFY_CLIENT_ID', 5 unless $ENV{SPOTIFY_CLIENT_ID};

    my $obj = WWW::Spotify->new();

    #------------------#

    # $obj->debug(1);

    #------------------#

    # ok( $obj->debug(0) == 0 , 'turn debug off' );

    sub show_and_pause {
        if ( $obj->debug() ) {
            my $show = shift;
            print Dumper($show);
            sleep 5;
        }
    }

    my $result;

    ok(
        $obj->oauth_client_id( $ENV{SPOTIFY_CLIENT_ID} ),
        'set client id'
    );

    ok(
        $obj->oauth_client_secret( $ENV{SPOTIFY_CLIENT_SECRET} ),
        'set client secret'
    );

    ok( $obj->get_client_credentials(), 'get client credentials' );

    $result = $obj->browse_featured_playlists();

    ok(
        $result =~ /total/,
        'result string for browse_featured_playlists contains the word total'
    );

    $result = $obj->browse_new_releases(
        { country => 'US', limit => 5, offset => 2 } );

    ok(
        $result =~ /total/,
        'result string for browse_new_releases contains the word total'
    );

}

done_testing();
