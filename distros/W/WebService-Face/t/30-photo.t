#!/usr/bin/perl 

use strict; 
use warnings; 

use Test::More; 
use WebService::Face::Client; 
use JSON;

unless ( $ENV{FACE_API_KEY} && $ENV{FACE_API_SECRET}) {
    warn("\n\nSet FACE_API_KEY, FACE_API_SECRET for testing\n\n");
    plan skip_all => ' Set environment vars for API access';
}

plan tests => 7;

my $client;
eval { $client = WebService::Face::Client->new({}) };
ok( !$@, "new()" );

my @tags = $client->faces_detect(
        { urls => "http://face.com/img/faces-of-the-festival-no-countries.jpg" }
   );

my @photos = $client->response->photos();
my $photo = shift @photos;

isa_ok( $photo, 'WebService::Face::Response::Photo' );
can_ok( $photo, 'width' );
can_ok( $photo, 'height' );
can_ok( $photo, 'url' );
can_ok( $photo, 'pid' );
can_ok( $photo, 'tags' );
