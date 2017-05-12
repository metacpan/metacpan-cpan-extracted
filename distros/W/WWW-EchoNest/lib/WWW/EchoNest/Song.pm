
package WWW::EchoNest::Song;

use 5.010;
use strict;
use warnings;
use Carp;
use Cwd qw( abs_path getcwd );
use File::Spec::Functions;
use List::Util qw( first );

use WWW::EchoNest;
our $VERSION = $WWW::EchoNest::VERSION;

BEGIN {
    our @EXPORT    = qw(  );
    our @EXPORT_OK = qw( profile search_song identify );
}
use parent qw( WWW::EchoNest::SongProxy Exporter );

use JSON;

use WWW::EchoNest::Functional qw(
                                    any
                                    keep
                                    make_stupid_accessor
                                    make_simple_accessor
                               );

use WWW::EchoNest::Util qw(
                              codegen
                              call_api
                              fix_keys
                         );



use overload
    '""' => '_stringify',
    ;



########################################################################
#
# METHODS
#
make_stupid_accessor( qw[ id title artist_name artist_id foreign_ids ] );

my $simple_accessors_ref =
    {
     attributes => [ qw( audio_summary song_hotttnesss artist_hotttnesss
                         artist_familiarity artist_location ) ],
     response_key => 'songs',
    };

make_simple_accessor( $simple_accessors_ref );

sub get_foreign_id {
    my($self, $args_ref)    = @_;
    my $use_cached          = $args_ref->{cache}      // 1;
    my $idspace             = $args_ref->{idspace}    // q[];
    
    # This should be a ref to an ARRAY of HASH-refs
    my $cached_val_ref     = $self->{foreign_ids};
    
    # This is an array of HASH-refs
    my @catalog_match = grep { $_->{catalog} eq $idspace }
        @$cached_val_ref if ($cached_val_ref && $idspace);

    # If we either don't want to use the cached value,
    # or the cached value isn't defined,
    # or the cached value doesn't contain a catalog entry for the idspace
    # the user has specified...
    if (not ($use_cached and $cached_val_ref and @catalog_match)) {
        my $request_ref = { method => 'profile', bucket => [ "id:$idspace" ] };
        my $response    = $self->get_attribute($request_ref);
        my $songs_ref   = $response->{songs};
        
        return if ! $songs_ref;

        # foreign_ids_ref is an ARRAY ref
        my $foreign_ids_ref = $songs_ref->[0]{foreign_ids}   // [];

        # if the song/profile request didn't yield a song with an id in the
        # requested id space, then we call song/search with artist_name
        if ( scalar( @$foreign_ids_ref ) == 0 ) {
            # Call song/search
            my $search_ref              = {};
            $search_ref->{artist}       = $self->{artist};
            $search_ref->{artist_id}    = $self->{artist_id};
            $search_ref->{title}        = $self->{title};
            $search_ref->{bucket}       = [ "id:$idspace" ];

            my @songs = search_song( $search_ref );
            # Use the first song doc that has a matching entry for our desired
            # idspace
            SONG : for my $song (@songs) {
                next SONG if ! (my $foreign_id_ref = $song->get_foreign_ids());
		
                ID : for my $foreign_id (@$foreign_id_ref) {
                    next ID if ! ($foreign_id->{catalog} eq $idspace);
                    $foreign_ids_ref = $foreign_id;
                    last SONG;
                }
            }
        }
	
        push @$cached_val_ref, $foreign_ids_ref;
        $self->{foreign_ids} = $cached_val_ref;
    
        my @foreign_ids = map { $_->{catalog} eq $idspace ? $_ : () }
            @{ $self->{foreign_ids} };

        if ( my $foreign_id_ref = $foreign_ids[0] ) {
            my $returned_id = $foreign_id_ref->{foreign_id};
            return $returned_id
        } else {
            return;
        }
    } else {
        return $catalog_match[0]->{foreign_id};
    }
    return;
}

