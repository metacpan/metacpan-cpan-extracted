#!/usr/bin/perl -T

use 5.010;
use strict;
use warnings;

use Test::More 'no_plan';

BEGIN {
    use_ok( 'WWW::EchoNest', qw( :all  ) );
    use_ok( 'WWW::EchoNest::ConfigData' );
}



# For testing get_track #################################################
#
my $test_file = WWW::EchoNest::ConfigData->feature('test_file');



# Test the entire API ###################################################
#
my @funcs = qw( get_artist get_catalog get_playlist get_song get_track );
can_ok( 'WWW::EchoNest', @funcs );



# get_artist ############################################################
#
my @artists = ();
push @artists, get_artist('autechre');
push @artists, get_artist('ARYPTWE1187FB49D64');
push @artists, get_artist( { name => 'squarepusher' } );

for (@artists) {
    ok( defined($_), 'get_artist returns a defined result' );
    isa_ok( $_, 'WWW::EchoNest::Artist' );
}



# get_catalog ############################################################
#
my @catalogs = ();
push @catalogs, get_catalog('new_songs');
push @catalogs, get_catalog( { name => 'my_artists', type => 'artist' } );

for (@catalogs) {
    ok( defined($_), 'get_catalog returns a defined result' );
    isa_ok( $_, 'WWW::EchoNest::Catalog' );
}



# get_playlist ############################################################
#
# - Defaults to an 'artist' type, so the only required parameter (if
#   you're just looking to create an artist-based playlist) is an artist
#   name.
#
my @playlists = ();
push @playlists, get_playlist( { artist => [ qw( Blondie Curve ) ] } );
push @playlists, get_playlist( ['Tom Waits', 'Marc Ribot'] );
push @playlists, get_playlist( 'Frank Zappa' );

for (@playlists) {
    ok( defined($_), 'get_playlist returns a defined result' );
    isa_ok( $_, 'WWW::EchoNest::Playlist' );
}



# get_song ################################################################
#
my @songs = ();
push @songs, get_song( { title => 'clap hands', artist => 'tom waits' } );
push @songs, get_song('singapore'); # probably not the tom waits song :(
push @songs, get_song('SOWWTEP12A8C13F50E'); # Hello Skinny

for (@songs) {
    ok( defined($_), 'get_song returns a defined result' );
    isa_ok( $_, 'WWW::EchoNest::Song' );
}



# get_track ###############################################################
#
my @tracks = ();
push @tracks, get_track($test_file);

for (@tracks) {
    ok( defined($_), 'get_track returns a defined result' );
    isa_ok( $_, 'WWW::EchoNest::Track' );
}



# README code #############################################################
#
