#!/usr/bin/env perl
#
# $Id: WebService-YouTube-Feeds.t 11 2007-04-09 04:34:01Z hironori.yoshida $
#
use strict;
use warnings;
use version; our $VERSION = qv('1.0.3');

use blib;
use Test::Base tests => 16;

use WebService::YouTube::Feeds;

can_ok( 'WebService::YouTube::Feeds', qw(new ua) );
my $feeds = WebService::YouTube::Feeds->new;

can_ok( $feeds, qw(tag user) );

my @global_rss = qw(
  recently_added
  recently_featured
  top_favorites
  top_rated
  most_discussed_month
  most_discussed_today
  most_discussed_week
  top_viewed
  top_viewed_month
  top_viewed_today
  top_viewed_week
);

can_ok( $feeds, @global_rss );

SKIP: {
    if ( !$ENV{TEST_YOUTUBE} ) {
        skip 'set TEST_YOUTUBE for testing WebService::YouTube::Feeds',
          @global_rss + 2;
    }
    ok( $feeds->tag('monkey'),   'tag' );
    ok( $feeds->user('YouTube'), 'user' );
    foreach my $rss (@global_rss) {
        cmp_ok( $feeds->$rss, q{==}, 15, $rss );
    }
}
