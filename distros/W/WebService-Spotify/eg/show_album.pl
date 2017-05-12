use strict;
use warnings;
use WebService::Spotify;
use Data::Dumper;

my $album_id = $ARGV[0] || 'spotify:album:3jWhmYMAWw5NvHTTeiQtfl';

my $sp = WebService::Spotify->new;
my $album = $sp->album($album_id);
print Dumper $album;