# NAME

WWW::Spotify - Spotify Web API Wrapper

# VERSION

version 0.011

# SYNOPSIS

    use WWW::Spotify ();

    my $spotify = WWW::Spotify->new();

    my $result;

    $result = $spotify->album('0sNOF9WDwhWunNAHPD3Baj');

    # $result is a json structure, you can operate on it directly
    # or you can use the "get" method see below

    $result = $spotify->albums( '41MnTivkwTO3UUJ8DrqEJJ,6JWc4iAiJ9FjyK0B59ABb4,6UXCm6bOO4gFlDQZV5yL37' );

    $result = $spotify->albums_tracks( '6akEvsycLGftJxYudPjmqK',
    {
        limit => 1,
        offset => 1

    }
    );

    $result = $spotify->artist( '0LcJLqbBmaGUft1e9Mm8HV' );

    my $artists_multiple = '0oSGxfWSnnOXhD2fKuz2Gy,3dBVyJ7JuOMt4GE9607Qin';

    $result = $spotify->artists( $artists_multiple );

    $result = $spotify->artist_albums( '1vCWHaC5f2uS3yhpwWbIA6' ,
                        { album_type => 'single',
                          # country => 'US',
                          limit   => 2,
                          offset  => 0
                        }  );

    $result = $spotify->track( '0eGsygTp906u18L0Oimnem' );

    $result = $spotify->tracks( '0eGsygTp906u18L0Oimnem,1lDWb6b6ieDQ2xT7ewTC3G' );

    $result = $spotify->artist_top_tracks( '43ZHCT0cAZBISjO8DG9PnE', # artist id
                                            'SE' # country
                                            );

    $result = $spotify->search(
                        'tania bowra' ,
                        'artist' ,
                        { limit => 15 , offset => 0 }
    );

    $result = $spotify->user( 'glennpmcdonald' );

    # public play interaction example
    # NEED TO SET YOUR o_auth client_id and secret for these to work

    $spotify->browse_featured_playlists( country => 'US' );

    my $link = $spotify->get('playlists.items[*].href');

    # $link is an arrayfef of the all the playlist urls

    foreach my $for_tracks (@{$link}) {
        # make sure the links look valid
        next if $for_tracks !~ /spotify\/play/;
        $spotify->query_full_url($for_tracks,1);
        my $pl_name = $spotify->get('name');
        my $tracks  = $spotify->get('tracks.items[*].track.id');
        foreach my $track (@{$tracks}) {
                print "$track\n";
            }
        }

# DESCRIPTION

Wrapper for the Spotify Web API.

https://developer.spotify.com/web-api/

Have access to a JSON viewer to help develop and debug. The Chrome JSON viewer is
very good and provides the exact path of the item within the JSON in the lower left
of the screen as you mouse over an element.

# CONSTRUCTOR ARGS

## ua

