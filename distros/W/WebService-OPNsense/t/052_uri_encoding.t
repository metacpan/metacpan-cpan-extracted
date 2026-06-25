#!perl
use v5.24;
use strictures 2;

use Test2::V1 qw( is ok like done_testing );

use HTTP::Response;
use Test::LWP::UserAgent;

BEGIN { $WebService::OPNsense::VERSION = '0.001' }
use WebService::OPNsense;

# Helper: create OPNsense object that captures outbound request URIs
sub _capture_get {
    my ($params) = @_;
    my $captured;
    my $ua = Test::LWP::UserAgent->new;
    $ua->add_handler(
        request_send => sub {
            my ($req) = @_;
            $captured = $req->uri->as_string;
            HTTP::Response->new(
                200, 'OK',
                [ 'Content-Type' => 'application/json' ],
                '{"status":"ok"}',
            );
        }
    );
    my $opn = WebService::OPNsense->new(
        base_url => 'https://opnsense.example.com',
        username => 'key',
        password => 'secret',
        ua       => $ua,
    );
    $opn->get( '/api/test', $params );
    return $captured;
}

# Scalar value with spaces
{
    my $captured = _capture_get( { name => 'hello world' } );
    like(
        $captured, qr/name=hello%20world/,
        'space encoded as %20'
    );
}

# Scalar value with special characters
{
    my $captured = _capture_get( { q => 'foo & bar?baz=qux' } );
    like(
        $captured, qr/q=foo%20%26%20bar%3Fbaz%3Dqux/,
        'special characters encoded'
    );
}

# UTF-8 characters
{
    my $captured = _capture_get( { desc => "caf\x{e9}" } );
    like(
        $captured, qr/desc=caf%C3%A9/,
        'UTF-8 characters encoded'
    );
}

# Arrayref values
{
    my $captured = _capture_get( { tags => [ 'a b', 'c&d' ] } );
    like(
        $captured, qr/tags%5B%5D=a%20b/,
        'array element with space encoded'
    );
    like(
        $captured, qr/tags%5B%5D=c%26d/,
        'array element with ampersand encoded'
    );
}

# Multiple params
{
    my $captured = _capture_get( { a => '1', b => 'two words' } );
    like(
        $captured, qr/(?<=[?&])a=1(?=&|$)/,
        'simple value unchanged'
    );
    like(
        $captured, qr/(?<=[?&])b=two%20words(?=&|$)/,
        'value with spaces encoded'
    );
}

# Empty params hashref → no query string
{
    my $captured = _capture_get( {} );
    is(
        $captured, 'https://opnsense.example.com/api/test',
        'empty params produce no query string'
    );
}

# No params (undef) → no query string
{
    my $ua = Test::LWP::UserAgent->new;
    my $captured;
    $ua->add_handler(
        request_send => sub {
            my ($req) = @_;
            $captured = $req->uri->as_string;
            HTTP::Response->new(
                200, 'OK',
                [ 'Content-Type' => 'application/json' ],
                '{"status":"ok"}',
            );
        }
    );
    my $opn = WebService::OPNsense->new(
        base_url => 'https://opnsense.example.com',
        username => 'key',
        password => 'secret',
        ua       => $ua,
    );
    $opn->get('/api/test');
    is(
        $captured, 'https://opnsense.example.com/api/test',
        'undef params produce no query string'
    );
}

done_testing;
