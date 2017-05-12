use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json);

use_ok('Test::RestAPI'); 

my $api = Test::RestAPI->new(
    endpoints => [
        Test::RestAPI::Endpoint->new(
            path   => '/',
            method => 'any',
            render => { json => { result => [ 'a', 'b' ] } },
        ),
    ]
);

lives_ok {
    $api->start();
    } 'start';

my $uri = $api->uri;

my $ua = Mojo::UserAgent->new();
is_deeply(decode_json($ua->get($uri)->res->body()), {result => ['a', 'b']}, 'json result');