sub get_tracks {
    my($self, $args_ref)   = @_;
    my $use_cached         = $args_ref->{cache}        // 1;
    my $catalog            = $args_ref->{catalog};

    # Should be a ref to an ARRAY of HASH refs
    my @cached_tracks      = @{ $self->{tracks} || [] };

    # An array of the catalog fields of each track
    my @catalogs           = map { $_->{catalog} } @cached_tracks;

    croak 'You must provide a catalog' if ! $catalog;

    # If we either don't want to use the cached value,
    # or there is no cached value,
    # or the cached value doesn't contain an entry whose catalog
    # matches the one the user has specified...
    if ( not ($use_cached and @cached_tracks and @catalogs) ) {
        my $request_ref = {
                           method  => 'profile',
                           bucket  => [ 'tracks', "id:$catalog" ],
                          };

        my $response  = $self->get_attribute($request_ref);
        my $songs_ref = $response->{songs};
        
        return if ! $songs_ref;

        # $logger->debug('$songs_ref : ', $json->encode($songs_ref));
	
        $self->{tracks} = [] if ! @cached_tracks;

        # Build the array of returned tracks.
        # Each entry is an ARRAY ref containing a list of tracks for
        # Each Song that was returned.
        my @returned_tracks;
        SONG : for my $song (@$songs_ref) {
            TRACK : for my $track (@{ $song->{tracks} }) {
                push @returned_tracks, $track;
            }
        }

        if (@returned_tracks) {
            $self->{tracks} = \@returned_tracks;
            return wantarray ? @returned_tracks : $returned_tracks[0];
        }
        
        # Call song/search if no returned tracks
        my $search_params_ref              = {};
        $search_params_ref->{artist}       = $self->{artist};
        $search_params_ref->{artist_id}    = $self->{artist_id};
        $search_params_ref->{title}        = $self->{title};
        $search_params_ref->{bucket}       = [ "id:$catalog", 'tracks' ];

        my @songs = search_song($search_params_ref);
	    
        # Use the first song that has a matching catalog
        SONG : for my $song (@songs) {
            my $track_list = $song->{tracks};
            next SONG if ! $track_list;
		
            TRACK : for my $new_track ( @$track_list ) {
                next TRACK if ! ($new_track->{catalog} eq $catalog);
                push @returned_tracks, $new_track;
                last SONG;
            }
        }

        # If we STILL haven't found a matching track...
        return if ! @returned_tracks;

        # A list of the ids of the cached tracks
        my @existing_track_ids  = map { $_->{foreign_id} } @cached_tracks;

        # A table that maps the existing track id's to a true value
        my %track_exists_for    = map { $_ => 1 } @existing_track_ids;

        # A list of HASH refs to the tracks whose id's haven't been seen before
        my @new_tracks = grep {
            not (
                 $_->{foreign_id}
                 && $track_exists_for{ $_->{foreign_id} }
                )
        } @returned_tracks;

        # Add the new tracks to the cached tracks
        push @cached_tracks, @new_tracks;
        $self->{tracks} = \@cached_tracks;
    }

    return grep { $_->{catalog} and $_->{catalog} eq $catalog }
        @cached_tracks;
}


########################################################################
#
# FUNCTIONS
#
sub _stringify {
    return q[<Song - '] . $_[0]->get_title . q['>];
}

