#!/usr/bin/perl

# A simple example, using WebSerice::Bluga::Webthumb to get a thumbnail of a
# site and return the URL for the thumbnail image
#
# Usage: getthumb.pl $url

use WebService::Bluga::Webthumb;
my $wt = WebService::Bluga::Webthumb->new(
    user    => '...put your user id here...',
    api_key => '...put your api_key here...',
    size    => $size,  # small, medium, medium2, large (default: medium)
    cache   => $cache_days, # optional - default 14
);

# get a thumbnail URL using the default settings
my $thumb_url = wt->thumb_url($url);

print "Thumbnail URL: $thumb_url\n";

