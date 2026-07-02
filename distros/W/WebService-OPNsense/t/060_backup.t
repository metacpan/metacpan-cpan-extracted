#!perl
use strictures 2;

use Test2::V1               qw( is ok subtest done_testing );
use Test2::Tools::Exception ();

use HTTP::Response       ();
use Ref::Util            qw( is_plain_hashref );
use Test::LWP::UserAgent ();

use constant {
    HTTP_OK                  => 200,
    HTTP_NOT_FOUND           => 404,
    HTTP_INTERNAL_SERVER_ERR => 500,
};

BEGIN { $WebService::OPNsense::VERSION = '0.001' }
use WebService::OPNsense ();

# Helper: build an OPNsense object with a mock handler
sub _build_opn {
    my ($handler) = @_;
    my $ua = Test::LWP::UserAgent->new;
    $ua->add_handler( request_send => $handler );
    return WebService::OPNsense->new(
        base_url => 'https://opnsense.example.com',
        username => 'key',
        password => 'secret',
        ua       => $ua,
    );
}

subtest 'providers' => sub {
    subtest 'GET 200 decoded data' => sub {
        my $captured;
        my $opn = _build_opn(
            sub {
                my ($req) = @_;
                $captured = $req->uri->as_string;
                HTTP::Response->new(
                    HTTP_OK, 'OK',
                    [ 'Content-Type' => 'application/json' ],
                    '{"rows":[{"name":"file","enabled":"1"},{"name":"ftp","enabled":"0"}]}',
                );
            }
        );
        my $providers = $opn->backup->providers;
        is(
            $captured,
            'https://opnsense.example.com/api/core/backup/providers',
            'URL path'
        );
        ok( is_plain_hashref($providers), 'returns hashref' );
        is( $providers->{rows}[0]{name},    'file', 'first row name' );
        is( $providers->{rows}[0]{enabled}, '1',    'first row enabled' );
        is( $providers->{rows}[1]{name},    'ftp',  'second row name' );
    };

    subtest 'GET 200 empty content returns undef' => sub {
        my $opn = _build_opn(
            sub {
                HTTP::Response->new(
                    HTTP_OK, 'OK',
                    [ 'Content-Type' => 'application/json' ],
                    q{},
                );
            }
        );
        ok(
            !defined $opn->backup->providers,
            'empty content returns undef'
        );
    };
};

subtest 'backups with host' => sub {
    my $captured;
    my $opn = _build_opn(
        sub {
            my ($req) = @_;
            $captured = $req->uri->as_string;
            HTTP::Response->new(
                HTTP_OK, 'OK',
                [ 'Content-Type' => 'application/json' ],
                '{"rows":[{"id":"20200601","description":"nightly"}]}',
            );
        }
    );
    my $backups = $opn->backup->backups('myfirewall');
    is(
        $captured,
        'https://opnsense.example.com/api/core/backup/backups/myfirewall',
        'URL path with host'
    );
    ok( is_plain_hashref($backups), 'returns hashref' );
    is( $backups->{rows}[0]{id}, '20200601', 'row id' );
};

subtest 'backups 404 throws Exception' => sub {
    my $opn = _build_opn(
        sub {
            HTTP::Response->new( HTTP_NOT_FOUND, 'Not Found' );
        }
    );
    my $e = eval { $opn->backup->backups('missing'); undef } || $@;
    ok( $e->isa('WebService::OPNsense::Exception'), '404 throws Exception' );
    is( $e->http_status, HTTP_NOT_FOUND, 'http_status is 404' );
};

subtest 'delete_backup' => sub {
    subtest 'POST 200 success' => sub {
        my ( $captured, $method );
        my $opn = _build_opn(
            sub {
                my ($req) = @_;
                $captured = $req->uri->as_string;
                $method   = $req->method;
                HTTP::Response->new(
                    HTTP_OK, 'OK',
                    [ 'Content-Type' => 'application/json' ],
                    '{"result":"deleted"}',
                );
            }
        );
        my $result = $opn->backup->delete_backup('bak-20200601');
        is( $method, 'POST', 'uses POST' );
        is(
            $captured,
            'https://opnsense.example.com/api/core/backup/deleteBackup/bak-20200601',
            'URL path'
        );
        is( $result->{result}, 'deleted', 'result' );
    };

    subtest 'POST 500 throws Exception' => sub {
        my $opn = _build_opn(
            sub {
                HTTP::Response->new(
                    HTTP_INTERNAL_SERVER_ERR, 'Internal Server Error',
                    [ 'Content-Type' => 'application/json' ],
                    '{"error":"delete failed"}',
                );
            }
        );
        my $e = eval { $opn->backup->delete_backup('bad-bak'); undef } || $@;
        ok(
            $e->isa('WebService::OPNsense::Exception'),
            '500 throws Exception'
        );
        is( $e->http_status, HTTP_INTERNAL_SERVER_ERR, 'http_status' );
        is( $e->message,     'delete failed',          'message' );
    };
};

