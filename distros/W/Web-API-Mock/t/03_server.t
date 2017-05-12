use strict;
use Test::More;
use Plack::Test;

use_ok $_ for qw(
    Web::API::Mock::Parser
    Web::API::Mock
);

my $parser = Web::API::Mock::Parser->new();
my $map;

subtest parse_md => sub {
    isa_ok $parser, 'Web::API::Mock::Parser';
    $parser->md(<<'...');
## GET /api/user

+ Request

+ Response 200 (text/html)

    + Body

            <html>
            <body>akihito</body>
            </html>

## POST /api/comment

+ Response 201 (application/json)

    + Headers

            X-Framework: Ark
    + Body

            {
                "status" : 200,
                "result": {
                    "ok": 1,
                }
            }

## GET /api/comment/{thread_id}/{number}

+ Request

+ Response 200 (text/html)

    + Body

            <html>
            <body>foobar</body>
            </html>

...

    $map = $parser->create_map();
    isa_ok $map, 'Web::API::Mock::Map';
};

subtest check_resource => sub {
    my $response = $map->request('GET', '/api/user');
    is $response->{status}, 200;
    is $response->{content_type}, 'text/html';

    $response = $map->request('POST', '/api/comment');
    is $response->{status}, 201;
    is $response->{content_type}, 'application/json';

};

my $mock = Web::API::Mock->new({
    parser => $parser,
    map    => $map,
});
my $app = $mock->psgi();

test_psgi $app, sub {
     my $cb  = shift;
     subtest user_request => sub {
         my $req = HTTP::Request->new(GET => "http://localhost/api/user");
         my $res = $cb->($req);
         like $res->content, qr!<html>.*akihito.*</html>!s;
     };

     subtest comment => sub {
         my $req = HTTP::Request->new(POST => "http://localhost/api/comment");
         my $res = $cb->($req);
         like $res->status_line, qr/201/;
         is $res->content_type, 'application/json';
         is $res->header('X-Framework'), 'Ark';
     };

     subtest bad_uri => sub {
         my $req = HTTP::Request->new(GET => "http://localhost/api/xxxx");
         my $res = $cb->($req);
         like $res->content, qr!404!s;
         like $res->status_line, qr/404/;
         is $res->content_type, 'text/plain';
     };

     subtest bad_method => sub {
         my $req = HTTP::Request->new(POST => "http://localhost/api/user");
         my $res = $cb->($req);
         like $res->content, qr!404!s;
         like $res->status_line, qr/404/;
         is $res->content_type, 'text/plain';
     };

     subtest get_comment => sub {
         my $req = HTTP::Request->new(GET => "http://localhost/api/comment/9999/123");
         my $res = $cb->($req);
         like $res->content, qr!<html>.*foo.*</html>!s;
     };

};

done_testing;
