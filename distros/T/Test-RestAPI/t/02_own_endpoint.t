use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;
use Mojo::UserAgent;

use_ok('Test::RestAPI'); 

my $api = Test::RestAPI->new(
    endpoints => [
        Test::RestAPI::Endpoint->new(
            path => '/error',
            method => 'get',
            render => {status => 444, text => 'Something not found'}
        ),
    ]
);

lives_ok {
    $api->start();
    } 'start';

my $uri = $api->uri;

my $ua = Mojo::UserAgent->new();
is($ua->get($uri.'/error')->res->code(), 444, 'call /error endpoint');

is($api->count_of_requests('/error'), 1, 'first request');

is($ua->get($uri.'/error')->res->code(), 444, 'call /error endpoint again');

is($api->count_of_requests('/error'), 2, 'second request');
