#!/usr/bin/env perl
#
# $Id: WebService-YouTube-Util.t 11 2007-04-09 04:34:01Z hironori.yoshida $
#
use strict;
use warnings;
use version; our $VERSION = qv('1.0.3');

use blib;
use Test::Base tests => 5;

use WebService::YouTube::Util;

can_ok(
    'WebService::YouTube::Util', qw(
      rss_uri
      rest_uri
      get_video_uri
      get_video
      )
);
is(
    WebService::YouTube::Util->rss_uri( 'global', 'arg' ),
    'http://www.youtube.com/rss/global/arg.rss',
    'rss_uri'
);
is(
    WebService::YouTube::Util->rest_uri(
        'dev_id', 'method', { key => 'value' }
    ),
    'http://www.youtube.com/api2_rest?dev_id=dev_id&method=method&key=value',
    'rest_uri'
);

SKIP: {
    if ( !$ENV{TEST_YOUTUBE} ) {
        skip 'set TEST_YOUTUBE for testing WebService::YouTube::Util', 1;
    }
    ok( WebService::YouTube::Util->get_video_uri('rdwz7QiG0lk'),
        'Got URI of the video' );
}

SKIP: {
    skip 'It takes a long time', 1;
    ok( WebService::YouTube::Util->get_video('rdwz7QiG0lk'), 'Got the video' );
}
