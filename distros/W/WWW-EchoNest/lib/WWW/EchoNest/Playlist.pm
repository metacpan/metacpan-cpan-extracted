
package WWW::EchoNest::Playlist;

use 5.010;
use strict;
use warnings;
use Carp;

BEGIN {
    our @EXPORT      = ();
    our @EXPORT_OK   = qw( static _playlist_types );
}
use parent qw( WWW::EchoNest::PlaylistProxy Exporter );

use WWW::EchoNest::Functional qw(
                                    any
                                    keep
                                    make_stupid_accessor
                               );
use WWW::EchoNest::Util qw( fix_keys call_api );
use WWW::EchoNest::Song;

use overload
    '""' => '_stringify',
    ;



########################################################################
#
# METHODS
#

make_stupid_accessor( qw[ type ] );

{
    my @playlist_types = qw( artist artist-radio artist-description song-radio );
    sub _playlist_types { @playlist_types }

    sub new {
        use WWW::EchoNest::Catalog;

        # First define some functions to help us process the arguments
        my $keep_if_defined = sub {
            my $keepers =
                [
                 'variety',
                 'max_tempo',
                 'min_tempo',
                 'max_duration',
                 'min_duration',
                 'max_loudness',
                 'min_loudness',
                 'max_danceability',
                 'min_danceability',
                 'max_energy',
                 'min_energy',
                 'artist_max_familiarity',
                 'artist_min_familiarity',
                 'artist_max_hotttnesss',
                 'artist_min_hotttnesss',
                 'song_max_hotttnesss',
                 'song_min_hotttnesss',
                 'mode',
                 'key',
                 'max_latitude',
                 'min_latitude',
                 'max_longitude',
                 'min_longitude',
                 'rank_type',
                 'test_new_things',
                ];
            keep($_[0], sub { defined($_[0]) }, $keepers);
        };

        my $keep_if_true = sub {
            my $keepers =
                [
                 'type',
                 'artist_pick',
                 'artist',
                 'artist_id',
                 'song_id',
                 'description',
                 'style',
                 'mood',
                 'sort',
                 'buckets',
                 'limit',
                 'dmca',
                 'chain_xspf',
                 'steer',
                 'steer_description',
                ];
            keep($_[0], sub { $_[0] }, $keepers);
        };

        my $class        = $_[0];
        my $args_ref     = $_[1];
        my $session_id   = $args_ref->{session_id};
    
        my $playlist_ref = $keep_if_true->( $keep_if_defined->( $args_ref ) );

        # Set defaults
        $playlist_ref->{type}          //= 'artist';
        $playlist_ref->{artist_pick}   //= 'song_hotttnesss-desc';
        $playlist_ref->{variety}       //= 0.5;
    
        for ( qw[ limit dmca chain_xspf ] ) {
            if ( $playlist_ref->{$_} ) {
                $playlist_ref->{$_} = 'true';
            } else {
                $playlist_ref->{$_} = 'false';
            }
        }

        # Check the type
        my $type = $playlist_ref->{type};
        croak "Unrecognized type: $type"
            if ! grep { $type eq $_ } @playlist_types;

        # Check the seed and source catalogs
        my $seed_catalog     = $playlist_ref->{seed_catalog};
        my $source_catalog   = $playlist_ref->{source_catalog};

        if ($seed_catalog) {
            $playlist_ref->{seed_catalog} = $seed_catalog->get_id
                if ($seed_catalog->isa( 'WWW::EchoNest::Catalog' ));
        }

        if ($source_catalog) {
            $playlist_ref->{source_catalog} = $source_catalog->get_id
                if ($source_catalog->isa( 'WWW::EchoNest::Catalog' ));
        }

        return $class->SUPER::new( $playlist_ref );
    }
}

sub get_next_song {
    my($self, $args_ref) = @_;
    my $response = $self->get_attribute( { method => 'dynamic' } );
    $self->{'songs'} = $response->{songs};
    return if ! $self->{songs};
    if (my $songs_ref = $self->{songs}) {
        return WWW::EchoNest::Song->new( fix_keys( $songs_ref->[0] ) );
    }
    return;
}

