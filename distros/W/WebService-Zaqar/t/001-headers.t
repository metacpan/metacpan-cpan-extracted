#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

# for the DumpToScalar middleware
use lib 't/lib';

use Test::More;
use Test::SetupTeardown;

use HTTP::Date;
use WebService::Zaqar;

my $requests;
my $mock_server = {
    '/v1/health' => sub {
        my $req = shift;
        $req->new_response(204, [], '');
    },
    '/v1/queues/chirimoya/claims' => sub {
        my $req = shift;
        $req->new_response(200, [], '{"ok": "ok"}');
    },
};

my $environment = Test::SetupTeardown->new(setup => sub { @{$requests} = () });

$environment->run_test('query with no payload', sub {

    my $client = WebService::Zaqar->new(base_url => 'http://localhost',
                                        spore_description_file => 'share/marconi.spore.json',
                                        client_uuid => 'tomato');
    $client->spore_client->enable('DumpToScalar',
                                  dump_log => $requests);
    $client->spore_client->enable('Mock',
                                  tests => $mock_server);

    $client->check_node_health;

    my $request = shift @{$requests};

    is($request->header('Content-Type'), undef,
         q{... and the Content-Type header for a request no payload is not provided});
    like($request->header('Accept'), qr{^application/json},
         q{... and the Accept header for a request with payload is application/json});
    is($request->header('Client-ID'), 'tomato',
       q{... and the Client-ID header uses the client UUID provided});
    isnt(HTTP::Date::str2time($request->header('Date')), undef,
         q{... and the Date header contains a valid RFC1123 date});
    is($request->header('X-Auth-Token'), undef,
       q{... and the auth token is not used if not provided});

                       });

$environment->run_test('query with payload', sub {

    my $client = WebService::Zaqar->new(base_url => 'http://localhost',
                                        spore_description_file => 'share/marconi.spore.json',
                                        client_uuid => 'tomato');
    $client->spore_client->enable('DumpToScalar',
                                  dump_log => $requests);
    $client->spore_client->enable('Mock',
                                  tests => $mock_server);

    $client->claim_messages(queue_name => 'chirimoya',
                            limit => 5,
                            payload => { ttl => 60,
                                         grace => 60 } );

    my $request = shift @{$requests};

    like($request->header('Content-Type'), qr{^application/json},
         q{... and the Content-Type header for a request with payload is application/json});
    like($request->header('Accept'), qr{^application/json},
         q{... and the Accept header for a request with payload is application/json});
    is($request->header('Client-ID'), 'tomato',
       q{... and the Client-ID header uses the client UUID provided});
    isnt(HTTP::Date::str2time($request->header('Date')), undef,
         q{... and the Date header contains a valid RFC1123 date});
    is($request->header('X-Auth-Token'), undef,
       q{... and the auth token is not used if not provided});

                       });

$environment->run_test('query with payload and token', sub {

    my $client = WebService::Zaqar->new(base_url => 'http://localhost',
                                        spore_description_file => 'share/marconi.spore.json',
                                        client_uuid => 'tomato',
                                        token => 'potato');
    $client->spore_client->enable('DumpToScalar',
                                  dump_log => $requests);
    $client->spore_client->enable('Mock',
                                  tests => $mock_server);

    $client->claim_messages(queue_name => 'chirimoya',
                            limit => 5,
                            payload => { ttl => 60,
                                         grace => 60 } );

    my $request = shift @{$requests};

    like($request->header('Content-Type'), qr{^application/json},
         q{... and the Content-Type header for a request with payload is application/json});
    like($request->header('Accept'), qr{^application/json},
         q{... and the Accept header for a request with payload is application/json});
    is($request->header('Client-ID'), 'tomato',
       q{... and the Client-ID header uses the client UUID provided});
    isnt(HTTP::Date::str2time($request->header('Date')), undef,
         q{... and the Date header contains a valid RFC1123 date});
    is($request->header('X-Auth-Token'), 'potato',
       q{... and the auth token is used if provided});

                       });

done_testing;
