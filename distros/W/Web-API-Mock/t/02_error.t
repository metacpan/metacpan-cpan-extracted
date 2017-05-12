use strict;
use Test::More;
use Test::Deep;

use_ok $_ for qw(
    Web::API::Mock::Parser
);

my $parser = Web::API::Mock::Parser->new();
my $map;

subtest parse_md => sub {
    isa_ok $parser, 'Web::API::Mock::Parser';
    $parser->md(<<'...');
# TEST API

HOGE FUGA

## XXXXXXXXX

HOGE FUGA

## GET /api/404

+ Request

+ Response 404 (text/html)

    + Body

            404 Not Found

## POST /api/create

+ Response 400 (application/json)

    + Headers

            X-Framework: Ark
    + Body

            {
                "status" : 400,
                "result": {
                    "message": "Bad Request",
                    "ng": 1,
                }
            }

...

    $map = $parser->create_map();
    isa_ok $map, 'Web::API::Mock::Map';
};

subtest invalid_request => sub {
    my $response = $map->request('GET', '/api/404');
    is $response->{status}, 404;
    is $response->{content_type}, 'text/html';

    $response = $map->request('POST', '/api/create');
    is $response->{status}, 400;
    is $response->{content_type}, 'application/json';
    note explain $response;

};

done_testing;
