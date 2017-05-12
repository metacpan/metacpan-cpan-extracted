#!/usr/bin/env perl
#
# $Id: recently_added.pl 11 2007-04-09 04:34:01Z hironori.yoshida $
#
package main;
use strict;
use warnings;
use version; our $VERSION = qv('1.0.3');

use blib;

use WebService::YouTube;

my $youtube = WebService::YouTube->new;

print "\n1. Get the information of the recently_added videos via RSS Feed.\n\n";
my @videos = $youtube->feeds->recently_added;
foreach my $video (@videos) {
    printf "%-33s    %-42s\n", $video->url, $video->title;
}

my $video = $videos[ int rand @videos ];
printf "\n2. The download URI of %s is here,\n\n", $video->id;
printf "    %s\n\n", WebService::YouTube::Util->get_video_uri($video);
