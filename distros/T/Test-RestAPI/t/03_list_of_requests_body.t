use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;
use Mojo::UserAgent;

use_ok('Test::RestAPI'); 

my $api = Test::RestAPI->new(
    endpoints => [
        Test::RestAPI::Endpoint->new(
            path => '/',
            method => 'any',
            render => {text => 'OK'}
        ),
    ]
);

lives_ok {
    $api->start();
    } 'start';

my $uri = $api->uri;

my $ua = Mojo::UserAgent->new();
is($ua->get($uri)->res->body(), 'OK', 'empty request');

is($ua->post($uri, 'content')->res->body(), 'OK', 'request with body');

is_deeply($api->list_of_requests_body(), ['', 'content'], 'list_of_requests_body');
