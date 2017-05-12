#!/usr/bin/env perl
#
# $Id: WebService-YouTube-User.t 11 2007-04-09 04:34:01Z hironori.yoshida $
#
use strict;
use warnings;
use version; our $VERSION = qv('1.0.3');

use blib;
use Test::Base tests => 4;

use WebService::YouTube::User;

can_ok( 'WebService::YouTube::User', qw(new) );

my $user = WebService::YouTube::User->new;
isa_ok( $user, 'WebService::YouTube::User' );

# derived from youtube.users.get_profile
can_ok(
    $user, qw(
      first_name
      last_name
      about_me
      age
      video_upload_count
      video_watch_count
      homepage
      hometown
      gender
      occupations
      companies
      city
      country
      books
      hobbies
      movies
      relationship
      friend_count
      favorite_video_count
      currently_on
      )
);

# derived from youtube.users.list_friends
can_ok(
    $user,
    qw(
      user
      video_upload_count
      favorite_count
      friend_count
      )
);
