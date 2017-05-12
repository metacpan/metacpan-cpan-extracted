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

plan tests => 13;

my $client;
eval { $client = WebService::Face::Client->new() };
ok( !$@, "new()" );

isa_ok( $client, 'WebService::Face::Client' );

########################################################################
#                   Client API
########################################################################

can_ok( $client, "faces_recognize" );
can_ok( $client, "faces_train" );
can_ok( $client, "faces_status" );

can_ok( $client, "tags_get" );
can_ok( $client, "tags_add" );
can_ok( $client, "tags_save" );
can_ok( $client, "tags_remove" );

can_ok( $client, "account_limits" );
can_ok( $client, "account_users" );

########################################################################
#                   helper functions
########################################################################


my $client_h = WebService::Face::Client->new({api_key => 'key', api_secret => 'secret'}); 
is($client_h->_get_credential_parameters(),'&api_key=key&api_secret=secret');
$client_h = WebService::Face::Client->new(); 
is($client_h->_get_credential_parameters(),'&api_key='.$ENV{FACE_API_KEY}.'&api_secret='.$ENV{FACE_API_SECRET});
