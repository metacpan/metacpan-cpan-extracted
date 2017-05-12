#!perl

use strict;
use warnings;
use utf8;
use HTTP::Request::Common;
use JSON qw/to_json/;

use Plack::Test;

use Test::More;
use Test::JsonAPI::Autodoc;

# PSGI application
my $app = sub {
    my $json = to_json({
        jsonrpc => '2.0',
        result  => {
            entries => [{
                title => 'example',
                body  => 'Hello!',
            }],
        },
        id => 1,
    });
    return [ 200, [ 'Content-Type' => 'application/json' ], [$json] ];
};

my $test_app = Plack::Test->create($app);

describe 'POST /' => sub {
    my $json = to_json({
        jsonrpc => '2.0',
        method  => 'get_entries',
        params  => { limit => 1, category => 'technology' },
    });
    my $req = POST '/';
    $req->header('Content-Type' => 'application/json');
    $req->header('Content-Length' => length $json);
    $req->content($json);
    plack_ok($test_app, $req, 200, "get message ok");
};

done_testing;
