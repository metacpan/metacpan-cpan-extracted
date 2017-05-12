#!/usr/bin/perl

####################################################################
### WebService::Pandora - search.pl                              ###
###                                                              ###
### This script will iterate through all of the song and artist  ###
### results of a particular search string, listing the best      ###
### matches first, printing them to stdout.                      ###
####################################################################

use strict;
use warnings;

use WebService::Pandora;
use Data::Dumper;

use constant USERNAME => 'email@address.com';
use constant PASSWORD => 'password';
use constant SEARCH_TEXT => 'jonathan coulton want you gone';

my $websvc = WebService::Pandora->new( username => USERNAME,
                                       password => PASSWORD );

# first we have to do the partner + user login
$websvc->login() or die( $websvc->error() );

# query pandora with our search string
my $result = $websvc->search( searchText => SEARCH_TEXT ) or die( $websvc->error() );

my $songs = $result->{'songs'};
my $artists = $result->{'artists'};

# look at the song results first
print "Songs:\n\n";

# loop through each song, sorted by search score with best match first
foreach my $song ( sort { $b->{'score'} <=> $a->{'score'} } @$songs ) {

    my $artistName = $song->{'artistName'};
    my $songName = $song->{'songName'};
    my $musicToken = $song->{'musicToken'};

    print "$artistName - $songName [$musicToken]\n";
}

# now look at the artist results
print "\nArtists:\n\n";

# loop through each artist, sorted by search score with best match first
foreach my $artist ( sort { $b->{'score'} <=> $a->{'score'} } @$artists ) {

    my $artistName = $artist->{'artistName'};
    my $musicToken = $artist->{'musicToken'};

    print "$artistName [$musicToken]\n";
}
