use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until);
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

my @informational;
my $final;
my @errors;

my $server = Unblock::HTTP2::Server->new(
    on_request => sub {
        my ($transaction, $request) = @_;

        $transaction->send_informational(
            Uniform::HTTP::Response->new(
                status  => 103,
                headers => [
                    [ 'link', '</style.css>; rel=preload' ],
                ],
            ),
        );

        $transaction->send_informational(
            Uniform::HTTP::Response->new(
                status  => 103,
                headers => [
                    [ 'link', '</script.js>; rel=preload' ],
                ],
            ),
        );

        $transaction->respond(
            Uniform::HTTP::Response->new(
                status => 200,
                body   => 'ok',
            ),
        );
    },

    on_error => sub {
        my ($transaction, $error) = @_;
        push @errors, "server: $error";
    },
);

my $client = Unblock::HTTP2::Client->new;

my $transaction = $client->request(
    Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/',
        scheme    => 'https',
        authority => 'example.test',
    ),

    on_informational => sub {
        my ($transaction, $response) = @_;
        push @informational, $response;
    },

    on_response => sub {
        my ($transaction, $response) = @_;
        $final = $response;
    },

    on_error => sub {
        my ($transaction, $error) = @_;
        push @errors, "client: $error";
    },
);

pump_until($client, $server, sub { $transaction->is_terminal });

is scalar(@informational), 2,
    'multiple non-final informational responses are delivered';
is $informational[0]->status, 103,
    'first informational response status is preserved';
is $informational[0]->header('link'),
    '</style.css>; rel=preload',
    'first informational response fields are preserved';
is $informational[1]->status, 103,
    'second informational response status is preserved';
is $informational[1]->header('link'),
    '</script.js>; rel=preload',
    'second informational response fields are preserved';
is defined($final) ? $final->status : undef, 200,
    'final response follows informational responses';
is_deeply \@errors, [],
    'informational response path reports no protocol errors';

done_testing;
