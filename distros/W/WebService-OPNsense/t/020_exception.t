#!perl
use strictures 2;

use Test2::V1               qw( is ok subtest done_testing );
use Test2::Tools::Exception qw( dies );

use WebService::OPNsense::Exception ();

use constant {
    HTTP_INTERNAL_SERVER_ERROR => 500,
    HTTP_NOT_FOUND             => 404,
    HTTP_TOO_MANY_REQUESTS     => 429,
};

subtest 'throw and catch' => sub {
    my $e = eval {
        WebService::OPNsense::Exception->throw(
            message     => 'test error',
            http_status => HTTP_INTERNAL_SERVER_ERROR,
        );
        1;
    };
    ok( !$e, 'throw dies' );
    $e = $@;

    ok( $e->isa('WebService::OPNsense::Exception'), 'isa Exception' );
    is( $e->message,     'test error',               'message' );
    is( $e->http_status, HTTP_INTERNAL_SERVER_ERROR, 'http_status' );
};

subtest 'throw actually dies' => sub {
    my $e = eval {
        WebService::OPNsense::Exception->throw(
            message     => 'fatal',
            http_status => 503,
        );
        1;
    };
    ok( !$e, 'throw actually dies' );
    my $exc = $@;
    ok( $exc->isa('WebService::OPNsense::Exception'), 'isa Exception' );
    is( $exc->message, 'fatal', 'caught exception message' );
};

subtest 'throw without http_status' => sub {
    my $e = eval {
        WebService::OPNsense::Exception->throw(
            message => 'status unknown',
        );
        1;
    };
    ok( !$e, 'throw dies' );
    my $exc = $@;
    ok( $exc->isa('WebService::OPNsense::Exception'), 'isa Exception' );
    is( $exc->http_status, undef, 'http_status is undef when omitted' );
};

subtest 'throw with response object' => sub {
    my $response_content = '{"error":"rate limit"}';

    my $e = eval {
        WebService::OPNsense::Exception->throw(
            message     => 'rate limited',
            http_status => HTTP_TOO_MANY_REQUESTS,
            response    => $response_content,
        );
        1;
    };
    ok( !$e, 'throw dies' );
    my $exc = $@;
    is( $exc->response,    $response_content,      'response preserved' );
    is( $exc->http_status, HTTP_TOO_MANY_REQUESTS, 'http_status set' );
};

subtest 'direct construction' => sub {
    my $e = WebService::OPNsense::Exception->new(
        message     => 'Not Found',
        http_status => HTTP_NOT_FOUND,
    );
    ok( defined $e, 'new returns an Exception' );
    is( $e->message,     'Not Found',    'new message' );
    is( $e->http_status, HTTP_NOT_FOUND, 'new http_status' );
};

subtest 'stringification' => sub {
    subtest 'basic' => sub {
        my $e = WebService::OPNsense::Exception->new(
            message     => 'Not Found',
            http_status => HTTP_NOT_FOUND,
        );
        is( "$e", 'Not Found', 'stringification' );
    };

    subtest 'special characters' => sub {
        my $e = WebService::OPNsense::Exception->new(
            message => 'Error: invalid input (code #42)',
        );
        is(
            "$e", 'Error: invalid input (code #42)',
            'stringification with special chars'
        );
    };
};

subtest 'new without message croaks' => sub {
    ok(
        dies {
            WebService::OPNsense::Exception->new(
                http_status => 500,
            );
        },
        'new without message croaks'
    );
};

done_testing;
