#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use WWW::VastAI::HTTPRequest;
use WWW::VastAI::HTTPResponse;
use WWW::VastAI::LWPIO;

{
    package Test::WWW::VastAI::FakeUA;

    sub new { bless {}, shift }

    sub request {
        my ($self, $request) = @_;
        $self->{request} = $request;
        return bless {
            code    => 201,
            content => '{"ok":true}',
        }, 'Test::WWW::VastAI::FakeHTTPResponse';
    }

    sub request_seen { shift->{request} }
}

{
    package Test::WWW::VastAI::FakeHTTPResponse;

    sub code { shift->{code} }

    sub decoded_content { shift->{content} }
}

subtest 'request and response wrappers expose payload state' => sub {
    my $request = WWW::VastAI::HTTPRequest->new(
        method  => 'POST',
        url     => 'https://example.invalid/instances',
        headers => {
            Authorization => 'Bearer token',
            'Content-Type' => 'application/json',
        },
        content => '{"name":"demo"}',
    );

    is($request->method, 'POST', 'request method');
    is($request->url, 'https://example.invalid/instances', 'request url');
    is($request->headers->{Authorization}, 'Bearer token', 'request header');
    ok($request->has_content, 'request reports content');

    my $empty = WWW::VastAI::HTTPRequest->new(
        method => 'GET',
        url    => 'https://example.invalid/instances',
    );
    ok(!$empty->has_content, 'empty request has no content');

    my $response = WWW::VastAI::HTTPResponse->new(
        status  => 202,
        content => '{"accepted":true}',
    );

    is($response->status, 202, 'response status');
    is($response->content, '{"accepted":true}', 'response content');
};

subtest 'lwpio converts internal request objects to lwp requests' => sub {
    my $ua = Test::WWW::VastAI::FakeUA->new;
    my $io = WWW::VastAI::LWPIO->new(user_agent => $ua);

    my $response = $io->call(
        WWW::VastAI::HTTPRequest->new(
            method  => 'POST',
            url     => 'https://example.invalid/instances',
            headers => {
                Authorization => 'Bearer token',
                'Content-Type' => 'application/json',
            },
            content => '{"name":"demo"}',
        )
    );

    isa_ok($response, 'WWW::VastAI::HTTPResponse');
    is($response->status, 201, 'lwpio forwards response status');
    is($response->content, '{"ok":true}', 'lwpio forwards decoded content');

    my $sent = $ua->request_seen;
    isa_ok($sent, 'HTTP::Request');
    is($sent->method, 'POST', 'lwp request method');
    is($sent->uri->as_string, 'https://example.invalid/instances', 'lwp request uri');
    is($sent->header('Authorization'), 'Bearer token', 'lwp request header');
    is($sent->content, '{"name":"demo"}', 'lwp request content');
};

done_testing;
