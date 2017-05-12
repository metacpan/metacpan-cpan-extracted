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

use Devel::Peek;
use Scalar::Util qw/weaken/;
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

$environment->run_test('no ref cycle exists', sub {
    my $client = WebService::Zaqar->new(base_url => 'http://localhost',
                                        spore_description_file => 'share/marconi.spore.json',
                                        client_uuid => 'tomato');

    # Versions prior to 0.010 had a ref cycle on Zaqar clients,
    # because of a closure.

    my $copy = $client;
    weaken $copy;

    ok($copy, q{... and the weak ref still points to something});

    undef $client;
    ok(!$copy, q{... no cyclic reference ever created});
                       });

$environment->run_test('cycle exists, but fixed', sub {
    my $client = WebService::Zaqar->new(base_url => 'http://localhost',
                                     spore_description_file => 'share/marconi.spore.json',
                                     client_uuid => 'tomato');

    # the SPORE backend's middlewares use closures to the client,
    # hence the cyclic ref
    $client->spore_client;

    my $copy = $client;
    weaken $copy;

    undef $client;
    ok(!$copy, q{... cyclic reference created and fixed});
                       });

done_testing;
