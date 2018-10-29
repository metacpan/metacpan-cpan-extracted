#!perl -T
use strict;
use warnings;
use JSON::MaybeXS qw(decode_json);
use Test::Exception;
use Test::More;
use WebService::HMRC::Authenticate;
use WebService::HMRC::Request;

plan tests => 21;

my ($uri, $ws, $response, $auth);


# Try posting an invalid 'open' url/endpoint.
# Return should be a valid error response
isa_ok(
    $ws = WebService::HMRC::Request->new({
        base_url => 'https://invalid/',
    }),
    'WebService::HMRC::Request',
    'object created for invalid "open" url/endpoint'
);

dies_ok {
    $response = $ws->post_endpoint_json({
        endpoint => 'hello/world',
    });
} 'post_endpoint_json dies without a data parameter';

dies_ok {
    $response = $ws->post_endpoint_json({
        endpoint => 'hello/world',
        data => undef,
    });
} 'post_endpoint_json dies with undef data parameter';

dies_ok {
    $response = $ws->post_endpoint_json({
        endpoint => 'hello/world',
        data => 'scalar',
    });
} 'post_endpoint_json dies with scalar data parameter';


# Test an unrestricted endpoint
my $data = {key1 => 'value1', key2 => 'value2'};
isa_ok(
    $response = $ws->post_endpoint_json({
        endpoint => 'hello/world',
        data => $data,
    }),
    'WebService::HMRC::Response',
    'response generated posting to invalid "open" endpoint'
);
is($response->data->{code}, 'INVALID_RESPONSE', 'INVALID_RESPONSE code generated for invalid "open" url/endpoint');
is($response->http->request->header('Authorization'), undef, 'No Authorization header for "open" endpoint');
is($response->http->request->header('Content-Type'), 'application/json', 'request content-type set to application/json');
is($response->http->request->uri, 'https://invalid/hello/world', 'request uri is correct');
is_deeply(
    decode_json($response->http->request->content),
    $data,
    'http request enccoded data as json'
);


# Test an application-restricted endpoint with additional header
ok($ws->auth->server_token('APPLICATION_TOKEN'), 'set server token');
isa_ok(
    $response = $ws->post_endpoint_json({
        endpoint => 'hello/world',
        data => $data,
        auth_type => 'application',
        headers => ['EXTRA-HEADER' => 'HEADER_VALUE'],
    }),
    'WebService::HMRC::Response',
    'response generated posting to invalid "application" endpoint'
);
is($response->data->{code}, 'INVALID_RESPONSE', 'INVALID_RESPONSE code generated for invalid "application" url/endpoint');
is($response->http->request->header('Authorization'), 'Bearer APPLICATION_TOKEN', 'Application token used for authorisation header');
is($response->http->request->header('Content-Type'), 'application/json', 'request content-type set to application/json');
is($response->http->request->header('EXTRA-HEADER'), 'HEADER_VALUE', 'request custom header set');


# Test a user-restricted endpoint
ok($ws->auth->access_token('ACCESS_TOKEN'), 'set access token');
isa_ok(
    $response = $ws->post_endpoint_json({
        endpoint => 'hello/world',
        data => $data,
        auth_type => 'user',
    }),
    'WebService::HMRC::Response',
    'response generated posting to invalid "user" endpoint'
);
is($response->data->{code}, 'INVALID_RESPONSE', 'INVALID_RESPONSE code generated for invalid "user" url/endpoint');
is($response->http->request->header('Authorization'), 'Bearer ACCESS_TOKEN', 'Access token used for authorisation header');
is($response->http->request->header('Content-Type'), 'application/json', 'request content-type set to application/json');
