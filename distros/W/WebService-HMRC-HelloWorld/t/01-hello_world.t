#!perl -T
use strict;
use warnings;
use Test::Exception;
use Test::More;
use WebService::HMRC::HelloWorld;
use WebService::HMRC::Authenticate;

plan tests => 21;

my($ws, $r, $auth);

# Instatiate the basic object
$ws = WebService::HMRC::HelloWorld->new();
isa_ok($ws, 'WebService::HMRC::HelloWorld', 'WebService::HMRC::HelloWorld object created');


# hello_world requires no authorisation
$r = $ws->hello_world;
isa_ok($r, 'WebService::HMRC::Response', 'hello_world method returns a WebService::HMRC::Response object');
ok($r->is_success, '/hello/world endpoint returned OK response');
is($r->data->{message}, 'Hello World', '/hello/world endpoint returned "Hello World" message');


# hello_world should fail with bad base_url is used
$ws->base_url('https://invalid/');
$r = $ws->hello_world;
isa_ok($r, 'WebService::HMRC::Response', 'hello_world method returns a WebService::HMRC::Response object when used with invalid base_url');
ok(! $r->is_success, '/hello/world does not indicate success when used with invalid base_url');
is($r->data->{code}, 'INVALID_RESPONSE', '/hello/world response element contains INVALID_RESPONSE code when used with invalid base_url');


# hello_application should croak without server_token
$ws = WebService::HMRC::HelloWorld->new();
dies_ok { $ws->hello_application } '/hello/application dies without auth';


# hello_application should fail with invalid server_token
isa_ok(
    $auth = WebService::HMRC::Authenticate->new(
        server_token => 'INVALID_SERVER_TOKEN'
    ),
    'WebService::HMRC::Authenticate',
    'created auth object with supplied server_token'
);
ok($ws->auth($auth), 'set auth with invalid server_token');

isa_ok(
    $r = $ws->hello_application,
    'WebService::HMRC::Response',
    '/hello/application returns with invalid server token'
);
ok(! $r->is_success, 'calling /hello/application with invalid server token does not indicate success');
is($r->data->{code}, 'INVALID_CREDENTIALS', 'INVALID_CREDENTIALS response calling /hello/application with invalid server_token');



# hello_application should return a message with a valid server token
SKIP: {
    my $token = $ENV{HMRC_SERVER_TOKEN} or skip (
        'Skipping tests on application-restricted endpoints as environment variable HMRC_SERVER_TOKEN is not set',
        4
    );

    isa_ok(
        $auth = WebService::HMRC::Authenticate->new({
            server_token => $ENV{HMRC_SERVER_TOKEN}
        }),
        'WebService::HMRC::Authenticate',
        'created auth object with supplied server_token'
    );
    ok($ws->auth($auth), 'set auth property with supplies server_token');

    $r = $ws->hello_application;

    ok($r->is_success, '/hello/application endpoint returned OK response');
    is($r->data->{message}, 'Hello Application', '/hello/application endpoint returned "Hello Application" message');
}



# Hello User should return a message with valid access_token
SKIP: {
    my $token = $ENV{HMRC_ACCESS_TOKEN} or skip (
        'Skipping tests on application-restricted endpoints as environment variable HMRC_ACCESS_TOKEN is not set',
        4
    );

    isa_ok(
        $auth = WebService::HMRC::Authenticate->new({
            access_token => $ENV{HMRC_ACCESS_TOKEN}
        }),
        'WebService::HMRC::Authenticate',
        'created auth object with supplied access_token'
    );
    ok($ws->auth($auth), 'set auth property with specified access_token');

    $r = $ws->hello_user;

    ok($r->is_success, '/hello/user endpoint returned OK response');
    is($r->data->{message}, 'Hello User', '/hello/user endpoint returned "Hello User" message');
}
