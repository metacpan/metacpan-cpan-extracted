use strict;
use warnings;
use Test::More;
use WWW::Hetzner;
use lib 't/lib';
use Test::WWW::Hetzner::Mock;

sub attempt {
    my ($code) = @_;
    my ($result, $error);
    my $ok = eval {
        $result = $code->();
        1;
    };
    $error = $@ unless $ok;
    return ($result, $error // '');
}

subtest 'Storage client uses the Storage API host and Bearer token' => sub {
    my ($storage, $error) = attempt(sub { mock_storage() });

    ok($storage, 'Storage client loads through mock_storage') or do {
        diag($error);
        fail('Storage client uses https://api.hetzner.com/v1');
        fail('Storage client builds a Bearer-authenticated request');
        return;
    };
    is($error, '', 'Storage client construction does not report an error');

    my $request = $storage->_build_request('GET', '/storage_boxes');
    isa_ok($request, 'WWW::Hetzner::HTTPRequest', 'Storage builds a transport request');
    is($request->url, 'https://api.hetzner.com/v1/storage_boxes', 'Storage uses its own API host');
    is_deeply($request->headers, {
        Authorization => 'Bearer test-token',
        'Content-Type' => 'application/json',
    }, 'Storage uses Cloud-style Bearer JSON transport');
};

subtest 'Storage client permits explicit token and base URL and rejects absent credentials' => sub {
    my ($storage, $error) = attempt(sub { mock_storage() });

    ok($storage, 'Storage client class is available') or do {
        diag($error);
        fail('Storage accepts an explicit token and base_url');
        fail('Storage rejects missing token before executing a request');
        return;
    };

    my $class = ref $storage;
    my $custom = $class->new(
        token    => 'custom-token',
        base_url => 'https://storage.example.test/v1',
        io       => $storage->io,
    );
    my $request = $custom->_build_request('GET', '/storage_boxes');
    is($request->url, 'https://storage.example.test/v1/storage_boxes', 'explicit base_url is honored');
    is($request->headers->{Authorization}, 'Bearer custom-token', 'explicit token is honored');

    my $missing = $class->new(token => undef, io => $storage->io);
    my ($result, $missing_error) = attempt(sub { $missing->get('/storage_boxes') });
    ok(!defined $result, 'missing credentials execute no request');
    like($missing_error, qr/token|Storage/i, 'missing credentials report a Storage token error');
};

subtest 'WWW::Hetzner exposes a Storage accessor without a root token attribute' => sub {
    my $hetzner = WWW::Hetzner->new;
    ok(!$hetzner->can('token'), 'umbrella client has no shared token attribute');

    my ($storage, $error) = attempt(sub { $hetzner->storage });
    isa_ok($storage, 'WWW::Hetzner::Storage', 'umbrella accessor builds a Storage client');
    is($error, '', 'Storage accessor does not require an umbrella token');
};

done_testing;
