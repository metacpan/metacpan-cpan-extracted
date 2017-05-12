#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use IO::Socket::SSL;
use URI;

use_ok( 'Tropo::RestAPI::Session' );

my $token = '1234';

my $session = Tropo::RestAPI::Session->new;
isa_ok $session, 'Tropo::RestAPI::Session';

my $result = $session->create;
ok !$result, 'Cannot create session - token missing';

BAIL_OUT( 'Need support of client-side SNI (openssl >= 1.0.0)' )
    if !IO::Socket::SSL->can_client_sni();

if ( $ENV{http_proxy} ) {
    my @no_proxy = split /\s*,\s*/, $ENV{no_proxy} || '';
    my $uri = URI->new( $session->url );
    BAIL_OUT( 'HTTPS via proxy is not supported' )
        if !grep{ $uri->host eq $_ }@no_proxy;
}

$result = $session->create( token => $token );
ok !$result, 'Cannot create session - invalid token';
is $session->err, 'Tropo session launch failed!';

done_testing();
