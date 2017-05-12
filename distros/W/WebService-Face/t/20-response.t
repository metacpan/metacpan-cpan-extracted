#!/usr/bin/perl 

use strict;
use warnings;

use Test::More;
use WebService::Face::Client;
use JSON;

unless ( $ENV{FACE_API_KEY} && $ENV{FACE_API_SECRET} ) {
    warn("\n\nSet FACE_API_KEY, FACE_API_SECRET for testing\n\n");
    plan skip_all => ' Set environment vars for API access';
}

plan tests => 25;

my $client;
eval { $client = WebService::Face::Client->new() };
ok( !$@, "new()" );

isa_ok( $client, 'WebService::Face::Client' );

my @tags = $client->faces_detect(
        { urls => "http://face.com/img/faces-of-the-festival-no-countries.jpg" }
);

########################################################################
#                   Response API
########################################################################

my $response = $client->response;
isa_ok( $response, 'WebService::Face::Response' );
can_ok( $response, "status" );
can_ok( $response, "error_code" );
can_ok( $response, "error_message" );
can_ok( $response, "photos" );
can_ok( $response, "url" );
can_ok( $response, "pid" );
can_ok( $response, "width" );
can_ok( $response, "height" );
can_ok( $response, "tags" );
can_ok( $response, "groups" );
can_ok( $response, "tid" );
can_ok( $response, "recognizable" );
can_ok( $response, "threshold" );
can_ok( $response, "uids" );
can_ok( $response, "confirmed" );
can_ok( $response, "manual" );
can_ok( $response, 'message' );
can_ok( $response, 'saved_tags' );
can_ok( $response, 'limits' );
can_ok( $response, 'users' );
can_ok( $response, 'account' );
ok( !$response->can('nonexistent'), 'No fallback method to jam tests' );
