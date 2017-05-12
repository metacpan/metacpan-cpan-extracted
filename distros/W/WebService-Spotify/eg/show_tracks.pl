use strict;
use warnings;
use WebService::Spotify;
use Data::Dumper;

my $spotify = WebService::Spotify->new;
my $results = $spotify->search('weezer', limit => 20);
say $_->{name} for @{$results->{tracks}->{items}};