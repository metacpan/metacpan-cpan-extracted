#!/usr/bin/env perl
use strict;
use warnings;

use WebService::YTSearch;

my $key = shift || $ENV{YOUTUBE_API_KEY} || die "Usage: perl $0 12345abcde query num max\n";
my $id  = shift || 'jjBQTw1e8iU';

my $ws = WebService::YTSearch->new(key => $key);

my $query = { videoId => $id, cmd => 'commentThreads', textFormat => 'plainText' };

my $r = $ws->search(%$query);

binmode(STDOUT, ':utf8');

for my $item ($r->{items}->@*) {
    my $x = $item->{snippet}{topLevelComment}{snippet};
    printf "%s: %s\n\n",
        $x->{authorDisplayName},
        $x->{textOriginal};
}
