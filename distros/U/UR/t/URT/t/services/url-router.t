#!/usr/bin/env perl

use Test::More;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../../lib";
use lib File::Basename::dirname(__FILE__)."/../../..";
use UR;
use strict;
use warnings;

use Plack::HTTPParser;
use Plack::Util;
use HTTP::Request;

plan tests => 18;

my $router = UR::Service::UrlRouter->create();
ok($router, 'Created a UrlRouter');

# Basic string routes
foreach my $method ( qw(GET POST PUT DELETE) ) {
    $router->$method('/thing', sub { return "$method Some Content" });
}
$router->GET('/stuff', sub { return [ 200, [ Header => 'Value'], [ 'Stuff Content' ]] });

my $fourohfour = [ 404, [ 'Content-Type' => 'text/plain' ], [ 'Not Found' ] ];

my $resp = $router->( make_psgi_env('GET', '/nomatch') );
is_deeply($resp,
    $fourohfour,
    'GET non-matching path returns 404');
    
$resp = $router->( make_psgi_env('GET', '/thing') );
is_deeply($resp,
    [ 200, [], ['GET Some Content'] ],
    'Run route for GET /thing');

$resp = $router->( make_psgi_env('POST', '/thing') );
is_deeply($resp,
    [ 200, [], ['POST Some Content'] ],
    'Run route for POST /thing');

$resp = $router->( make_psgi_env('PUT', '/thing') );
is_deeply($resp,
    [ 200, [], ['PUT Some Content'] ],
    'Run route for PUT /thing');

$resp = $router->( make_psgi_env('DELETE', '/thing') );
is_deeply($resp,
    [ 200, [], ['DELETE Some Content'] ],
    'Run route for DELETE /thing');

$resp = $router->( make_psgi_env('GET', '/stuff') );
is_deeply($resp,
    [ 200, [ Header => 'Value'], ['Stuff Content']],
    'Run route that returns PSGI struct');


# A subref route that fires if the first char is a T
$router = UR::Service::UrlRouter->create();
ok($router, 'Created UrlRouter');
$router->GET(sub { return substr(shift->{PATH_INFO}, 0, 1) eq 'T' },
            sub { return "Started with T" });

$resp = $router->( make_psgi_env('GET', 'Tfoo') );
is_deeply($resp,
    [ 200, [], [ 'Started with T' ] ],
    'Match route with subref');

$resp = $router->( make_psgi_env('PUT', 'Tfoo') );
is_deeply($resp, $fourohfour, 'Did not match subref route with different method');

$resp = $router->( make_psgi_env('GET', 'tfoo') );
is_deeply($resp, $fourohfour, 'Did not match subref route with non-matching string');


# A regex route
$router = UR::Service::UrlRouter->create();
ok($router, 'Created UrlRouter');
my @matches;
$router->GET(qr{^\/(\w+)\/(\w+)},
            sub {
                my $env = shift;
                @matches = @_;
                return 1;
            });

$resp = $router->( make_psgi_env('GET', '/one/two'));
is_deeply($resp,
        [200, [], [1]],
        'Run route matching regex');
is_deeply(\@matches, ['one','two'], 'Callback saw the matches');

$resp = $router->( make_psgi_env('GET', '/one/two/three/four') );
is_deeply($resp,
        [200, [], [1]],
        'Run route matching regex');
is_deeply(\@matches, ['one','two'], 'Callback saw the matches');

$resp = $router->( make_psgi_env('GET', 'one/two') );
is_deeply($resp, $fourohfour, 'Did not match regex with non-matching path');

$resp = $router->( make_psgi_env('PUT', '/one/two'));
is_deeply($resp, $fourohfour, 'Did not match regex with different method');




sub make_psgi_env {
    my $method = shift;
    my $path = shift;

    my $req = HTTP::Request->new($method, $path);
    $req->protocol('HTTP/1.1');
    
    # copied from HTTP::Server::PSGI::accept_loop()
    my $env = {
                SERVER_PORT => 80,
                SERVER_NAME => 'localhost',
                SCRIPT_NAME => '',
                REMOTE_ADDR => 'localhost',
                REMOTE_PORT => $$,
                'psgi.version' => [ 1, 1 ],
                'psgi.errors'  => *STDERR,
                'psgi.url_scheme' => 'http',
                'psgi.run_once'     => Plack::Util::FALSE,
                'psgi.multithread'  => Plack::Util::FALSE,
                'psgi.multiprocess' => Plack::Util::FALSE,
                'psgi.streaming'    => Plack::Util::TRUE,
                'psgi.nonblocking'  => Plack::Util::FALSE,
                'psgix.input.buffered' => Plack::Util::TRUE,
            };
    Plack::HTTPParser::parse_http_request($req->as_string, $env);
    return $env;
}
