use strict;
use warnings;
use Test::More;
use lib 'lib';

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;

my $request = Uniform::HTTP::Request->new(
    method    => 'POST',
    target    => '/items?draft=1',
    scheme    => 'https',
    authority => 'example.com',
    headers   => [ [ Host => 'example.com' ] ],
);

isa_ok $request, 'Uniform::HTTP::Message';
is $request->method, 'POST', 'request method is retained';
is $request->target, '/items?draft=1', 'request target is retained exactly';
is $request->scheme, 'https', 'request scheme is retained';
is $request->authority, 'example.com', 'request authority is retained';
ok $request->target_is_exact, 'canonical request target is exact';
is $request->method('PATCH'), $request, 'method setter is chainable';
is $request->target('*'), $request, 'asterisk target is accepted';
is $request->scheme('custom+http'), $request, 'scheme setter is chainable';
is $request->authority('example.net:8443'), $request,
    'authority setter is chainable';
is $request->scheme(undef), $request, 'scheme can be cleared';
is $request->authority(undef), $request, 'authority can be cleared';
is $request->scheme, undef, 'cleared scheme is undef';
is $request->authority, undef, 'cleared authority is undef';

my $connect = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    target    => 'example.com:443',
    authority => 'example.com:443',
    version   => '2',
);
is $connect->target, 'example.com:443',
    'ordinary HTTP/2 CONNECT uses exact authority bytes as target';
is $connect->authority, 'example.com:443',
    'ordinary HTTP/2 CONNECT retains authority separately';
is $connect->scheme, undef,
    'ordinary HTTP/2 CONNECT does not require an invented scheme';
ok $connect->target_is_exact,
    'exact authority-form CONNECT target remains exact';

my $opaque_authority = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/',
    authority => 'user@example.com:443',
);
is $opaque_authority->authority, 'user@example.com:443',
    'authority is minimally checked rather than fully parsed';

for my $bad_authority ('', 'example.com/path', 'example.com?query', "bad host") {
    eval {
        Uniform::HTTP::Request->new(
            method    => 'GET',
            target    => '/',
            authority => $bad_authority,
        );
    };
    ok $@, "prohibited authority value is rejected: $bad_authority";
}

my $response = Uniform::HTTP::Response->new(
    status  => 204,
    headers => [ [ 'X-Test', 'yes' ] ],
);

isa_ok $response, 'Uniform::HTTP::Message';
is $response->status, 204, 'response status is retained';
is $response->reason, undef, 'reason is not synthesized';
is $response->version, undef, 'version is not synthesized';
is $response->status(299), $response, 'status setter is chainable';
is $response->reason('Custom'), $response, 'reason setter is chainable';
is $response->reason, 'Custom', 'reason is retained';
is $response->reason(undef), $response, 'reason can be cleared';
is $response->reason, undef, 'cleared reason is undef';

my $frozen_request = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/',
    scheme    => 'https',
    authority => 'example.com',
)->freeze;

for my $change (
    [ method    => sub { $frozen_request->method('POST') } ],
    [ target    => sub { $frozen_request->target('/other') } ],
    [ scheme    => sub { $frozen_request->scheme('http') } ],
    [ authority => sub { $frozen_request->authority('example.net') } ],
) {
    eval { $change->[1]->() };
    like $@, qr/message is immutable/,
        "freeze prevents request $change->[0] mutation";
}

my $frozen_response = Uniform::HTTP::Response->new(
    status => 200,
    reason => 'OK',
)->freeze;

eval { $frozen_response->status(201) };
like $@, qr/message is immutable/, 'freeze prevents response status mutation';
eval { $frozen_response->reason('Created') };
like $@, qr/message is immutable/, 'freeze prevents response reason mutation';

done_testing;
