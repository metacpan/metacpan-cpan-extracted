#!perl
use strictures 2;

use Test2::V1 qw( is like subtest done_testing );

use HTTP::Response       ();
use Test::LWP::UserAgent ();

use constant {
    E_ACUTE => 0xe9,
    HTTP_OK => 200,
};

BEGIN { $WebService::OPNsense::VERSION = '0.001' }
use WebService::OPNsense ();

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
                HTTP_OK, 'OK',
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

subtest 'scalar values' => sub {
    subtest 'spaces encoded' => sub {
        my $captured = _capture_get( { name => 'hello world' } );
        like(
            $captured, qr/name=hello%20world/,
            'space encoded as %20'
        );
    };

    subtest 'special characters encoded' => sub {
        my $captured = _capture_get( { q => 'foo & bar?baz=qux' } );
        like(
            $captured, qr/q=foo%20%26%20bar%3Fbaz%3Dqux/,
            'special characters encoded'
        );
    };

    subtest 'UTF-8 characters encoded' => sub {
        my $captured = _capture_get( { desc => 'caf' . chr(E_ACUTE) } );
        like(
            $captured, qr/desc=caf%C3%A9/,
            'UTF-8 characters encoded'
        );
    };
};

subtest 'arrayref values' => sub {
    my $captured = _capture_get( { tags => [ 'a b', 'c&d' ] } );
    like(
        $captured, qr/tags%5B%5D=a%20b/,
        'array element with space encoded'
    );
    like(
        $captured, qr/tags%5B%5D=c%26d/,
        'array element with ampersand encoded'
    );
};

subtest 'multiple params' => sub {
    my $captured = _capture_get( { a => '1', b => 'two words' } );
    like(
        $captured, qr/(?<=[?&])a=1(?=&|$)/,
        'simple value unchanged'
    );
    like(
        $captured, qr/(?<=[?&])b=two%20words(?=&|$)/,
        'value with spaces encoded'
    );
};

subtest 'no query string for empty params' => sub {
    my $captured = _capture_get( {} );
    is(
        $captured, 'https://opnsense.example.com/api/test',
        'empty params produce no query string'
    );
};

subtest 'no query string for undef params' => sub {
    my $ua = Test::LWP::UserAgent->new;
    my $captured;
    $ua->add_handler(
        request_send => sub {
            my ($req) = @_;
            $captured = $req->uri->as_string;
            HTTP::Response->new(
                HTTP_OK, 'OK',
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
};

done_testing;
