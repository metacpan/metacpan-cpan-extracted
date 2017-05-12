#!/usr/bin/env perl
#
# $Id: WebService-YouTube.t 11 2007-04-09 04:34:01Z hironori.yoshida $
#
use strict;
use warnings;
use version; our $VERSION = qv('1.0.3');

use blib;
use Test::Base tests => 6;

use WebService::YouTube;

can_ok( 'WebService::YouTube', qw(new dev_id ua) );
can_ok( 'WebService::YouTube', qw(videos feeds) );

my $youtube = WebService::YouTube->new;
isa_ok( $youtube->feeds, 'WebService::YouTube::Feeds' );

SKIP: {
    if ( !$ENV{TEST_YOUTUBE} ) {
        skip 'set TEST_YOUTUBE for testing WebService::YouTube', 1;
    }
    $youtube->dev_id( $ENV{TEST_YOUTUBE} );
    isa_ok( $youtube->videos, 'WebService::YouTube::Videos' );
}

TODO: {
    todo_skip 'These have not been implemented yet', 2;

    # youtube.users.*
    can_ok( $youtube, qw(users) );
    isa_ok( $youtube->users, 'WebService::YouTube::Users' );
}
