use strict;
use warnings;
use WebService::Spotify;
use Data::Dumper;

my $artist_id = $ARGV[0] || 'spotify:artist:3jOstUTkEu2JkjvRdBA5Gu';

my $sp = WebService::Spotify->new;
my $artist = $sp->artist($artist_id);
print Dumper $artist;