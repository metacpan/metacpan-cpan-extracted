#!/usr/bin/env perl

use strict;
use warnings;
use version; our $VERSION = qv('0.03');

use Test::Base tests => 2;

use WebService::Ustream::API::User;

can_ok( 'WebService::Ustream::API::User', qw(new key ua) );
can_ok(
    'WebService::Ustream::API::User',
    qw(
	info
	list_channels
	list_videos
	comments
       )
);

