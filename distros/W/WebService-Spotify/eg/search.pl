use strict;
use warnings;
use Data::Dumper;
use WebService::Spotify;
use WebService::Spotify::Util;

my $search_str = $ARGV[0] || 'Radiohead';

my $sp = WebService::Spotify->new;
my $result = $sp->search($search_str);
print Dumper $result;
