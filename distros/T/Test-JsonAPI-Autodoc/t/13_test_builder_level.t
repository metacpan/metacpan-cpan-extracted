#!perl

use strict;
use warnings;
use utf8;
use HTTP::Request::Common;
use HTTP::Response;
use Test::Mock::LWP::Conditional;

use Test::More;
use Test::JsonAPI::Autodoc;

my $ok_res = HTTP::Response->new(200);
$ok_res->content('{ "message" : "success" }');
$ok_res->content_type('application/json');

Test::Mock::LWP::Conditional->stub_request(
    "http://localhost:3000/foobar" => $ok_res,
);

my $level = $Test::Builder::Level;

describe 'POST /foobar' => sub {
    my $nest_level = $Test::Builder::Level;

    no warnings qw(redefine);
    local *Test::More::is = sub {
        is $Test::Builder::Level, $nest_level + 2, 'changed';
    };

    my $req = POST 'http://localhost:3000/foobar';
    $req->header('Content-Type' => 'application/json');
    $req->content(q{
        {
            "id": 1,
            "message": null
        }
    });
    http_ok($req, 200);

    is $Test::Builder::Level + 1, $level + 1, 'changed';
    is $nest_level, $Test::Builder::Level, 'restored';
};

is $Test::Builder::Level, $level, 'restored';

done_testing;
