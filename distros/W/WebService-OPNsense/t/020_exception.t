#!perl
use v5.24;
use strictures 2;

use Test2::V1               qw( is isnt ok done_testing );
use Test2::Tools::Exception qw( dies lives );

use WebService::OPNsense::Exception;

# Create and throw
{
    my $e;
    ok(
        lives {
            eval {
                WebService::OPNsense::Exception->throw(
                    message     => 'test error',
                    http_status => 500,
                );
            };
            $e = $@;
        },
        'throw lives'
    );

    ok( $e->isa('WebService::OPNsense::Exception'), 'isa Exception' );
    is( $e->message,     'test error', 'message' );
    is( $e->http_status, 500,          'http_status' );
}

# throw actually dies
{
    my $e = eval {
        WebService::OPNsense::Exception->throw(
            message     => 'fatal',
            http_status => 503,
        );
        1;
    };
    ok( !$e, 'throw actually dies' );
    my $exc = $@;
    ok( $exc->isa('WebService::OPNsense::Exception'), 'caught exception isa Exception' );
    is( $exc->message, 'fatal', 'caught exception message' );
}

# throw with no http_status
{
    my $e = eval {
        WebService::OPNsense::Exception->throw(
            message => 'status unknown',
        );
        1;
    };
    ok( !$e, 'throw without http_status dies' );
    my $exc = $@;
    ok( $exc->isa('WebService::OPNsense::Exception'), 'isa Exception' );
    is( $exc->http_status, undef, 'http_status is undef when omitted' );
}

# throw with response object
{
    my $response_content = '{"error":"rate limit"}';

    my $e = eval {
        WebService::OPNsense::Exception->throw(
            message     => 'rate limited',
            http_status => 429,
            response    => $response_content,
        );
        1;
    };
    ok( !$e, 'throw with response dies' );
    my $exc = $@;
    is( $exc->response,    $response_content, 'response preserved' );
    is( $exc->http_status, 429,               'http_status set' );
}

# new without throw (direct construction)
{
    my $e = WebService::OPNsense::Exception->new(
        message     => 'Not Found',
        http_status => 404,
    );
    ok( defined $e, 'new returns an Exception' );
    is( $e->message,     'Not Found', 'new message' );
    is( $e->http_status, 404,         'new http_status' );
}

# Stringification
{
    my $e = WebService::OPNsense::Exception->new(
        message     => 'Not Found',
        http_status => 404,
    );
    is( "$e", 'Not Found', 'stringification' );
}

# Stringification with special characters
{
    my $e = WebService::OPNsense::Exception->new(
        message => 'Error: invalid input (code #42)',
    );
    is(
        "$e", 'Error: invalid input (code #42)',
        'stringification with special chars'
    );
}

# new without message should croak
{
    ok(
        dies {
            WebService::OPNsense::Exception->new(
                http_status => 500,
            );
        },
        'new without message croaks'
    );
}

done_testing;
