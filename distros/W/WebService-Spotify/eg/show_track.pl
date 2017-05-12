use strict;
use warnings;
use WebService::Spotify;
use Data::Dumper;

my $track_id = $ARGV[0] || 'spotify:track:0Svkvt5I79wficMFgaqEQJ';

my $sp = WebService::Spotify->new;
my $track = $sp->track($track_id);
print Dumper $track;