# Grab all the track listings from one of Gilles Peterson's Radio 6 shows
#!perl

use strict;
use warnings;

use feature 'say';
use FindBin::libs;

use WWW::BBC::TrackListings;

binmode(STDOUT, ":utf8");

my $tracks = WWW::BBC::TrackListings->new({ url => "http://www.bbc.co.uk/programmes/b03c8l9l" });

for my $track ( $tracks->all_tracks ) {
    say $track->artist . " - " . $track->title;
}