sub get_current_song {
    my($self, $args_ref) = @_;
    if ( my $songs_ref = $self->{songs} || [ $self->get_next_song() ] ) {
        return WWW::EchoNest::Song->new( fix_keys($songs_ref->[0]) );
    }
    return;
}

sub session_info {
    return $_[0]->get_attribute(
                                {
                                 method       => 'session_info',
                                 session_id   => $_[0]->get_session_id(),
                                },
                               );
}



########################################################################
#
# FUNCTIONS
#
sub _stringify {
    my($self) = @_;
    return '<Playlist - ' . $self->get_session_id() . '>';
}

sub static {
    use WWW::EchoNest::Catalog;
    
    # First define some functions to help us process the arguments
    my $keep_if_defined = sub {
        my $keepers =
            [
             'variety',
             'results',
             'max_tempo',
             'min_tempo',
             'max_duration',
             'min_duration',
             'max_loudness',
             'min_loudness',
             'max_danceability',
             'min_danceability',
             'max_energy',
             'min_energy',
             'artist_max_familiarity',
             'artist_min_familiarity',
             'artist_max_hotttnesss',
             'artist_min_hotttnesss',
             'song_max_hotttnesss',
             'song_min_hotttnesss',
             'mode',
             'key',
             'max_latitude',
             'min_latitude',
             'max_longitude',
             'min_longitude',
             'rank_type',
             'test_new_things',
            ];
        keep($_[0], sub { defined($_[0]) }, $keepers);
    };

    my $keep_if_true = sub {
        my $keepers =
            [
             'type',
             'artist_pick',
             'artist',
             'artist_id',
             'song_id',
             'description',
             'style',
             'mood',
             'sort',
             'buckets',
             'limit',
            ];
        keep($_[0], sub { $_[0] }, $keepers);
    };

    my $args_ref     = $_[0];
    my $playlist_ref = $keep_if_true->( $keep_if_defined->( $args_ref ) );

    # Set defaults
    $playlist_ref->{type}          //= 'artist';
    $playlist_ref->{artist_pick}   //= 'song_hotttnesss-desc';
    $playlist_ref->{variety}       //= 0.5;
    
    for ( qw[ limit ] ) {
        if ( $playlist_ref->{$_} ) {
            $playlist_ref->{$_} = 'true';
        } else {
            $playlist_ref->{$_} = 'false';
        }
    }

    my $type             = $playlist_ref->{type};
    my $seed_catalog     = $playlist_ref->{seed_catalog};
    my $source_catalog   = $playlist_ref->{source_catalog};
    my $artist           = $playlist_ref->{artist};
    my $artist_id        = $playlist_ref->{artist_id};
    my $song_id          = $playlist_ref->{song_id};

    # Check the type
    croak "Unrecognized type: $type"
        if ! grep { $type eq $_ }
            (
             'artist',
             'artist-radio',
             'artist-description',
             'song-radio',
            );

    # Check the seed and source catalogs
    if ($seed_catalog) {
        $playlist_ref->{seed_catalog} = $seed_catalog->get_id
            if ($seed_catalog->isa( 'WWW::EchoNest::Catalog' ));
    }

    if ($source_catalog) {
        $playlist_ref->{source_catalog} = $source_catalog->get_id
            if ($source_catalog->isa( 'WWW::EchoNest::Catalog' ));
    }

    # Check that the 'type' jives with 'description', 'style' and 'mood'
    my $acceptable_type = any map { $_ eq $type }
        (
         'artist-description',
         'artist-radio',
         'song-radio',
        );

    my $is_valid = sub {
        for my $param (@_) {
            my $val = $playlist_ref->{ $param };
            my $reason = <<"REASON";
Invalid parameter: the $param parameter must be used in conjunction with a <type>
parameter specifying an artist-description, artist-radio, or song-radio playlist.
REASON
            croak $reason if ($val and not $acceptable_type);
        }
    };

    # Basically if any of these args are provided, <type> has to be either
    # 'artist-description', 'artist-radio', or 'song-radio'
    $is_valid->( qw[ description style mood ] );

    my $desc_or_style_or_mood =
        $playlist_ref->{description} || $playlist_ref->{style}
            || $playlist_ref->{mood};

    my $reason = <<'REASON';
Invalid parameter: the "style", "mood", and "description" parameters must
be used in conjunction with a "type" parameter specifying an artist-description
playlist.
REASON
    croak $reason
        if ($type eq 'artist-description' and not $desc_or_style_or_mood);
    
    $reason = <<'REASON';
Invalid parameter: the "description", "style", and "mood" parameters may not be
used in conjunction with an "artist", "artist_id", or "song_id" parameter.
REASON
    croak $reason
        if (
            $desc_or_style_or_mood
            and ($artist or $artist_id or $song_id)
            and $type ne 'artist-radio'
           );

    my $result = call_api(
                          {
                           method => 'playlist/static',
                           params => $playlist_ref,
                          }
                         );
    return map { WWW::EchoNest::Song->new(fix_keys($_)) }
        @{ $result->{response}{songs} };
}