You may provide your own user agent object to the constructor.  This should be
a [LWP:UserAgent](LWP:UserAgent) or a subclass of it, like [WWW::Mechanize](https://metacpan.org/pod/WWW%3A%3AMechanize). If you are
using [WWW::Mechanize](https://metacpan.org/pod/WWW%3A%3AMechanize), you may want to set autocheck off.  To get extra
debugging information, you can do something like this:

    use LWP::ConsoleLogger::Easy qw( debug_ua );
    use WWW::Mechanize ();
    use WWW::Spotify ();

    my $mech = WWW::Mechanize->new( autocheck => 0 );
    debug_ua( $mech );
    my $spotify = WWW::Spotify->new( ua => $mech )

# METHODS

## auto\_json\_decode

When true results will be returned as JSON instead of a perl data structure

    $spotify->auto_json_decode(1);

## auto\_xml\_decode

When true results will be returned as JSON instead of a perl data structure

    $spotify->auto_xml_decode(1);

## get

Returns a specific item or array of items from the JSON result of the
last action.

       $result = $spotify->search(
                           'tania bowra' ,
                           'artist' ,
                           { limit => 15 , offset => 0 }
       );

    my $image_url = $spotify->get( 'artists.items[0].images[0].url' );

JSON::Path is the underlying library that actually parses the JSON.

## query\_full\_url( $url , \[needs o\_auth\] )

Results from some calls (playlist for example) return full urls that can be in their entirety. This method allows you
make a call to that url and use all of the o\_auth and other features provided.

    $spotify->query_full_url( "https://api.spotify.com/v1/users/spotify/playlists/06U6mm6KPtPIg9D4YGNEnu" , 1 );

## album

equivalent to /v1/albums/{id}

    $spotify->album('0sNOF9WDwhWunNAHPD3Baj');

used album vs albums since it is a singular request

## albums

equivalent to /v1/albums?ids={ids}

    $spotify->albums( '41MnTivkwTO3UUJ8DrqEJJ,6JWc4iAiJ9FjyK0B59ABb4,6UXCm6bOO4gFlDQZV5yL37' );

or

    $spotify->albums( [ '41MnTivkwTO3UUJ8DrqEJJ',
                        '6JWc4iAiJ9FjyK0B59ABb4',
                        '6UXCm6bOO4gFlDQZV5yL37' ] );

## albums\_tracks

equivalent to /v1/albums/{id}/tracks

    $spotify->albums_tracks('6akEvsycLGftJxYudPjmqK',
    {
        limit => 1,
        offset => 1

    }
    );

## artist

equivalent to /v1/artists/{id}

    $spotify->artist( '0LcJLqbBmaGUft1e9Mm8HV' );

used artist vs artists since it is a singular request and avoids collision with "artists" method

## artists

equivalent to /v1/artists?ids={ids}

    my $artists_multiple = '0oSGxfWSnnOXhD2fKuz2Gy,3dBVyJ7JuOMt4GE9607Qin';

    $spotify->artists( $artists_multiple );

## artist\_albums

equivalent to /v1/artists/{id}/albums

    $spotify->artist_albums( '1vCWHaC5f2uS3yhpwWbIA6' ,
                        { album_type => 'single',
                          # country => 'US',
                          limit   => 2,
                          offset  => 0
                        }  );

## artist\_top\_tracks

equivalent to /v1/artists/{id}/top-tracks

    $spotify->artist_top_tracks( '43ZHCT0cAZBISjO8DG9PnE', # artist id
                                 'SE' # country
                                            );

## artist\_related\_artists

equivalent to /v1/artists/{id}/related-artists

    $spotify->artist_related_artists( '43ZHCT0cAZBISjO8DG9PnE' );

## search

equivalent to /v1/search?type=album (etc)

    $spotify->search(
                        'tania bowra' ,
                        'artist' ,
                        { limit => 15 , offset => 0 }
    );

## track

equivalent to /v1/tracks/{id}

    $spotify->track( '0eGsygTp906u18L0Oimnem' );

## tracks

equivalent to /v1/tracks?ids={ids}

    $spotify->tracks( '0eGsygTp906u18L0Oimnem,1lDWb6b6ieDQ2xT7ewTC3G' );

## browse\_featured\_playlists

equivalent to /v1/browse/featured-playlists

    $spotify->browse_featured_playlists();

requires OAuth

## browse\_new\_releases

equivalent to /v1/browse/new-releases

requires OAuth

    $spotify->browse_new_releases

## force\_client\_auth

Boolean

will pass authentication (OAuth) on all requests when set

    $spotify->force_client_auth(1);

## user

equivalent to /user

## oauth\_client\_id

needed for requests that require OAuth, see Spotify API documentation for more information

    $spotify->oauth_client_id('2xfjijkcjidjkfdi');

Can also be set via environment variable, SPOTIFY\_CLIENT\_ID

## oauth\_client\_secret

needed for requests that require OAuth, see Spotify API documentation for more information

    $spotify->oauth_client_secret('2xfjijkcjidjkfdi');

Can also be set via environment variable, SPOTIFY\_CLIENT\_SECRET

# THANKS

Paul Lamere at The Echo Nest / Spotify

All the great Perl community members that keep Perl fun

# AUTHOR

Aaron Johnson <aaronjjohnson@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Aaron Johnson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