subtest 'revert_backup' => sub {
    subtest 'POST 200 success' => sub {
        my ( $captured, $method );
        my $opn = _build_opn(
            sub {
                my ($req) = @_;
                $captured = $req->uri->as_string;
                $method   = $req->method;
                HTTP::Response->new(
                    HTTP_OK, 'OK',
                    [ 'Content-Type' => 'application/json' ],
                    '{"result":"reverted"}',
                );
            }
        );
        my $result = $opn->backup->revert_backup('bak-20200601');
        is( $method, 'POST', 'uses POST' );
        is(
            $captured,
            'https://opnsense.example.com/api/core/backup/revertBackup/bak-20200601',
            'URL path'
        );
        is( $result->{result}, 'reverted', 'result' );
    };

    subtest 'POST 500 throws Exception' => sub {
        my $opn = _build_opn(
            sub {
                HTTP::Response->new(
                    HTTP_INTERNAL_SERVER_ERR, 'Internal Server Error',
                    [ 'Content-Type' => 'application/json' ],
                    '{"error":"revert failed"}',
                );
            }
        );
        my $e = eval { $opn->backup->revert_backup('bad-bak'); undef } || $@;
        ok(
            $e->isa('WebService::OPNsense::Exception'),
            '500 throws Exception'
        );
        is( $e->http_status, HTTP_INTERNAL_SERVER_ERR, 'http_status' );
        is( $e->message,     'revert failed',          'message' );
    };
};

subtest 'download' => sub {
    subtest 'GET 200 with specific backup revision' => sub {
        my ( $captured, $method );
        my $opn = _build_opn(
            sub {
                my ($req) = @_;
                $captured = $req->uri->as_string;
                $method   = $req->method;
                HTTP::Response->new(
                    HTTP_OK, 'OK',
                    [ 'Content-Type' => 'application/json' ],
                    '{"configuration":"<opnsense></opnsense>"}',
                );
            }
        );
        my $config = $opn->backup->download( 'myfirewall', 'bak-20200601' );
        is( $method, 'GET', 'uses GET' );
        is(
            $captured,
            'https://opnsense.example.com/api/core/backup/download/myfirewall/bak-20200601',
            'URL path with backup revision'
        );
        is( $config->{configuration}, '<opnsense></opnsense>', 'returned data' );
    };

    subtest 'GET 200 without backup revision (optional segment omitted)' => sub {
        my ( $captured, $method );
        my $opn = _build_opn(
            sub {
                my ($req) = @_;
                $captured = $req->uri->as_string;
                $method   = $req->method;
                HTTP::Response->new(
                    HTTP_OK, 'OK',
                    [ 'Content-Type' => 'application/json' ],
                    '{"configuration":"<opnsense></opnsense>"}',
                );
            }
        );
        my $config = $opn->backup->download('myfirewall');
        is( $method, 'GET', 'uses GET' );
        is(
            $captured,
            'https://opnsense.example.com/api/core/backup/download/myfirewall',
            'URL path without backup revision'
        );
        is( $config->{configuration}, '<opnsense></opnsense>', 'returned data' );
    };

    subtest 'GET 404 throws Exception' => sub {
        my $opn = _build_opn(
            sub {
                HTTP::Response->new( HTTP_NOT_FOUND, 'Not Found' );
            }
        );
        my $e = eval { $opn->backup->download('myfirewall'); undef } || $@;
        ok( $e->isa('WebService::OPNsense::Exception'), '404 throws Exception' );
        is( $e->http_status, HTTP_NOT_FOUND, 'http_status is 404' );
    };

    subtest 'GET 500 throws Exception' => sub {
        my $opn = _build_opn(
            sub {
                HTTP::Response->new(
                    HTTP_INTERNAL_SERVER_ERR, 'Internal Server Error',
                    [ 'Content-Type' => 'application/json' ],
                    '{"error":"download failed"}',
                );
            }
        );
        my $e = eval { $opn->backup->download('myfirewall'); undef } || $@;
        ok(
            $e->isa('WebService::OPNsense::Exception'),
            '500 throws Exception'
        );
        is( $e->http_status, HTTP_INTERNAL_SERVER_ERR, 'http_status' );
        is( $e->message,     'download failed',        'message' );
    };
};

subtest 'diff' => sub {
    subtest 'GET 200 success' => sub {
        my ( $captured, $method );
        my $opn = _build_opn(
            sub {
                my ($req) = @_;
                $captured = $req->uri->as_string;
                $method   = $req->method;
                HTTP::Response->new(
                    HTTP_OK, 'OK',
                    [ 'Content-Type' => 'application/json' ],
                    '{"diff":"old vs new"}',
                );
            }
        );
        my $diff = $opn->backup->diff( 'myfirewall', 'bak-v1', 'bak-v2' );
        is( $method, 'GET', 'uses GET' );
        is(
            $captured,
            'https://opnsense.example.com/api/core/backup/diff/myfirewall/bak-v1/bak-v2',
            'URL path'
        );
        ok( defined $diff->{diff}, 'diff data returned' );
    };

    subtest 'GET 404 throws Exception' => sub {
        my $opn = _build_opn(
            sub {
                HTTP::Response->new( HTTP_NOT_FOUND, 'Not Found' );
            }
        );
        my $e = eval { $opn->backup->diff( 'myfirewall', 'bak-v1', 'bak-v2' ); undef } || $@;
        ok( $e->isa('WebService::OPNsense::Exception'), '404 throws Exception' );
        is( $e->http_status, HTTP_NOT_FOUND, 'http_status is 404' );
    };

    subtest 'GET 500 throws Exception' => sub {
        my $opn = _build_opn(
            sub {
                HTTP::Response->new(
                    HTTP_INTERNAL_SERVER_ERR, 'Internal Server Error',
                    [ 'Content-Type' => 'application/json' ],
                    '{"error":"diff failed"}',
                );
            }
        );
        my $e = eval {
            $opn->backup->diff( 'myfirewall', 'bak-v1', 'bak-v2' );
            undef;
        } || $@;
        ok(
            $e->isa('WebService::OPNsense::Exception'),
            '500 throws Exception'
        );
        is( $e->http_status, HTTP_INTERNAL_SERVER_ERR, 'http_status' );
        is( $e->message,     'diff failed',            'message' );
    };
};

done_testing;
