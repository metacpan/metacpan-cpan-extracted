#!/usr/bin/perl

####################################################################
### WebService::Pandora - favorites.pl                           ###
###                                                              ###
### This script will iterate through all of the user's stations, ###
### getting the details of the station and grab all of the       ###
### songs that had positive feedback, printing them to stdout.   ###
####################################################################

use strict;
use warnings;

use WebService::Pandora;
use Data::Dumper;

use constant USERNAME => 'email@address.com';
use constant PASSWORD => 'password';

my $websvc = WebService::Pandora->new( username => USERNAME,
                                       password => PASSWORD );

# first we have to do the partner + user login
$websvc->login() or die( $websvc->error() );

# maintain a hashref of our favorite artists + songs
my $favorites = {};

my $result;

# get all of our stations that we'll iterate through
$result = $websvc->getStationList() or die( $websvc->error() );

my $stations = $result->{'stations'};

# loop through every station
foreach my $station ( @$stations ) {

    # get the details of this station, including the feedback
    $result = $websvc->getStation( stationToken => $station->{'stationToken'},
                                   includeExtendedAttributes => 1 )
        or die( $websvc->error() );

    # only want tracks we've thumb'd up
    my $station_favorites = $result->{'feedback'}{'thumbsUp'};

    # we might not have any feedback for this station
    next if ( !defined( $station_favorites ) );

    # loop through all of our favorites
    foreach my $favorite ( @$station_favorites ) {

        # store the artist & song in our favorites hash
        $favorites->{$favorite->{'artistName'}}{$favorite->{'songName'}} = 1;
    }
}

# get all of the artists of our favorite tracks
my @artists = keys( %$favorites );

# loop through each artist, sorted in alphabetical order
foreach my $artist ( sort { lc( $a ) cmp lc( $b ) } @artists ) {

    # get all of our favorite songs from this artist
    my @songs = keys( %{$favorites->{$artist}} );

    # loop through each song, sorted in alphabetical order
    foreach my $song ( sort { lc( $a ) cmp lc( $b ) } @songs ) {

        print "$artist - $song\n";
    }
}
