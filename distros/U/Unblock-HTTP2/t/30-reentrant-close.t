use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until);
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

sub request_for {
    return Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/',
        scheme    => 'https',
        authority => 'example.test',
    );
}

{
    my @server_errors;
    my $server;
    $server = Unblock::HTTP2::Server->new(
        on_request => sub {
            my ($stream, $request) = @_;
            $server->close('server closed from request callback');
        },

        on_error => sub {
            my ($stream, $error) = @_;
            push @server_errors, $error;
        },
    );

    my $client = Unblock::HTTP2::Client->new;
    $client->request(request_for());

    pump_until($client, $server, sub { $server->is_closed });

    ok $server->is_closed,
        'server can request close from inside an nghttp2 receive callback';
    ok @server_errors >= 1,
        'deferred server close fails the active stream after callback unwinds';
    like $server_errors[0], qr/server closed from request callback/,
        'deferred server close preserves its reason';
}

{
    my @client_errors;
    my $client;

    my $server = Unblock::HTTP2::Server->new(
        on_request => sub {
            my ($stream, $request) = @_;
            $stream->respond(
                Uniform::HTTP::Response->new(
                    status => 200,
                    body   => 'response',
                ),
            );
        },
    );

    $client = Unblock::HTTP2::Client->new;
    $client->request(
        request_for(),

        on_response => sub {
            my ($stream, $response) = @_;
            $client->close('client closed from response callback');
        },

        on_error => sub {
            my ($stream, $error) = @_;
            push @client_errors, $error;
        },
    );

    pump_until($client, $server, sub { $client->is_closed });

    ok $client->is_closed,
        'client can request close from inside an nghttp2 receive callback';
    ok @client_errors >= 1,
        'deferred client close fails the active stream after callback unwinds';
    ok defined($client_errors[0]) && length($client_errors[0]),
        'deferred client close leaves the active stream with a terminal reason';
}

done_testing;