1;

__END__

=head1 NAME

WWW::EchoNest::Playlist - A Dynamic Playlist Object.

=head1 SYNOPSIS
    
  The Playlist module loosely covers L< http://developer.echonest.com/docs/v4/playlist.html >.
  Refer to the official api documentation if you are unsure about something.

=head1 METHODS

=head2 new

  Returns a new WWW::EchoNest::Playlist instance.

  NOTE:
    WWW::EchoNest also provides a get_playlist() convenience function that also returns a new WWW::EchoNest::Playlist instance.

  ARGUMENTS:
    type => a string representing the playlist type -- ('artist', 'artist-radio', 'artist-description', 'song-radio')
    artist_pick => How songs should be chosen for each artist
    variety => A number between 0 and 1 specifying the variety of the playlist
    artist_id => the artist_id
    artist => the name of an artist
    song_id => the song_id
    description => A string describing the artist and song
    style => A string describing the style/genre of the artist and song
    mood => A string describing the mood of the artist and song
    results => An integer number of results to return
    max_tempo => The max tempo of song results
    min_tempo => The min tempo of song results
    max_duration => The max duration of song results
    min_duration => The min duration of song results
    max_loudness => The max loudness of song results
    min_loudness => The min loudness of song results
    artist_max_familiarity => A float specifying the max familiarity of artists to search for
    artist_min_familiarity => A float specifying the min familiarity of artists to search for
    artist_max_hotttnesss => A float specifying the max hotttnesss of artists to search for
    artist_min_hotttnesss => A float specifying the max hotttnesss of artists to search for
    song_max_hotttnesss => A float specifying the max hotttnesss of songs to search for
    song_min_hotttnesss => A float specifying the max hotttnesss of songs to search for
    max_energy => The max energy of song results
    min_energy => The min energy of song results
    max_dancibility => The max dancibility of song results
    min_dancibility => The min dancibility of song results
    mode => 0 or 1 (minor or major)
    key => 0-11 (c, c-sharp, d, e-flat, e, f, f-sharp, g, a-flat, a, b-flat, b)
    max_latitude => A float specifying the max latitude of artists to search for
    min_latitude => A float specifying the min latitude of artists to search for
    max_longitude => A float specifying the max longitude of artists to search for
    min_longitude => A float specifying the min longitude of artists to search for
    sort => A string indicating an attribute and order for sorting the results
    buckets => A list of strings specifying which buckets to retrieve
    limit => A boolean indicating whether or not to limit the results to one of the id spaces specified in buckets
    seed_catalog => A Catalog object or catalog id to use as a seed
    source_catalog => A Catalog object or catalog id
    steer => A steering value to determine the target song attributes
    steer_description => A steering value to determine the target song description term attributes
    rank_type => A string denoting the desired ranking for description searches, either 'relevance' or 'familiarity'



  RETURNS:
    A new instance of WWW::EchoNest::Playlist.

  EXAMPLE:
    use WWW::EchoNest qw( :all );
    use WWW::EchoNest::Playlist;
    my $playlist = get_playlist( { type => 'artist-radio', artist => [ 'The Beatles', 'The Rolling Stones', ], } );
    

