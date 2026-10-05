use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until pump_until_idle);
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP2::_Headers;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

my $received_request;
{
    no warnings 'redefine';
    local *Uniform::HTTP::Request::new = sub {
        die "normal Request constructor used";
    };

    $received_request = Unblock::HTTP2::_Headers->request_from_headers(
        [
            [ ':method',    'GET' ],
            [ ':scheme',    'https' ],
            [ ':authority', 'example.test' ],
            [ ':path',      '/trusted' ],
            [ 'x-test',     'one' ],
        ],
        end_stream => 1,
    );
}

isa_ok $received_request, 'Uniform::HTTP::Request';
is $received_request->target, '/trusted',
    'received request uses trusted native construction';
ok $received_request->is_complete,
    'trusted complete request keeps receive state';
ok !$received_request->is_mutable,
    'trusted complete request is frozen';

my $received_response;
{
    no warnings 'redefine';
    local *Uniform::HTTP::Response::new = sub {
        die "normal Response constructor used";
    };

    $received_response = Unblock::HTTP2::_Headers->response_from_headers(
        [
            [ ':status', '204' ],
            [ 'x-test',  'two' ],
        ],
        end_stream => 1,
    );
}

isa_ok $received_response, 'Uniform::HTTP::Response';
is $received_response->status, 204,
    'received response uses trusted native construction';
ok $received_response->is_complete,
    'trusted complete response keeps receive state';

{
    package Local::UniformRequest;
    use parent 'Uniform::HTTP::Request';
}

my $subclass = Local::UniformRequest->new(
    method    => 'GET',
    target    => '/fallback',
    scheme    => 'https',
    authority => 'example.test',
);

ok !Unblock::HTTP2::_Headers->native_message($subclass),
    'Uniform subclasses stay on the portable contract path';
is_deeply(
    Unblock::HTTP2::_Headers->request_headers($subclass),
    [
        [ ':method',    'GET' ],
        [ ':scheme',    'https' ],
        [ ':authority', 'example.test' ],
        [ ':path',      '/fallback' ],
    ],
    'portable fallback remains available',
);

my @errors;
my $done = 0;

my $server = Unblock::HTTP2::Server->new(
    on_request => sub {
        my ($stream, $request) = @_;
        is $request->header('x-mixed-case'), 'request-value',
            'native request FastPath lowercases field names for HTTP/2';
    },
    on_request_end => sub {
        my ($stream) = @_;
        $stream->respond(
            Uniform::HTTP::Response->new(
                status => 200,
                headers => [
                    [ 'X-Mixed-Response', 'response-value' ],
                ],
            )
        );
    },
    on_error => sub {
        my ($stream, $error) = @_;
        push @errors, "server: $error";
    },
);

my $client = Unblock::HTTP2::Client->new;
pump_until_idle($client, $server);

my $request = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/fast',
    scheme    => 'https',
    authority => 'example.test',
    headers   => [
        [ 'X-Mixed-Case', 'request-value' ],
    ],
);

{
    no warnings 'redefine';

    local *Unblock::HTTP2::_Headers::request_headers = sub {
        die "portable request header builder used for canonical request";
    };
    local *Unblock::HTTP2::_Headers::response_headers = sub {
        die "portable response header builder used for canonical response";
    };
    local *Unblock::HTTP2::_Headers::request_from_headers = sub {
        die "Perl request receive constructor used";
    };
    local *Unblock::HTTP2::_Headers::response_from_headers = sub {
        die "Perl response receive constructor used";
    };
    local *Uniform::HTTP::FastPath::request_from_validated = sub {
        die "Perl FastPath request constructor used";
    };
    local *Uniform::HTTP::FastPath::response_from_validated = sub {
        die "Perl FastPath response constructor used";
    };

    $client->request(
        $request,
        on_response => sub {
            my ($stream, $response) = @_;
            is $response->status, 200, 'native Uniform path response arrives';
            is $response->header('x-mixed-response'), 'response-value',
                'native response FastPath lowercases field names for HTTP/2';
        },
        on_complete => sub {
            $done = 1;
        },
        on_error => sub {
            my ($stream, $error) = @_;
            push @errors, "client: $error";
        },
    );

    pump_until($client, $server, sub { $done });
}

ok $done, 'canonical request and response use native Uniform path';
is_deeply \@errors, [], 'native Uniform exchange reports no errors';

done_testing;
