#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# Log::Any::Test must be loaded before any module that uses Log::Any
use Log::Any::Test;
use Log::Any qw($log);

use_ok('WWW::Hetzner::Cloud');

subtest 'uses Log::Any' => sub {
    # Verify the Role imports Log::Any
    my $http_log = Log::Any->get_logger(category => 'WWW::Hetzner::Role::HTTP');
    ok($http_log, 'WWW::Hetzner::Role::HTTP has a Log::Any logger');
};

subtest 'logging with mocked UA' => sub {
    my $cloud = WWW::Hetzner::Cloud->new(token => 'test-token');

    # Clear any previous log messages
    Log::Any->get_logger(category => 'WWW::Hetzner::Role::HTTP')->clear;

    # Mock the UA to return a valid response
    no warnings 'redefine';
    local *LWP::UserAgent::request = sub {
        my ($self, $request) = @_;
        my $response = HTTP::Response->new(200, 'OK');
        $response->content('{"servers":[]}');
        return $response;
    };

    # Make a request
    eval { $cloud->servers->list };

    # Check logs
    my $msgs = Log::Any->get_logger(category => 'WWW::Hetzner::Role::HTTP')->msgs;

    my @debug = grep { $_->{level} eq 'debug' } @$msgs;
    ok(@debug >= 1, 'has debug messages');
    like($debug[0]->{message}, qr{GET.*/servers}, 'debug logs request URL');

    my @info = grep { $_->{level} eq 'info' } @$msgs;
    ok(@info >= 1, 'has info messages');
    like($info[0]->{message}, qr{GET.*/servers.*200}, 'info logs successful request');
};

subtest 'debug logs request body for POST' => sub {
    my $cloud = WWW::Hetzner::Cloud->new(token => 'test-token');

    Log::Any->get_logger(category => 'WWW::Hetzner::Role::HTTP')->clear;

    no warnings 'redefine';
    local *LWP::UserAgent::request = sub {
        my ($self, $request) = @_;
        my $response = HTTP::Response->new(200, 'OK');
        $response->content('{"server":{"id":1,"name":"test","status":"running","public_net":{"ipv4":{"ip":"1.2.3.4"}}}}');
        return $response;
    };

    eval {
        $cloud->servers->create(
            name        => 'test-server',
            server_type => 'cx22',
            image       => 'debian-12',
        );
    };

    my $msgs = Log::Any->get_logger(category => 'WWW::Hetzner::Role::HTTP')->msgs;
    my @debug = grep { $_->{level} eq 'debug' } @$msgs;

    ok(@debug >= 2, 'has multiple debug messages');

    my @body_logs = grep { $_->{message} =~ /Body:/ } @debug;
    ok(@body_logs >= 1, 'logs request body');
    like($body_logs[0]->{message}, qr/test-server/, 'body contains request data');
};

subtest 'error logging on API error' => sub {
    my $cloud = WWW::Hetzner::Cloud->new(token => 'test-token');

    Log::Any->get_logger(category => 'WWW::Hetzner::Role::HTTP')->clear;

    no warnings 'redefine';
    local *LWP::UserAgent::request = sub {
        my ($self, $request) = @_;
        my $response = HTTP::Response->new(401, 'Unauthorized');
        $response->content('{"error":{"message":"Invalid token"}}');
        return $response;
    };

    eval { $cloud->servers->list };

    my $msgs = Log::Any->get_logger(category => 'WWW::Hetzner::Role::HTTP')->msgs;
    my @errors = grep { $_->{level} eq 'error' } @$msgs;

    ok(@errors >= 1, 'has error messages');
    like($errors[0]->{message}, qr/Invalid token/, 'error contains API message');
};

done_testing;
