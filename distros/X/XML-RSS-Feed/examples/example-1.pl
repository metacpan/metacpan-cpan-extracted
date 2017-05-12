#!/usr/bin/perl
use strict;
use warnings;
use XML::RSS::Feed;
use LWP::Simple qw(get);

my $feed = XML::RSS::Feed->new(
    url    => "http://use.perl.org/index.rss",
    name   => "useperl",
    delay  => 10,
    debug  => 1,
    tmpdir => "/tmp",
);

while (1) {
    $feed->parse( get( $feed->url ) );
    print $_->headline . "\n" for $feed->late_breaking_news;
    sleep( $feed->delay );
}
