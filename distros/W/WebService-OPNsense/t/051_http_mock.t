#!perl
use v5.24;
use strictures 2;

use Test2::V1               qw( is isnt ok like done_testing );
use Test2::Tools::Exception qw( dies lives );

use HTTP::Request;
use HTTP::Status qw( status_message );
use HTTP::Response;
use Test::LWP::UserAgent;

BEGIN { $WebService::OPNsense::VERSION = '0.001' }
use WebService::OPNsense;

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

# GET 200 returns decoded data
{
    my $opn  = _build_mock( 200, '{"status":"ok","count":42}' );
    my $req  = HTTP::Request->new( GET => 'http://localhost/api/test' );
    my $data = $opn->req($req);
    is( ref $data,       'HASH', 'GET 200 returns hashref' );
    is( $data->{status}, 'ok',   'GET 200 data status' );
    is( $data->{count},  42,     'GET 200 data count' );
}

# GET 404 returns undef
{
    my $opn = _build_mock( 404, '{"message":"not found"}' );
    my $req = HTTP::Request->new( GET => 'http://localhost/api/test' );
    ok( !defined $opn->req($req), 'GET 404 returns undef' );
}

# GET 410 returns undef
{
    my $opn = _build_mock( 410, '{"message":"gone"}' );
    my $req = HTTP::Request->new( GET => 'http://localhost/api/test' );
    ok( !defined $opn->req($req), 'GET 410 returns undef' );
}

# POST 200 returns decoded data
{
    my $opn  = _build_mock( 200, '{"result":"created"}' );
    my $req  = HTTP::Request->new( POST => 'http://localhost/api/test' );
    my $data = $opn->req($req);
    is( ref $data,       'HASH',    'POST 200 returns hashref' );
    is( $data->{result}, 'created', 'POST 200 data result' );
}

# POST 400 throws Exception
{
    my $opn = _build_mock( 400, '{"error":"bad request"}' );
    my $req = HTTP::Request->new( POST => 'http://localhost/api/test' );
    ok( dies { $opn->req($req) }, 'POST 400 throws' );
}

# POST 500 throws Exception
{
    my $opn = _build_mock( 500, '{"message":"server error"}' );
    my $req = HTTP::Request->new( POST => 'http://localhost/api/test' );
    ok( dies { $opn->req($req) }, 'POST 500 throws' );
}

# Exception check: http_status and message
{
    my $opn = _build_mock( 403, '{"error":"forbidden"}' );
    my $req = HTTP::Request->new( POST => 'http://localhost/api/test' );
    my $e   = eval { $opn->req($req); undef } || $@;
    ok( $e->isa('WebService::OPNsense::Exception'), 'exception isa Exception' );
    is( $e->http_status, 403,         'exception http_status' );
    is( $e->message,     'forbidden', 'exception message' );
}

# Exception without error key falls back to message key
{
    my $opn = _build_mock( 422, '{"message":"unprocessable"}' );
    my $req = HTTP::Request->new( POST => 'http://localhost/api/test' );
    my $e   = eval { $opn->req($req); undef } || $@;
    is( $e->message, 'unprocessable', 'fallback to message key' );
}

# Exception without error/message falls back to status_line
{
    my $opn = _build_mock( 418, '{"unknown":"data"}' );
    my $req = HTTP::Request->new( POST => 'http://localhost/api/test' );
    my $e   = eval { $opn->req($req); undef } || $@;
    is( $e->message, '418 I\'m a teapot', 'fallback to status_line' );
}

# No content returns undef
{
    my $opn = _build_mock( 200, '' );
    my $req = HTTP::Request->new( GET => 'http://localhost/api/test' );
    ok( !defined $opn->req($req), 'empty content returns undef' );
}

# Invalid JSON returns undef
{
    my $opn = _build_mock( 200, 'not valid json' );
    my $req = HTTP::Request->new( GET => 'http://localhost/api/test' );
    ok( !defined $opn->req($req), 'invalid JSON returns undef' );
}

done_testing;
