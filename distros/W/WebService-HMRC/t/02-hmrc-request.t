#!perl -T
use strict;
use warnings;
use Test::Exception;
use Test::More;
use WebService::HMRC::Authenticate;
use WebService::HMRC::Request;

plan tests => 32;

my ($uri, $ws, $response, $auth);


# Instatiate the basic object using defaults
$ws = WebService::HMRC::Request->new();
isa_ok($ws, 'WebService::HMRC::Request', 'WebService::HMRC::Request object created using defaults');
isa_ok($ws->ua, 'LWP::UserAgent', 'ua method returns LWP::UserAgent object');
is($ws->api_version, '1.0', 'api_version property is set to default');
is($ws->base_url, 'https://test-api.service.hmrc.gov.uk/', 'base_url method is set to default');
is($ws->ua->default_header('Accept'), 'application/vnd.hmrc.1.0+json', 'default Accept header set correctly');
$uri = $ws->endpoint_url('/test/endpoint');
isa_ok($uri, 'URI', 'endpoint_url method returns a URI object');
is($uri, 'https://test-api.service.hmrc.gov.uk/test/endpoint', 'endpoint_url correctly joins default base_url with endpoint');


# Check a default auth object is created if one is not specified
isa_ok($ws->auth, 'WebService::HMRC::Authenticate', 'default auth object created');


# Check an explicit auth object parameter is respected
isa_ok(
    $auth = WebService::HMRC::Authenticate->new({
        server_token => 'SERVER_TOKEN',
    }),
    'WebService::HMRC::Authenticate',
    'explicit auth object created'
);
isa_ok(
    $ws = WebService::HMRC::Request->new({
        auth => $auth,
    }),
    'WebService::HMRC::Request',
    'object created with explicit auth parameter'
);
is($ws->auth->server_token, 'SERVER_TOKEN', 'explicit auth server_token respected');


# Instantiate object with specified parameters
$ws = WebService::HMRC::Request->new({
    base_url => 'https://example.com/ws/',
    api_version => '9.9',
});
isa_ok($ws, 'WebService::HMRC::Request', 'WebService::HMRC::Request object created using specified parameters');
is($ws->api_version, '9.9', 'api_version property is set to specified value');
is($ws->base_url, 'https://example.com/ws/', 'base_url method is set to specified value');
is($ws->ua->default_header('Accept'), 'application/vnd.hmrc.9.9+json', 'default Accept header uses specified api version');
$uri = $ws->endpoint_url('/test/endpoint');#/test/endpoint');
is($uri, 'https://example.com/ws/test/endpoint', 'endpoint_url correctly joins specified base_url with endpoint');


# endpoint_url method croaks if endpoint is unspecified
dies_ok {
    $ws->endpoint_url()
} 'endpoint_url method croaks if endpoint is undefined';


# Try retrieving an invalid 'open' url/endpoint.
# Return should be a valid error response
isa_ok(
    $ws = WebService::HMRC::Request->new({
        base_url => 'https://invalid/',
    }),
    'WebService::HMRC::Request',
    'object created for invalid "open" url/endpoint'
);
isa_ok(
    $response = $ws->get_endpoint({
        endpoint => 'hello/world',
    }),
    'WebService::HMRC::Response',
    'response generated for invalid "open" url/endpoint'
);
is($response->data->{code}, 'INVALID_RESPONSE', 'INVALID_RESPONSE code generated for invalid "open" url/endpoint');
is($response->http->request->header('Authorization'), undef, 'No Authorization header for "open" endpoint');
is($response->header('content-type'), 'text/plain', 'response header correctly extracted');


# Try retrieving an invalid 'application-restricted' url/endpoint.
# Return should be a valid error response
dies_ok {
    $ws->get_endpoint({
        endpoint => 'hello/application',
        auth_type => 'application',
    })
} 'get_endpoint croaks for "application" endpoint without server_token';
ok($ws->auth->server_token('SERVER_TOKEN'), 'set server_token for "application" endpoint');
isa_ok(
    $response = $ws->get_endpoint({
        endpoint => 'hello/application',
        auth_type => 'application',
    }),
    'WebService::HMRC::Response',
    'response generated for invalid "application" url/endpoint'
);
is($response->data->{code}, 'INVALID_RESPONSE', 'INVALID_RESPONSE code generated for invalid "application" url/endpoint');
is($response->http->request->header('Authorization'), 'Bearer SERVER_TOKEN', 'Correct Authorization header for "application" endpoint');


# Try retrieving an invalid 'user-restricted' url/endpoint.
# Return should be a valid error response
dies_ok {
    $ws->get_endpoint({
        endpoint => 'hello/user',
        auth_type => 'user',
    })
} 'get_endpoint croaks for "user" endpoint without access_token';
ok($ws->auth->access_token('ACCESS_TOKEN'), 'set access_token for "user" endpoint');
isa_ok(
    $response = $ws->get_endpoint({
        endpoint => 'hello/user',
        auth_type => 'user',
    }),
    'WebService::HMRC::Response',
    'response generated for invalid "user" url/endpoint'
);
is($response->data->{code}, 'INVALID_RESPONSE', 'INVALID_RESPONSE code generated for invalid "user" url/endpoint');
is($response->http->request->header('Authorization'), 'Bearer ACCESS_TOKEN', 'Correct Authorization header for "user" endpoint');
