#!/usr/bin/env perl

use Modern::Perl '2015';

use WG::API;

use Test::More;

my $auth = WG::API->new( application_id => $ENV{'WG_KEY'} || 'demo' )->auth();
isa_ok( $auth, "WG::API::Auth" );

ok( $auth->login( nofollow => 1, redirect_uri => 'http://localhost/response' )
        || $auth->error->message eq 'REQUEST_LIMIT_EXCEEDED',
    'Get redirect uri'
);
is( $auth->prolongate( access_token => 'xxx' ), undef, 'Prolongate with invalid access token' );
like( $auth->error->message, qr/INVALID_ACCESS_TOKEN|REQUEST_LIMIT_EXCEEDED/, 'Vaidate error message' );

ok( $auth->logout( access_token => 'xxx' ) || ( $auth->error->message eq 'REQUEST_LIMIT_EXCEEDED' ),
    'Logout with invalid access token' );

done_testing();

