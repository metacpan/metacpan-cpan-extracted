#!perl

use strict;
use warnings;
use utf8;
use HTTP::Request::Common;
use HTTP::Response;
use JSON;

use Test::Mock::LWP::Conditional;
use Test::More;
use Test::JsonAPI::Autodoc;

# Stabbing a server
my $ok_res = HTTP::Response->new(200);
$ok_res->content('{ "message" : "success" }');
$ok_res->content_type('application/json');
Test::Mock::LWP::Conditional->stub_request(
    "http://localhost:5000/foo" => $ok_res,
);

subtest '200 OK' => sub {
    describe 'POST /foo' => sub {
        my $req = POST 'http://localhost:5000/foo';

        my $json = to_json({
            id      => 1,
            message => 'blah blah',
        });

        $req->header('Content-Type' => 'application/json');
        $req->content($json);
        http_ok($req, 200, {
            description       => 'get message ok',
            param_description => {
                id      => 'Some ID',
                message => 'Awesome message!',
            },
        });
    };
};

done_testing;
