#!/usr/bin/env perl
#
# $Id: WebService-YouTube-Video.t 11 2007-04-09 04:34:01Z hironori.yoshida $
#
use strict;
use warnings;
use version; our $VERSION = qv('1.0.3');

use blib;
use Test::Base tests => 6;

use WebService::YouTube::Video;

can_ok( 'WebService::YouTube::Video', qw(new) );

my $video = WebService::YouTube::Video->new;
isa_ok( $video, 'WebService::YouTube::Video' );

# derived from youtube.videos.get_details
can_ok(
    $video, qw(
      author
      title
      rating_avg
      rating_count
      tags
      description
      update_time
      view_count
      upload_time
      length_seconds
      recording_date
      recording_location
      recording_country
      comment_list
      channel_list
      thumbnail_url
      )
);

# derived from youtube.videos.list_by_tag
can_ok(
    $video, qw(
      author
      id
      title
      length_seconds
      rating_avg
      rating_count
      description
      view_count
      upload_time
      comment_count
      tags
      url
      thumbnail_url
      )
);

# derived from youtube.videos.list_by_user
can_ok(
    $video, qw(
      author
      id
      title
      length_seconds
      rating_avg
      rating_count
      description
      view_count
      upload_time
      comment_count
      tags
      url
      thumbnail_url
      )
);

# derived from youtube.videos.list_featured
can_ok(
    $video, qw(
      author
      id
      title
      length_seconds
      rating_avg
      rating_count
      description
      view_count
      upload_time
      comment_count
      tags
      url
      thumbnail_url
      )
);
