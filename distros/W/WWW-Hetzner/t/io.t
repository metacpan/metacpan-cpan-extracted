#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use WWW::Hetzner::HTTPRequest;
use WWW::Hetzner::HTTPResponse;
use WWW::Hetzner::LWPIO;
use WWW::Hetzner::Cloud;
use WWW::Hetzner::Robot;
use Test::WWW::Hetzner::Mock;

# --- HTTPRequest ---

subtest 'HTTPRequest attributes' => sub {
    my $req = WWW::Hetzner::HTTPRequest->new(
        method  => 'POST',
        url     => 'https://api.hetzner.cloud/v1/servers',
        headers => { Authorization => 'Bearer test', 'Content-Type' => 'application/json' },
        content => '{"name":"test"}',
    );

    is($req->method, 'POST', 'method');
    is($req->url, 'https://api.hetzner.cloud/v1/servers', 'url');
    is($req->headers->{Authorization}, 'Bearer test', 'auth header');
    is($req->content, '{"name":"test"}', 'content');
    ok($req->has_content, 'has_content is true');
};

subtest 'HTTPRequest without content' => sub {
    my $req = WWW::Hetzner::HTTPRequest->new(
        method => 'GET',
        url    => 'https://api.hetzner.cloud/v1/servers',
    );

    ok(!$req->has_content, 'has_content is false when no content');
    is_deeply($req->headers, {}, 'default headers is empty hashref');
};

# --- HTTPResponse ---

subtest 'HTTPResponse attributes' => sub {
    my $res = WWW::Hetzner::HTTPResponse->new(
        status  => 200,
        content => '{"servers":[]}',
    );

    is($res->status, 200, 'status');
    is($res->content, '{"servers":[]}', 'content');
};

subtest 'HTTPResponse default content' => sub {
    my $res = WWW::Hetzner::HTTPResponse->new(status => 204);

    is($res->status, 204, 'status');
    is($res->content, '', 'default content is empty string');
};

# --- Role::IO contract ---

subtest 'Role::IO requires call' => sub {
    eval q{
        package Test::BadIO;
        use Moo;
        with 'WWW::Hetzner::Role::IO';
        1;
    };
    like($@, qr/call/, 'Role::IO requires call method');
};

subtest 'Role::IO accepts valid implementation' => sub {
    eval q{
        package Test::GoodIO;
        use Moo;
        with 'WWW::Hetzner::Role::IO';
        sub call { }
        1;
    };
    is($@, '', 'Role::IO accepts class with call method');
};

# --- LWPIO ---

subtest 'LWPIO instantiation' => sub {
    my $io = WWW::Hetzner::LWPIO->new;
    isa_ok($io, 'WWW::Hetzner::LWPIO');
    is($io->timeout, 30, 'default timeout');
    isa_ok($io->ua, 'LWP::UserAgent');

    my $io2 = WWW::Hetzner::LWPIO->new(timeout => 60);
    is($io2->timeout, 60, 'custom timeout');
};

# --- IO injection ---

subtest 'Cloud accepts custom io' => sub {
    my $io = Test::WWW::Hetzner::MockIO->new(
        routes   => { 'GET /servers' => { servers => [] } },
        base_url => 'https://api.hetzner.cloud/v1',
    );

    my $cloud = WWW::Hetzner::Cloud->new(token => 'test', io => $io);
    is($cloud->io, $io, 'custom io is used');

    my $servers = $cloud->servers->list;
    is_deeply($servers, [], 'request goes through custom io');
};

subtest 'Robot accepts custom io' => sub {
    my $fixture = load_fixture('robot_servers_list');

    my $io = Test::WWW::Hetzner::MockIO->new(
        routes   => { 'GET /server' => $fixture },
        base_url => 'https://robot-ws.your-server.de',
    );

    my $robot = WWW::Hetzner::Robot->new(
        user => 'u', password => 'p', io => $io,
    );
    is($robot->io, $io, 'custom io is used');

    my $servers = $robot->servers->list;
    is(scalar @$servers, 2, 'request goes through custom io');
};

