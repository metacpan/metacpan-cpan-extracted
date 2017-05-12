use strict;
use warnings;
use Test::More;
use Test::Fake::HTTPD;

use Web::Compare;

{
    my $ok_server = run_http_server {
        return [
            200,
            [],
            ['OK']
        ];
    };
    my $broken_server = run_http_server {
        return [
            500,
            [],
            ['Internal Server Error']
        ];
    };
    my $req_uri = $broken_server->endpoint;

    my $wc = Web::Compare->new(
        $req_uri, $ok_server->endpoint, {
            on_error => sub {
                my ($self, $res, $req) = @_;

                is $req->uri, $broken_server->endpoint;
                is $res->code, 500;
            },
        },
    );

    eval { $wc->report; };
    ok $@;
    like $@, qr/^Error: $req_uri\n500 Internal Server Error/;
}

done_testing;
