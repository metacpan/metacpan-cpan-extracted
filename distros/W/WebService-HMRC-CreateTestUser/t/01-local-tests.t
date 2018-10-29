#!perl -T
use strict;
use warnings;
use JSON::MaybeXS;
use Test::Exception;
use Test::More;
use WebService::HMRC::CreateTestUser;

plan tests => 35;

my($create, $r, $body);


# Instatiate the basic object with invalid url
$create = WebService::HMRC::CreateTestUser->new(base_url => 'http://invalid/');
isa_ok($create, 'WebService::HMRC::CreateTestUser', 'WebService::HMRC::CreateTestUser object created');


# Should croak without authorisation token
dies_ok {
    $create->individual({ services => [] })
} 'create individual dies without auth';

dies_ok {
    $create->organisation({ services => [] })
} 'create organisation dies without auth';

dies_ok {
    $create->agent({ services => [] })
} 'create agent dies without auth';


# Set a fake authorisation token
ok($create->auth->server_token('INVALID_TOKEN'), 'set an invalid SERVER TOKEN');


# Should croak with invalid services
dies_ok {
    $create->individual({ services => {} })
} 'create individual dies with invalid services';

dies_ok {
    $create->organisation({ services => {} })
} 'create organisation dies with invalid services';

dies_ok {
    $create->agent({ services => {} })
} 'create agent dies with invalid services';


# Should return a response with no services
isa_ok(
    $r = $create->individual(),
    'WebService::HMRC::Response',
    'create individual returns response object with no services specified'
);
ok(!$r->is_success, 'create individual is not successful with invalid url');
is($r->http->request->uri, 'http://invalid/create-test-user/individuals', 'create individual uses correct uri');
is($r->http->request->header('Authorization'), 'Bearer INVALID_TOKEN', 'create individual uses correct auth header');

isa_ok(
    $r = $create->organisation(),
    'WebService::HMRC::Response',
    'create organisation returns response object with no services specified'
);
ok(!$r->is_success, 'create organisation is not successful with invalid url');
is($r->http->request->uri, 'http://invalid/create-test-user/organisations', 'create organisation uses correct uri');
is($r->http->request->header('Authorization'), 'Bearer INVALID_TOKEN', 'create organisation uses correct auth header');

isa_ok(
    $r = $create->agent(),
    'WebService::HMRC::Response',
    'create agent returns response object with no services specified'
);
ok(!$r->is_success, 'create agent is not successful with invalid url');
is($r->http->request->uri, 'http://invalid/create-test-user/agents', 'create agent uses correct uri');
is($r->http->request->header('Authorization'), 'Bearer INVALID_TOKEN', 'create agent uses correct auth header');


# Should return a response with services specified
isa_ok(
    $r = $create->individual({ services => ['self-assessment', 'mtd-income-tax'] }),
    'WebService::HMRC::Response',
    'create individual returns response object with 2 services specified'
);
is($r->http->request->header('Accept'), 'application/vnd.hmrc.1.0+json', 'create individual has correct Accept header');
is($r->http->request->header('Content-type'), 'application/json', 'create individual has correct Content-type header');
ok($body = decode_json($r->http->request->content), 'decoded create individual request content');
is_deeply($body, {serviceNames => ['self-assessment', 'mtd-income-tax']}, 'create individual request specifies correct services');

isa_ok(
    $r = $create->organisation({ services => ['corporation-tax', 'mtd-vat'] }),
    'WebService::HMRC::Response',
    'create organisation returns response object with 2 services specified'
);
is($r->http->request->header('Accept'), 'application/vnd.hmrc.1.0+json', 'create organisation has correct Accept header');
is($r->http->request->header('Content-type'), 'application/json', 'create organisation has correct Content-type header');
ok($body = decode_json($r->http->request->content), 'decoded create organisation request content');
is_deeply($body, {serviceNames => ['corporation-tax', 'mtd-vat']}, 'create organisation request specifies correct services');

isa_ok(
    $r = $create->agent({ services => ['agent-services'] }),
    'WebService::HMRC::Response',
    'create agent returns response object with 1 service specified'
);
is($r->http->request->header('Accept'), 'application/vnd.hmrc.1.0+json', 'create agent has correct Accept header');
is($r->http->request->header('Content-type'), 'application/json', 'create agent has correct Content-type header');
ok($body = decode_json($r->http->request->content), 'decoded create agent request content');
is_deeply($body, {serviceNames => ['agent-services']}, 'create agent request specifies correct services');