=head2 get_next_song

  Get the next song in the playlist.

  ARGUMENTS:
    none

  RETURNS:
    A WWW::EchoNest::Song instance.

  EXAMPLE:
    my $next_song = $playlist->get_next_song();



=head2 get_current_song

  Get the current song in the playlist.

  ARGUMENTS:
    none

  RETURNS:
    A WWW::EchoNest::Song instance.

  EXAMPLE:
    my $curr_song = $playlist->get_current_song();



=head2 session_info

  Get information about the playlist.

  ARGUMENTS:
    none

  RETURNS:
    A reference to a hash that contains diagnostic information
    about the currently running playlist.

  EXAMPLE:
    my $playlist_info = $playlist->session_info();



=head1 FUNCTIONS

=head2 static

  Get a static playlist.

  ARGUMENTS:
    type => a string representing the playlist type ('artist', 'artist-radio', ...)
    artist_pick => How songs should be chosen for each artist
    variety => A number between 0 and 1 specifying the variety of the playlist
    artist_id => the artist_id
    artist => the name of an artist
    song_id => the song_id
    description => A string describing the artist and song
    style => A string describing the style/genre of the artist and song
    mood => A string describing the mood of the artist and song
    results => An integer number of results to return
    max_tempo => The max tempo of song results
    min_tempo => The min tempo of song results
    max_duration => The max duration of song results
    min_duration => The min duration of song results
    max_loudness => The max loudness of song results
    min_loudness => The min loudness of song results
    artist_max_familiarity => A float specifying the max familiarity of artists to search for
    artist_min_familiarity => A float specifying the min familiarity of artists to search for
    artist_max_hotttnesss => A float specifying the max hotttnesss of artists to search for
    artist_min_hotttnesss => A float specifying the max hotttnesss of artists to search for
    song_max_hotttnesss => A float specifying the max hotttnesss of songs to search for
    song_min_hotttnesss => A float specifying the max hotttnesss of songs to search for
    max_energy => The max energy of song results
    min_energy => The min energy of song results
    max_dancibility => The max dancibility of song results
    min_dancibility => The min dancibility of song results
    mode => 0 or 1 (minor or major)
    key => 0-11 (c, c-sharp, d, e-flat, e, f, f-sharp, g, a-flat, a, b-flat, b)
    max_latitude => A float specifying the max latitude of artists to search for
    min_latitude => A float specifying the min latitude of artists to search for
    max_longitude => A float specifying the max longitude of artists to search for
    min_longitude => A float specifying the min longitude of artists to search for                        
    sort => A string indicating an attribute and order for sorting the results
    buckets => A list of strings specifying which buckets to retrieve
    limit => A boolean indicating whether or not to limit the results to one of the id spaces specified in buckets
    seed_catalog => A Catalog object or catalog id to use as a seed
    source_catalog => A Catalog object or catalog id
    rank_type => A string denoting the desired ranking for description searches, either 'relevance' or 'familiarity'



  RETURNS:
    A reference to a hash that contains diagnostic information about the currently running playlist.

  EXAMPLE:
    use WWW::EchoNest::Playlist qw( static );
    my $static_playlist = static( { type => 'artist-radio', artist => [ 'The Beatles', 'The Rolling Stones', ], } );



=head1 AUTHOR

Brian Sorahan, C<< <bsorahan@gmail.com> >>

=head1 SUPPORT

Join the Google group: <http://groups.google.com/group/www-echonest>

=head1 ACKNOWLEDGEMENTS

Thanks to all the folks at The Echo Nest for providing access to their
powerful API.

=head1 LICENSE

Copyright 2011 Brian Sorahan.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
