#!perl
use strictures 2;

use Test2::V1               qw( is ok subtest done_testing );
use Test2::Tools::Exception qw( dies );

use HTTP::Request ();
use HTTP::Status  qw(
    HTTP_BAD_REQUEST
    HTTP_FORBIDDEN
    HTTP_GONE
    HTTP_NOT_FOUND
    HTTP_OK
    status_message
);
use HTTP::Response       ();
use Ref::Util            qw( is_plain_hashref );
use Test::LWP::UserAgent ();

use constant {
    HTTP_OK                  => 200,
    HTTP_NOT_FOUND           => 404,
    HTTP_GONE                => 410,
    HTTP_BAD_REQUEST         => 400,
    HTTP_INTERNAL_SERVER_ERR => 500,
    HTTP_FORBIDDEN           => 403,
    HTTP_UNPROCESSABLE       => 422,
    HTTP_TEAPOT              => 418,
    TEST_COUNT               => 42,
};

BEGIN { $WebService::OPNsense::VERSION = '0.001' }
use WebService::OPNsense ();

# Helper: build an OPNsense object with a mock that returns a given response
sub _build_mock {
    my ( $status, $content, $content_type ) = @_;
    $content_type ||= 'application/json';
    my $ua = Test::LWP::UserAgent->new;
    $ua->add_handler(
        request_send => sub {
            HTTP::Response->new(
                $status,
                status_message($status),
                [ 'Content-Type' => $content_type ],
                $content,
            );
        }
    );
    return WebService::OPNsense->new(
        base_url => 'https://opnsense.example.com',
        username => 'key',
        password => 'secret',
        ua       => $ua,
    );
}

subtest 'GET 200 returns decoded data' => sub {
    my $opn    = _build_mock( HTTP_OK, '{"status":"ok","count":42}' );
    my $req    = HTTP::Request->new( GET => 'http://localhost/api/test' );
    my $result = $opn->req($req);
    ok( is_plain_hashref($result), 'returns hashref' );
    is( $result->{status}, 'ok',       'data status' );
    is( $result->{count},  TEST_COUNT, 'data count' );
};

subtest 'GET 404 throws Exception' => sub {
    my $opn = _build_mock( HTTP_NOT_FOUND, '{"message":"not found"}' );
    my $req = HTTP::Request->new( GET => 'http://localhost/api/test' );
    ok( dies { $opn->req($req) }, 'GET 404 throws' );
};

subtest 'GET 410 throws Exception' => sub {
    my $opn = _build_mock( HTTP_GONE, '{"message":"gone"}' );
    my $req = HTTP::Request->new( GET => 'http://localhost/api/test' );
    ok( dies { $opn->req($req) }, 'GET 410 throws' );
};

subtest 'POST 200 returns decoded data' => sub {
    my $opn    = _build_mock( HTTP_OK, '{"result":"created"}' );
    my $req    = HTTP::Request->new( POST => 'http://localhost/api/test' );
    my $result = $opn->req($req);
    ok( is_plain_hashref($result), 'returns hashref' );
    is( $result->{result}, 'created', 'data result' );
};

subtest 'POST 400 throws Exception' => sub {
    my $opn = _build_mock( HTTP_BAD_REQUEST, '{"error":"bad request"}' );
    my $req = HTTP::Request->new( POST => 'http://localhost/api/test' );
    ok( dies { $opn->req($req) }, 'throws' );
};

subtest 'POST 500 throws Exception' => sub {
    my $opn = _build_mock( HTTP_INTERNAL_SERVER_ERR, '{"message":"server error"}' );
    my $req = HTTP::Request->new( POST => 'http://localhost/api/test' );
    ok( dies { $opn->req($req) }, 'throws' );
};

subtest 'Exception details' => sub {
    subtest 'http_status and message' => sub {
        my $opn = _build_mock( HTTP_FORBIDDEN, '{"error":"forbidden"}' );
        my $req = HTTP::Request->new( POST => 'http://localhost/api/test' );
        my $e   = eval { $opn->req($req); undef } || $@;
        ok( $e->isa('WebService::OPNsense::Exception'), 'isa Exception' );
        is( $e->http_status, HTTP_FORBIDDEN, 'http_status' );
        is( $e->message,     'forbidden',    'message' );
    };

    subtest 'fallback to message key' => sub {
        my $opn = _build_mock( HTTP_UNPROCESSABLE, '{"message":"unprocessable"}' );
        my $req = HTTP::Request->new( POST => 'http://localhost/api/test' );
        my $e   = eval { $opn->req($req); undef } || $@;
        is( $e->message, 'unprocessable', 'message from message key' );
    };

    subtest 'fallback to status_line' => sub {
        my $opn = _build_mock( HTTP_TEAPOT, '{"unknown":"data"}' );
        my $req = HTTP::Request->new( POST => 'http://localhost/api/test' );
        my $e   = eval { $opn->req($req); undef } || $@;
        is( $e->message, '418 I\'m a teapot', 'message from status_line' );
    };
};

subtest 'content edge cases' => sub {
    subtest 'empty content returns undef' => sub {
        my $opn = _build_mock( HTTP_OK, q{} );
        my $req = HTTP::Request->new( GET => 'http://localhost/api/test' );
        ok( !defined $opn->req($req), 'empty content returns undef' );
    };

    subtest 'invalid JSON returns undef' => sub {
        my $opn = _build_mock( HTTP_OK, 'not valid json' );
        my $req = HTTP::Request->new( GET => 'http://localhost/api/test' );
        ok( !defined $opn->req($req), 'invalid JSON returns undef' );
    };
};

done_testing;
