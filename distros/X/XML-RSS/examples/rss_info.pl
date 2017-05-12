#!/usr/bin/perl

# channel_info.pl
# print channel info

use lib '.';

use strict;
use warnings;

use XML::RSS;

my $rss = XML::RSS->new;
$rss->parsefile(shift);

print "XML encoding: ".$rss->encoding."\n";
print "RSS Version: ".$rss->version."\n";
print "Title: ".$rss->channel('title')."\n";
print "Language: ".$rss->channel('language')."\n";
print "Rating: ".$rss->channel('rating')."\n";
print "Copyright: ".$rss->channel('copyright')."\n";
print "Publish Date: ".$rss->channel('pubDate')."\n";
print "Last Build Date: ".$rss->channel('lastBuildDate')."\n";
print "CDF URL: ".$rss->channel('docs')."\n";
print "Items: ".scalar(@{$rss->items})."\n";


