use strict;
use warnings FATAL => 'all';

use WWW::GitHub::PostReceiveHook;

use Test::More;
use Test::Warn;
use Plack::Test;
use HTTP::Request::Common qw/POST GET/;
use JSON;
use Encode;

# create the server
my $app = WWW::GitHub::PostReceiveHook->new(
    routes => {
        '/hello' => sub {
            my ($payload) = @_;

            is_deeply $payload, ['FOO'], 'payload deserialized correctly';
        },
        '/multibyte' => sub {
            my ($payload) = @_;

            is_deeply $payload, [ decode_utf8 '忍者' ],
                'encode multibyte and payload deserialized correctly';
        },
        '/goodbye' => sub { print 'goodbye' },
    }
)->to_psgi_app;

test_psgi app => $app, client => sub {
    my $client_cb = shift;

    my $request = HTTP::Request->new( GET => '/' );
    my $response = $client_cb->($request);
    is   $response->code,    404, '404 on root';

    $response = $client_cb->(POST '/' => [ bar => 'BAR' ]);
    is $response->code, 404, '404 with empty body';

    $response = $client_cb->(POST '/' => [ bar => 'BAR' ]);
    is $response->code, 404, '404 with no payload param';

    $response = $client_cb->(POST '/hello' => [ bar => 'BAR' ]);
    is $response->code, 404, '404 with no payload param to app path';

    warning_like
        { $response = $client_cb->(POST '/hello', { 'payload' => 'FOO'} ); }
        qr{Caught exception: /hello},
        'malformed JSON string picked up and warned';

    is $response->code, 400, '400 with payload param with unparsing json';
    is $response->content, 'Bad Request', 'Bad Request returned';

    $response = $client_cb->(POST '/hello', { 'payload' => '["FOO"]'} );
    is $response->code, 200, '200 with payload param';
    is $response->content, 'OK', 'OK returned on valid json';

    $response = $client_cb->(POST '/multibyte', { 'payload' => '["忍者"]'} );
    is $response->code, 200, '200 with payload param';
    is $response->content, 'OK', 'OK returned on valid json';
};

done_testing();