sub identify {
    my %args               = %{ $_[0] };
    my $filename           = $args{filename};
    my $query_obj_ref      = $args{query_obj};
    my $query_obj_type     = ref($query_obj_ref);
    
    croak 'query_obj needs to be a HASH or ARRAY ref'
        if (
            defined($query_obj_ref)
            and $query_obj_type ne 'HASH'
            and $query_obj_type ne 'ARRAY'
           );
    
    my $code               = $args{code};
    my $artist             = $args{artist};
    my $title              = $args{title};
    my $release            = $args{release};
    my $duration           = $args{duration};
    my $genre              = $args{genre};
    my $buckets            = $args{buckets}               // [];
    my $codegen_start      = $args{codegen_start}         // 0;
    my $codegen_duration   = $args{codegen_duration}      // 30;

    my $post               = 0;
    my $has_data           = 0;
    my $data               = 0;

    my $cwd = abs_path( getcwd() );

    # Run the codegen on the file if it exists
    if (defined($filename)) {
        my $codegen_params =
            {
             filename     => $filename,
             start        => $codegen_start,
             duration     => $codegen_duration,
            };
	
        if (-e -f $filename) {
            eval {
                $query_obj_ref = codegen($codegen_params);
            };
	    
            croak "Error running codegen on $filename: $@" if $@;
            croak "Error running codegen on $filename"
                if ! defined($query_obj_ref);
            
        } else {
            # If abs path, we're really screwed. Otherwise, maybe it isn't
            # under the current working directory
            croak "File does not exist: $filename" if $filename =~ m[^/.*$];
	    
            # Make sure we're looking in the current working directory...
            my $filename = catfile( $cwd, $filename );
            if (-e -f $filename) {
                eval {
                    $query_obj_ref = codegen($codegen_params);
                };
		
                croak "Error running codegen on $filename: $@" if $@;
                croak "Error running codegen on $filename"
                    if ! defined($query_obj_ref);
            } else {
                croak "File does not exist: $filename";
            }
        }
    }

    # Make sure query_obj is an ARRAY ref
    $query_obj_ref = [ $query_obj_ref ]
        if (defined($query_obj_ref) and ref($query_obj_ref) ne 'ARRAY');

    # Check codegen results for an error report
    if ($filename) {
        for my $q (@{ $query_obj_ref }) {
            if (defined($q) && (ref($q) eq 'HASH')) {
                if (exists $q->{'error'}) {
                    my $error       = $q->{error};
                    my $filename    = $q->{metadata}{filename}    // '';
                    croak "$error: $filename";
                }
            }
        }
    }
    
    croak 'Not enough information to identify song'
        if (! ($filename || $query_obj_ref || $code));
    
    my %request_args       = ();
    
    $has_data = 1 && $request_args{code} = $code         if $code;
    $request_args{title}                 = $title        if $title;
    $request_args{release}               = $release      if $release;
    $request_args{bucket}                = $buckets      if $buckets;
    $request_args{duration}              = $duration     if $duration;
    $request_args{genre}                 = $genre        if $genre;

    if ( $query_obj_ref and any(@$query_obj_ref) ) {
        $has_data   = 1;
        $post       = 1;
        
        eval {
            $data = { query => encode_json($query_obj_ref) };
        };
        croak "Could not encode json string: $@" if $@;

    }

    if ($has_data) {
        my $request_hash_ref =
            {
             method               => 'song/identify',
             params               => \%request_args,
             post                 => $post,
             data                 => $data,
            };

        my $result_ref = call_api( $request_hash_ref );

        my @song_list = map {   WWW::EchoNest::Song->new(fix_keys($_))   }
            @{ $result_ref->{response}{songs} };

        return wantarray ? @song_list : $song_list[0];
    }

    return;
}


sub search_song {
    # First argument should be a hash ref
    my $args_ref = $_[0];
    
    # Define two lexical functions that help us process the arguments
    my $keep_if_true    = sub {
        my $keepers =
            [ qw( title artist artist_id combined description style sort
                  buckets rank_type limit mood ) ];
        keep($_[0], sub { $_[0] }, $keepers);
    };

    my $keep_if_defined = sub {
        my $keepers =
            [ qw( results start max_tempo min_tempo max_duration min_duration
                  max_loudness min_loudness artist_max_familiarity
                  artist_min_familiarity artist_max_hotttnesss
                  artist_min_hotttnesss song_max_hotttnesss song_min_hotttnesss
                  mode max_energy min_energy max_danceability min_danceability
                  key max_latitude min_latitude max_longitude min_longitude
                  test_new_things ) ];
        keep($_[0], sub { defined($_[0]) }, $keepers);
    };

    my $parsed_args = $keep_if_true->( $keep_if_defined->($args_ref) );

    # Set defaults
    $parsed_args->{limit}    = 'true'  if exists $parsed_args->{limit};
    $parsed_args->{results}  = 15      if ! $parsed_args->{results};

    # Change 'buckets' to 'bucket'
    if (exists $parsed_args->{buckets}) {
        $parsed_args->{bucket} = delete $parsed_args->{buckets};
    }

    my $result = call_api( { method => 'song/search', params => $parsed_args } );
    my @song_list = map {   WWW::EchoNest::Song->new(fix_keys($_))   }
        @{ $result->{response}{songs} };
    
    return wantarray ? @song_list : $song_list[0];
}

