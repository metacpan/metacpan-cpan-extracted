use strict;
use warnings;
use utf8;
use Test::More;
use WWW::Hetzner::HTTPRequest;
use lib 't/lib';
use Test::WWW::Hetzner::Mock;

sub query_parts {
    my ($request) = @_;
    my ($query) = $request->url =~ /\?(.*)\z/;
    return [ sort split /&/, ($query // ''), -1 ];
}

subtest 'Cloud retains JSON and Bearer authentication' => sub {
    my $cloud = mock_cloud();
    my $request = $cloud->_build_request('POST', '/servers', body => {
        name => 'cloud & = + % space',
    });

    isa_ok($request, 'WWW::Hetzner::HTTPRequest', 'Cloud builds a transport request');
    is($request->method, 'POST', 'Cloud request method');
    is($request->url, 'https://api.hetzner.cloud/v1/servers', 'Cloud request URL');
    is_deeply($request->headers, {
        Authorization => 'Bearer test-token',
        'Content-Type' => 'application/json',
    }, 'Cloud request headers');
    is($request->content, '{"name":"cloud & = + % space"}', 'Cloud request content remains JSON');
};

subtest 'Robot POST is form encoded and preserves Basic authentication' => sub {
    my $robot = mock_robot();
    my $request = $robot->_build_request('POST', '/order/server/transaction', body => {
        authorized_key => [
            '15:28:b0:03',
            'aa:bb:cc:dd',
        ],
    });

    isa_ok($request, 'WWW::Hetzner::HTTPRequest', 'Robot builds a transport request');
    is($request->method, 'POST', 'Robot request method');
    is($request->url, 'https://robot-ws.your-server.de/order/server/transaction', 'Robot request URL');
    is_deeply($request->headers, {
        Authorization => 'Basic dGVzdC11c2VyOnRlc3QtcGFzc3dvcmQ=',
        'Content-Type' => 'application/x-www-form-urlencoded',
    }, 'Robot request headers');

    # Hetzner Robot documents one or more fingerprints as authorized_key[]:
    # https://robot.hetzner.com/doc/webservice/en.html#order-server-transaction
    is($request->content,
        'authorized_key%5B%5D=15%3A28%3Ab0%3A03&authorized_key%5B%5D=aa%3Abb%3Acc%3Add',
        'Robot authorized_key array uses documented repeated authorized_key[] form parameters',
    );
};

subtest 'query strings percent encode Unicode, reserved values, repeated values, and omit undef' => sub {
    my $params = {
        'q &=+% space' => 'Grüße &=+% space',
        repeat         => [ 'one &', 'two=+%' ],
        omitted        => undef,
    };
    my $expected_params = {
        'q &=+% space' => 'Grüße &=+% space',
        repeat         => [ 'one &', 'two=+%' ],
    };
    my $expected_parts = [ sort { $a cmp $b } (
        'q%20%26%3D%2B%25%20space=Gr%C3%BC%C3%9Fe%20%26%3D%2B%25%20space',
        'repeat=one%20%26',
        'repeat=two%3D%2B%25',
    ) ];

    my $raw_cloud = mock_cloud();
    my $request = $raw_cloud->_build_request('GET', '/request', params => $params);
    isa_ok($request, 'WWW::Hetzner::HTTPRequest', 'query test uses the raw transport request');
    is($request->method, 'GET', 'query request method');
    is_deeply(query_parts($request), $expected_parts, 'raw query has exactly the percent-encoded pairs');
    unlike($request->url, qr/(?:[?&])omitted=/, 'undef scalar is not encoded as a query parameter');

    my %seen;
    my $cloud = mock_cloud(
        'GET /request' => sub {
            my ($method, $path, %opts) = @_;
            $seen{method}  = $method;
            $seen{path}    = $path;
            $seen{params}  = $opts{params};
            $seen{request} = $opts{request};
            return {};
        },
    );

    $cloud->get('/request', params => $params);
    is($seen{method}, 'GET', 'callback method remains compatible');
    is($seen{path}, '/request', 'callback path excludes the query for route compatibility');
    is_deeply($seen{params}, $expected_params, 'callback receives decoded query values and repeated values');
    isa_ok($seen{request}, 'WWW::Hetzner::HTTPRequest', 'callback receives the unmodified raw request');

    my %decoded;
    my $wire_cloud = mock_cloud(
        'GET /request' => sub {
            my ($method, $path, %opts) = @_;
            $decoded{method}  = $method;
            $decoded{path}    = $path;
            $decoded{params}  = $opts{params};
            $decoded{request} = $opts{request};
            return {};
        },
    );
    my $wire_request = WWW::Hetzner::HTTPRequest->new(
        method  => 'GET',
        url     => 'https://api.hetzner.cloud/v1/request?' . join('&', @$expected_parts),
        headers => {},
    );

    $wire_cloud->io->call($wire_request);
    is($decoded{method}, 'GET', 'encoded query callback method');
    is($decoded{path}, '/request', 'encoded query callback path remains route-compatible');
    is_deeply($decoded{params}, $expected_params, 'MockIO decodes encoded query values and retains repeated values');
    is($decoded{request}, $wire_request, 'MockIO preserves the raw query request');
};

subtest 'MockIO decodes Robot form bodies into existing callback body shapes' => sub {
    my %seen;
    my $robot = mock_robot(
        'POST /boot/123456/rescue' => sub {
            my ($method, $path, %opts) = @_;
            $seen{method}  = $method;
            $seen{path}    = $path;
            $seen{body}    = $opts{body};
            $seen{request} = $opts{request};
            return {};
        },
    );
    my $request = WWW::Hetzner::HTTPRequest->new(
        method  => 'POST',
        url     => 'https://robot-ws.your-server.de/boot/123456/rescue',
        headers => { 'Content-Type' => 'application/x-www-form-urlencoded' },
        content => 'os=linux&authorized_key%5B%5D=aa%3Abb%3Acc%3Add&authorized_key%5B%5D=ee%3Aff%3A00%3A11',
    );

    $robot->io->call($request);

    is($seen{method}, 'POST', 'form callback method');
    is($seen{path}, '/boot/123456/rescue', 'form callback path');
    is_deeply($seen{body}, {
        os             => 'linux',
        authorized_key => [ 'aa:bb:cc:dd', 'ee:ff:00:11' ],
    }, 'form callback body retains the existing decoded Perl shape');
    is($seen{request}, $request, 'form callback also receives the raw request');
};

done_testing;