subtest 'Cloud defaults to LWPIO' => sub {
    my $cloud = WWW::Hetzner::Cloud->new(token => 'test');
    isa_ok($cloud->io, 'WWW::Hetzner::LWPIO');
};

# --- _build_request ---

subtest '_build_request for GET' => sub {
    my $cloud = mock_cloud('GET /servers' => { servers => [] });

    my $req = $cloud->_build_request('GET', '/servers', params => { page => 2, per_page => 25 });
    isa_ok($req, 'WWW::Hetzner::HTTPRequest');
    is($req->method, 'GET', 'method');
    like($req->url, qr{^https://api\.hetzner\.cloud/v1/servers\?}, 'url has base + path');
    like($req->url, qr{page=2}, 'url has page param');
    like($req->url, qr{per_page=25}, 'url has per_page param');
    is($req->headers->{Authorization}, 'Bearer test-token', 'bearer auth header');
    is($req->headers->{'Content-Type'}, 'application/json', 'content-type header');
    ok(!$req->has_content, 'GET has no content');
};

subtest '_build_request for POST with body' => sub {
    my $cloud = mock_cloud('POST /servers' => { server => {} });

    my $req = $cloud->_build_request('POST', '/servers', body => { name => 'test' });
    isa_ok($req, 'WWW::Hetzner::HTTPRequest');
    is($req->method, 'POST', 'method');
    is($req->url, 'https://api.hetzner.cloud/v1/servers', 'url without query params');
    ok($req->has_content, 'POST has content');
    like($req->content, qr/"name".*"test"/, 'content is JSON-encoded body');
};

subtest '_build_request skips undefined params' => sub {
    my $cloud = mock_cloud('GET /servers' => { servers => [] });

    my $req = $cloud->_build_request('GET', '/servers', params => { page => 1, name => undef });
    like($req->url, qr{page=1}, 'defined param included');
    unlike($req->url, qr{name}, 'undefined param excluded');
};

# --- _parse_response ---

subtest '_parse_response success with JSON' => sub {
    my $cloud = mock_cloud();

    my $res = WWW::Hetzner::HTTPResponse->new(
        status  => 200,
        content => '{"servers":[{"id":1}]}',
    );

    my $data = $cloud->_parse_response($res, 'GET', '/servers');
    is_deeply($data, { servers => [{ id => 1 }] }, 'parses JSON response');
};

subtest '_parse_response success with empty body' => sub {
    my $cloud = mock_cloud();

    my $res = WWW::Hetzner::HTTPResponse->new(status => 204, content => '');
    my $data = $cloud->_parse_response($res, 'DELETE', '/servers/1');
    is($data, undef, 'empty body returns undef');
};

subtest '_parse_response error with message' => sub {
    my $cloud = mock_cloud();

    my $res = WWW::Hetzner::HTTPResponse->new(
        status  => 404,
        content => '{"error":{"message":"Server not found"}}',
    );

    eval { $cloud->_parse_response($res, 'GET', '/servers/999') };
    like($@, qr/Server not found/, 'croak with API error message');
};

subtest '_parse_response error without JSON' => sub {
    my $cloud = mock_cloud();

    my $res = WWW::Hetzner::HTTPResponse->new(
        status  => 500,
        content => 'Internal Server Error',
    );

    eval { $cloud->_parse_response($res, 'GET', '/servers') };
    like($@, qr/500/, 'croak with status code when no JSON');
};

# --- Robot auth headers ---

subtest 'Robot _set_auth sets Basic auth header' => sub {
    my $robot = WWW::Hetzner::Robot->new(
        user => 'myuser', password => 'mypass',
        io   => Test::WWW::Hetzner::MockIO->new(
            routes   => { 'GET /server' => [] },
            base_url => 'https://robot-ws.your-server.de',
        ),
    );

    my %headers;
    $robot->_set_auth(\%headers);

    ok(exists $headers{Authorization}, 'Authorization header set');
    like($headers{Authorization}, qr/^Basic /, 'Basic auth prefix');

    require MIME::Base64;
    my $expected = 'Basic ' . MIME::Base64::encode_base64('myuser:mypass', '');
    is($headers{Authorization}, $expected, 'correct base64 encoding');
};

# --- MockIO route matching ---

subtest 'MockIO exact route match' => sub {
    my $cloud = mock_cloud(
        'GET /servers'  => { servers => [{ id => 1 }] },
        'POST /servers' => { server => { id => 2 } },
    );

    my $list = $cloud->get('/servers');
    is($list->{servers}[0]{id}, 1, 'GET matched');

    my $created = $cloud->post('/servers', { name => 'x' });
    is($created->{server}{id}, 2, 'POST matched');
};

subtest 'MockIO pattern route match' => sub {
    my $fixture = load_fixture('servers_get');

    my $cloud = mock_cloud(
        '/servers/\d+' => $fixture,
    );

    my $data = $cloud->get('/servers/123456');
    is($data->{server}{id}, 123456, 'regex route matched');
};

subtest 'MockIO dies on unknown route' => sub {
    my $cloud = mock_cloud();

    eval { $cloud->get('/nonexistent') };
    like($@, qr/No mock route/, 'dies for unmatched route');
};

subtest 'MockIO callback receives decoded body' => sub {
    my $received_body;

    my $cloud = mock_cloud(
        'POST /servers' => sub {
            my ($method, $path, %opts) = @_;
            $received_body = $opts{body};
            return { server => { id => 1 } };
        },
    );

    $cloud->post('/servers', { name => 'callback-test', type => 'cx22' });
    is($received_body->{name}, 'callback-test', 'callback received decoded body');
    is($received_body->{type}, 'cx22', 'all body fields present');
};

subtest 'MockIO supports HTTPResponse from route' => sub {
    my $cloud = mock_cloud(
        'GET /servers' => WWW::Hetzner::HTTPResponse->new(
            status  => 403,
            content => '{"error":{"message":"Forbidden"}}',
        ),
    );

    eval { $cloud->servers->list };
    like($@, qr/Forbidden/, 'HTTPResponse route triggers error handling');
};

subtest 'LWPIO names the reason for LWP internal failures' => sub {
    {
        package Test::StubUA;
        sub new { bless {}, shift }
        sub request {
            my $r = HTTP::Response->new(500, "Can't connect", [
                'Client-Warning' => 'Internal response',
                'Content-Type'   => 'text/plain',
            ], "Can't connect to 127.0.0.1:9 (Connection refused)\n");
            return $r;
        }
    }
    require HTTP::Response;
    my $cloud = WWW::Hetzner::Cloud->new(
        token => 't',
        io    => WWW::Hetzner::LWPIO->new(ua => Test::StubUA->new),
    );
    eval { $cloud->get('/servers') };
    like($@, qr/Hetzner API error: Can't connect to 127\.0\.0\.1:9/, 'transport reason in error');
};

subtest 'non-JSON error body contributes status and text' => sub {
    my $cloud = WWW::Hetzner::Cloud->new(token => 't');
    my $res = WWW::Hetzner::HTTPResponse->new(
        status => 502, content => "<html><body><h1>Bad Gateway</h1></body></html>");
    eval { $cloud->_parse_response($res, 'GET', '/servers') };
    like($@, qr/Hetzner API error: 502 Bad Gateway/, 'status and stripped text');
    $res = WWW::Hetzner::HTTPResponse->new(status => 503);
    eval { $cloud->_parse_response($res, 'GET', '/servers') };
    like($@, qr/Hetzner API error: 503 at/, 'bare status when no body');
};

done_testing;
