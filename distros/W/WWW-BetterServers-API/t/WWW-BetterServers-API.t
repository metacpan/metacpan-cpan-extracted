#-*- mode: cperl -*-#
use strict;
use warnings;
use utf8;

use Test::More tests => 10;
BEGIN { use_ok('WWW::BetterServers::API') };

#########################

my %cred = (
    api_id     => $ENV{API_ID},
    api_secret => $ENV{API_SECRET},
    auth_type  => $ENV{AUTH_TYPE},
    api_host   => $ENV{API_HOST} || 'api.betterservers.com',
    ($ENV{API_PORT} ? (api_port => $ENV{API_PORT}) : ())
);

my $api_id = $cred{api_id};

SKIP: {
    skip("API_ID, API_SECRET, AUTH_TYPE environment vars not set", 9)
      unless $cred{api_id} and $cred{api_secret} and $cred{auth_type};

    my $api = new WWW::BetterServers::API(%cred);

    ## run (non-blocking) requests in parallel
    my $delay = Mojo::IOLoop->delay;

    {
        my $end = $delay->begin(0);
        $api->request(method   => "GET",
                      uri      => "/v1/accounts/$api_id/diskofferings",
                      callback => sub { my ($ua, $tx) = @_;
                                        is( $tx->res->code, 200, "200 status good" ) or diag $tx->res->body;
                                        like( $tx->res->body, qr("storagetype"), "storagetype found" );
                                        $end->() });
    }

    {
        my $end = $delay->begin(0);
        $api->request(method   => "GET",
                      uri      => "/v1/accounts/$api_id",
                      callback => sub { my ($ua, $tx) = @_;
                                        is( $tx->res->code, 200, "200 status good" );
                                        ok( $tx->res->json('/api_id'), "api id found" );
                                        $end->() });
    }

    {
        my $end = $delay->begin(0);
        $api->request(method   => "POST",
                      uri      => "/response_code?code=201",
                      body     => '{"Mått":"Smîth"}',
                      callback => sub { my ($ua, $tx) = @_;
                                        is( $tx->res->code, 201, "201 status good" );
                                        ok( $tx->res->json('/code'), "code found" );
                                        $end->() });
    }

    {
        my $end = $delay->begin(0);
        $api->request(method   => "PUT",
                      uri      => "/response_code?code=202",
                      payload  => { "Dåvî∂" => 'Ténnånt' },
                      callback => sub { my ($ua, $tx) = @_;
                                        is( $tx->res->code, 202, "202 status good" );
                                        ok( $tx->res->json('/code'), "code found" );
                                        $end->() });
    }

    $delay->wait;

    ## blocking request
    my $res = $api->request(method  => "POST",
                            uri     => "/v1/accounts/$api_id/auth_token",
                            payload => { duration => 30 });

    ok( $res->json('/token'), "good token" );
}
