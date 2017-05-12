#!/usr/bin/perl -T

use 5.010;
use strict;
use warnings;

use Test::More 'no_plan';

BEGIN {
    use_ok( 'WWW::EchoNest',              qw[ get_playlist                  ] );
    use_ok( 'WWW::EchoNest::Id',          qw[ is_id                         ] );
    use_ok( 'WWW::EchoNest::Playlist',    qw[ static                        ] );
    use_ok( 'WWW::EchoNest::Song',        qw[ search_song                   ] );
}


my $artists_aref = [ 'autechre', 'aphex twin', 'squarepusher' ];


########################################################################
#
# Playlist creation
#
my @playlists = (); # Array to store the playlist objects we create
my $query_ref = { artist => $artists_aref };

my $artist_playlist = new_ok( 'WWW::EchoNest::Playlist', [ $query_ref ] );
my $easy_playlist   = get_playlist('James Brown');

isa_ok( $artist_playlist, 'WWW::EchoNest::Playlist' );
isa_ok( $easy_playlist,   'WWW::EchoNest::Playlist' );

push @playlists,
    (
     $artist_playlist,
     $easy_playlist,
    );



########################################################################
#
# session_info
#
for my $playlist (@playlists) {
    can_ok( $playlist, qw[ session_info ] );
    my $playlist_info = $playlist->session_info();
    ok( defined($playlist_info), 'session_info returns a defined result' );
    is( ref($playlist_info), 'HASH', 'session_info returns a HASH ref' );
}


########################################################################
#
# get_next_song
#
for my $playlist (@playlists) {
    can_ok( $playlist, qw[ get_next_song ] );
    my $next_song = $playlist->get_next_song();
    ok( defined($next_song), 'get_next_song returns a defined result' );
    isa_ok( $next_song, 'WWW::EchoNest::Song' );
}


########################################################################
#
# get_current_song
#
for my $playlist (@playlists) {
    can_ok( $playlist, qw[ get_current_song ] );
    my $current_song = $playlist->get_current_song();
    ok( defined($current_song), 'get_current_song returns a defined result' );
    isa_ok( $current_song, 'WWW::EchoNest::Song' );
}


########################################################################
#
# static
# - if <type eq 'artist-description'> then you must provide one of the
#     <description>, <style>, or <mood> parameters.
#
can_ok( 'WWW::EchoNest::Playlist', qw[ static ] );

# Song id to be used in testing the 'song-radio' type
my %query_info = ( artist => 'Lupe Fiasco', title => 'The Show Goes On' );
my $song_ref = search_song( \%query_info );
my $test_id  = $song_ref->get_id();
ok( is_id( $test_id ), 'test_song_file has valid id' );


# A list of queries to test...
my @static_queries =
    (
     # type eq 'artist'
     {
      type           => 'artist',
      artist         => $artists_aref,
      results        => 20,
     },
     # type eq 'artist-description'
     {
      type           => 'artist-description',
      description    => 'crazy',
      results        => 20,
     },
     # type eq 'artist-radio'
     {
      type           => 'artist-radio',
      artist         => $artists_aref,
      results        => 20,
     },
     # type eq 'song-radio' needs codegen!!
     $test_id ? {
      type           => 'song-radio',
      song_id        => $test_id,
      results        => 20,
     } : (),
     # From the EN API docs
     {
      type                      => 'artist-description',
      description               => [ 'disco', '70s' ],
      artist_min_familiarity    => 0.7,
      sort                      => 'tempo-asc',
      results                   => 20,
     },
    );

for my $query_ref (@static_queries) {
    my @static_playlist = static($query_ref);
    ok( @static_playlist, 'static returns a defined result' );
    isa_ok( $static_playlist[0], 'WWW::EchoNest::Song' );
}
