#!perl

use strict;
use warnings;
use utf8;
use HTTP::Request::Common;
use Plack::Request;

use Plack::Test;

use Test::More;
use Test::JsonAPI::Autodoc;

# Plack App
my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    if ($req->path eq '/') {
        return [ 200, [ 'Content-Type' => 'application/json' ], ['{ "message" : "Hello" }'] ];
    }
    elsif ($req->path eq '/foo') {
        return [ 200, [ 'Content-Type' => 'application/json' ], ['{ "message" : "Goodbye" }'] ];
    }
    return [ 404, [ 'Content-Type' => 'text/plain' ], [ "Not found" ] ];
};

# Not use `test_psgi`
my $test_app = Plack::Test->create($app);
describe 'POST /' => sub {
    my $req = POST '/';
    $req->header('Content-Type' => 'application/json');
    $req->content(q{
        {
        "id": 1,
        "message": "blah blah"
        }
    });
    plack_ok($test_app, $req, 200, "get message ok");
};

# Use `test_psgi`
test_psgi $app, sub {
    my $cb = shift;

    describe 'POST /foo' => sub {
        my $req = POST '/foo';
        $req->header('Content-Type' => 'application/json');
        $req->content(q{
            {
                "id": 1,
                "message": "blah blah"
            }
        });
        plack_ok($cb, $req, 200, "get message ok");
    };
};

done_testing;