sub profile {
    my $args_ref         = $_[0];
    my $ids              = $args_ref->{ids}       // [];
    my $buckets          = $args_ref->{buckets}   // [];
    my $limit            = $args_ref->{limit};
    
    croak 'ids must be string or array ref'
        if (ref($ids) and ref($ids) ne 'ARRAY');

    $ids = [ $ids ] if ! ref($ids);

    my $parsed_args = {};
    
    $parsed_args->{id}     = $ids;
    $parsed_args->{bucket} = $buckets     if $buckets;
    $parsed_args->{limit}  = 'true'       if $limit;

    my $result = call_api( { method => 'song/profile', params => $parsed_args } );
    my @song_list = map { WWW::EchoNest::Song->new(fix_keys($_)) }
        @{ $result->{response}{songs} };
    
    return wantarray ? @song_list : $song_list[0];
}



1;



__END__



=head1 NAME

WWW::EchoNest::Song.

=head1 SYNOPSIS
    
use WWW::EchoNest::Song;


=head1 METHODS

=head2 new

  Returns a new WWW::EchoNest::Song instance.

  NOTE:
    WWW::EchoNest also provides a song() convenience function that also returns a new WWW::EchoNest::Song instance.

  ARGUMENTS:
    id         => a song ID 
    buckets    => a list of strings specifying which buckets to retrieve
  
  RETURNS:
    A new WWW::EchoNest::Song instance.

=head2 get_id

  Returns the Echo Nest Song ID.

  ARGUMENTS:
    none
  
  RETURNS:
    The Echo Nest Song ID.

=head2 get_title

  Returns the song title.

  ARGUMENTS:
    none
  
  RETURNS:
    Song title.

=head2 get_artist_name

  Returns the artist name.

  ARGUMENTS:
    none
  
  RETURNS:
    Artist name.

=head2 get_artist_id

  Returns the artist ID.

  ARGUMENTS:
    none
  
  RETURNS:
    The Echo Nest Artist ID.

=head2 get_song_hotttnesss

  Returns The Echo Nest's numerical estimation of how hottt this song is.

  ARGUMENTS:
    cache => A boolean indicating whether or not the cached value should be used (if available). Defaults to True.
  
  RETURNS:
    Float representing this song's hotttnesss.

=head2 get_artist_hotttnesss

  Returns The Echo Nest's numerical estimation of how hottt the artist for this song is.

  ARGUMENTS:
    cache => A boolean indicating whether or not the cached value should be used (if available). Defaults to True.
  
  RETURNS:
    Float representing the artist's hotttnesss for this song.

=head2 get_artist_familiarity

  Returns The Echo Nest's numerical estimation of how familiar the artist for this song is to the rest of the world.

  ARGUMENTS:
    cache    => A boolean indicating whether or not the cached value should be used (if available). Defaults to True.
  
  RETURNS:
    Float representing the artist's familiarity for this song.

=head2 get_artist_location

  Returns info about where this song's artist is from.

  ARGUMENTS:
    cache   => A boolean indicating whether or not the cached value should be used (if available). Defaults to True.
  
  RETURNS:
    A reference to a hash describing location, latitude,
    and longitude for this Song's artist.

