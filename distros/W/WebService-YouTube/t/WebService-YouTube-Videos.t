#!/usr/bin/env perl
#
# $Id: WebService-YouTube-Videos.t 11 2007-04-09 04:34:01Z hironori.yoshida $
#
use strict;
use warnings;
use version; our $VERSION = qv('1.0.3');

use blib;
use Test::Base tests => 7;

use WebService::YouTube::Videos;

can_ok( 'WebService::YouTube::Videos', qw(new dev_id) );
can_ok(
    'WebService::YouTube::Videos',
    qw(
      get_details
      list_by_tag
      list_by_user
      list_featured
      )
);

SKIP: {
    if ( !$ENV{TEST_YOUTUBE} ) {
        skip 'set TEST_YOUTUBE for testing WebService::YouTube::Videos', 5;
    }
    my $api =
      WebService::YouTube::Videos->new( { dev_id => $ENV{TEST_YOUTUBE} } );
    my @videos = $api->list_featured;
    cmp_ok( @videos, q{==}, 100, 'youtube.videos.list_featured' );

    @videos = $api->list_by_user('youtuberocks');
    cmp_ok( @videos, q{==}, 0, 'youtube.videos.list_by_user' );

    @videos = $api->list_by_tag('feature film documentary');
    cmp_ok( @videos, q{>}, 0, 'youtube.videos.list_by_tag' );

    @videos = $api->list_by_tag('javascript json api jsonscriptrequest');
    cmp_ok( @videos, q{==}, 1, 'video_list has only one video' );

    my $video = $api->get_details( $videos[0] );
    ok( $video, 'youtube.videos.get_details' );
}
