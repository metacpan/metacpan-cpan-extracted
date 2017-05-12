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
## GET /api/hoge

+ Request

    + Headers

            Cookie: sid=71de3e2e5c1e7f15fecef9b25f74087d6bc41b01

    + Parameters
        + id (number) ... ID
        + title (string) ... Title
        + body (string) ... Body
        + gender (string) ... Gender(male|female)

+ Response 200 (text/plain)

    + Headers

            X-Framework: Ark

    + Body

            Hello World

## POST /api/foo

+ Response 200 (text/plain)

    + Headers

            X-Framework: ArkFoo
            X-Served-By: app001

    + Body

            Hello World
            Foo

## GET /api/bar

+ Response 200 (text/plain)

    + Body

            Hello World
            Bar

## GET /api/fizz/{id}

+ Response 200 (text/plain)

    Hello World
    Fizz

...

    $map = $parser->create_map();
    isa_ok $map, 'Web::API::Mock::Map';
};

subtest request => sub {
    my $response = $map->request('GET', '/api/hoge');
    is $response->{header}->{'X-Framework'}, 'Ark';
    is $response->{body}, "Hello World\n";

    $response = $map->request('POST', '/api/foo');
    is $response->{header}->{'X-Framework'}, 'ArkFoo';
    is $response->{header}->{'X-Served-By'}, 'app001';
    is $response->{body}, "Hello World\nFoo\n";
    note explain $response;

    $response = $map->request('GET', '/api/bar');
    is $response->{status}, 200;

    $response = $map->request('GET', '/api/fizz');
    ok !$response->{status};

    $response = $map->request('GET', '/api/fizz/12345');
    is $response->{status}, 200;
    is $response->{content_type}, 'text/plain';

    $response = $map->request('POST', '/api/bar');
    ok !$response->{status};
    note explain $response;
};

subtest url_list => sub {
    ok(grep(/api\/foo/, @{$map->url_list}));
    ok(grep(/api\/bar/, @{$map->url_list}));
    ok(grep(/api\/fizz/, @{$map->url_list}));
    ok(grep(/api\/hoge/, @{$map->url_list}));
    note explain $map->url_list;
};

done_testing;