=head2 get_audio_summary

  Get an audio summary of a song containing mode, tempo, key, duration, time signature, loudness, danceability, energy, and analysis_url.

  ARGUMENTS:
    cache => A boolean indicating whether or not the cached value should be used (if available). Defaults to True.
  
  RETURNS:
    A reference to a hash containing mode, tempo, key, duration, time signature, loudness, danceability, energy and analysis_url keys.

=head2 get_foreign_id

  Get the foreign id for this song for a specific id space.

  ARGUMENTS:
    idspace     => A string indicating the idspace to fetch a foreign id for.
  
  RETURNS:
    A foreign ID string.

=head2 get_tracks

  Get the tracks for a song given a catalog.

  ARGUMENTS:
    catalog => A string representing the catalog whose track you want to retrieve.
  
  RETURNS:
    A reference to an array of hash refs describing tracks.

=head1 FUNCTIONS

=head2 identify

  Identify a song.

  ARGUMENTS:
    filename         => The path of the file you want to analyze (requires codegen binary!)
    query_obj        => A dict or list of dicts containing a 'code' element with an fp code
    code             => A fingerprinter code
    artist           => An artist name
    title            => A song title
    release          => A release name
    duration         => A song duration
    genre            => A string representing the genre
    buckets          => A list of strings specifying which buckets to retrieve
    codegen_start    => The point (in seconds) where the codegen should start
    codegen_duration => The duration (in seconds) the codegen should analyze
  
  RETURNS:
    A foreign ID string.

=head2 search_song

  Search for songs by name, description, or constraint.

  ARGUMENTS:
    title                  => the name of a song
    artist                 => the name of an artist
    artist_id              => the artist_id
    combined               => the artist name and song title
    description            => A string describing the artist and song
    style                  => A string describing the style/genre of the artist and song
    mood                   => A string describing the mood of the artist and song
    results                => An integer number of results to return
    max_tempo              => The max tempo of song results
    min_tempo              => The min tempo of song results
    max_duration           => The max duration of song results
    min_duration           => The min duration of song results
    max_loudness           => The max loudness of song results
    min_loudness           => The min loudness of song results
    artist_max_familiarity => A float specifying the max familiarity of artists to search for
    artist_min_familiarity => A float specifying the min familiarity of artists to search for
    artist_max_hotttnesss  => A float specifying the max hotttnesss of artists to search for
    artist_min_hotttnesss  => A float specifying the max hotttnesss of artists to search for
    song_max_hotttnesss    => A float specifying the max hotttnesss of songs to search for
    song_min_hotttnesss    => A float specifying the max hotttnesss of songs to search for
    max_energy             => The max energy of song results
    min_energy             => The min energy of song results
    max_dancibility        => The max dancibility of song results
    min_dancibility        => The min dancibility of song results
    mode                   => 0 or 1 (minor or major)
    key                    => 0-11 (c, c-sharp, d, e-flat, e, f, f-sharp, g, a-flat, a, b-flat, b)
    max_latitude           => A float specifying the max latitude of artists to search for
    min_latitude           => A float specifying the min latitude of artists to search for
    max_longitude          => A float specifying the max longitude of artists to search for
    min_longitude          => A float specifying the min longitude of artists to search for                        
    sort                   => A string indicating an attribute and order for sorting the results
    buckets                => A list of strings specifying which buckets to retrieve
    limit                  => A boolean indicating whether or not to limit the results to one of the id spaces specified in buckets
    rank_type              => A string denoting the desired ranking for description searches, either 'relevance' or 'familiarity'
  
  RETURNS:
    A reference to an array of Song objects.

  EXAMPLE:
    # Insert helpful example here!

=head2 profile

  Get the profiles for multiple songs at once.

  ARGUMENTS:
    ids     => A song ID or list of song IDs
    buckets => A list of strings specifying which buckets to retrieve
    limit   => A boolean indicating whether or not to limit the results to one of the id spaces specified in buckets

  RETURNS:
    A reference to an array of Song objects.

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
