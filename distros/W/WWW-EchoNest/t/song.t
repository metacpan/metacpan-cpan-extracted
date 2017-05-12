#!/usr/bin/perl -T

use 5.010;
use strict;
use warnings;
use Carp;

use Test::More 'no_plan';

BEGIN {
    use_ok( 'WWW::EchoNest',        qw[ get_song                            ] );
    use_ok( 'WWW::EchoNest::Id',    qw[ is_id                               ] );
    use_ok( 'WWW::EchoNest::Song',  qw[ profile search_song identify        ] );
    use_ok( 'WWW::EchoNest::ConfigData'                                       );
}

# The song object we will use in testing.
my $song_ref;

# Build-time configuration data
my $test_file     = WWW::EchoNest::ConfigData->feature( 'test_file'     );
my $codegen_found = WWW::EchoNest::ConfigData->feature( 'codegen_found' );

# Info to be used by song_search and others
my %query_info =
    (
     artist    => 'Lupe Fiasco',
     title     => 'The Show Goes On',
    );



########################################################################
#
# identify
# - This function is only tested if the 'codegen_found' property is true.
#
{
    my $method = 'song/identify';
    
    SKIP : {
        skip 'No codegen found', 3 if not $codegen_found;
        
        can_ok( 'WWW::EchoNest::Song', qw[ identify ] );
        my $song_ref = identify( { filename => $test_file } );
        ok( defined($song_ref), 'identify returns a defined result' );
        isa_ok( $song_ref, 'WWW::EchoNest::Song' );
    }
}



########################################################################
#
# search_song
#

$song_ref = search_song( \%query_info );
isa_ok( $song_ref, 'WWW::EchoNest::Song' );



########################################################################
#
# Test the OO interface using $song_ref
#
is(
   lc $song_ref->get_artist_name,
   lc $query_info{'artist'},
   'get_artist_name checks out'
  );

is(
   lc $song_ref->get_title,
   lc $query_info{'title'},
   'get_title checks out'
  );

my $song_id = $song_ref->get_id;
ok(
   is_id($song_id),
   'song/search returns a song with a valid id'
  );

my $artist_id = $song_ref->get_artist_id;
ok(
   is_id($artist_id),
   'song/search returns a song with a valid artist id'
  );



########################################################################
#
# get_audio_summary
#
my $audio_summary_ref = $song_ref->get_audio_summary;
ok( defined($audio_summary_ref)
    && ref($audio_summary_ref) eq 'HASH',
    'get_audio_summary returns a well-defined HASH ref' );



########################################################################
#
# get_song_hotttnesss
#
my $song_hotttnesss = $song_ref->get_song_hotttnesss;
ok( (not defined($song_hotttnesss)) || ($song_hotttnesss =~ m{\d*.?\d*}),
    'get_song_hotttnesss returns a float' );



########################################################################
#
# get_artist_hotttnesss
#
my $artist_hotttnesss = $song_ref->get_artist_hotttnesss;
ok( defined($artist_hotttnesss)
    && ($artist_hotttnesss =~ m{\d*.?\d*}),
    'get_artist_hotttnesss returns a float' );



########################################################################
#
# get_artist_familiarity
#
my $artist_familiarity = $song_ref->get_artist_familiarity;
ok( defined($artist_familiarity)
    && ($artist_familiarity =~ m{\d*.?\d*}),
    'get_artist_familiarity returns a float' );



########################################################################
#
# get_artist_location
#
my $artist_location = $song_ref->get_artist_location;
ok( defined($artist_location)
    && (ref($artist_location) eq 'HASH')
    && ($artist_location->{'longitude'} =~ m{\d*.?\d*})
    && ($artist_location->{'latitude'}  =~ m{\d*.?\d*})
    && (exists $artist_location->{'location'}),
    'get_artist_location returns a valid location hashref' );



########################################################################
#
# get_foreign_id
#
my $mb_id
    = $song_ref->get_foreign_id(
                                         {
                                          idspace => 'musicbrainz',
                                         },
                                        );
ok( defined($mb_id)
    && is_id($mb_id),
    'get_foreign_id returns a valid id' );



########################################################################
#
# get_tracks
#
my $catalog_string    = '7digital';
my $catalog_ref       = { catalog => $catalog_string };
my @tracks   = $song_ref->get_tracks($catalog_ref);
my $track    = $tracks[0];
my $catalog  = $track->{'catalog'};

SKIP : {
    my $reason = "No $catalog_string tracks for 'Moisture'";
    skip $reason, 1 if ! defined($catalog);
    is( $catalog,
        $catalog_string,
        "passing { catalog => $catalog_string } to get_tracks returned "
        ."a $catalog_string catalog entry for The Residents" );
};

# Moisture, by The Residents, doesn't seem to have a musicbrainz or 7digital
# id, so let's try a different one
my $lmfao_hash_ref =
    {
     artist        => 'LMFAO',
     title         => 'Party Rock Anthem',
    };

my @lmfao_songs        = search_song($lmfao_hash_ref);
my $lmfao_song_ref     = $lmfao_songs[0];
my @lmfao_tracks       = $lmfao_song_ref->get_tracks($catalog_ref);
my $lmfao_track        = $lmfao_tracks[0];
my $lmfao_catalog      = $lmfao_track->{'catalog'};
SKIP : {
    my $reason = "No $catalog_string tracks for 'Party Rock Anthem'";
    skip $reason, 1 if ! defined($lmfao_catalog);
    is( $lmfao_catalog,
        $catalog_string,
        "passing { catalog => $catalog_string } to get_tracks returned "
        ."a $catalog_string catalog entry for LMFAO"
      );
};



########################################################################
#
# &WWW::EchoNest::Song::profile
#
my $profile_hash_ref = { ids => [ $song_id ], buckets => [ 'audio_summary' ] };
my $song_profile_ref = profile($profile_hash_ref);
isa_ok( $song_profile_ref, 'WWW::EchoNest::Song' );

