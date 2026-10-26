use strict;
use warnings;
use Test::More;
use Config;
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::_Wire;

{ package PortableRequest; our @ISA = ('Uniform::HTTP::Request'); }
{ package PortableResponse; our @ISA = ('Uniform::HTTP::Response'); }

my @cases = (
    [GET => {}, { status => 200, body => "a\0b\xff" }],
    [GET => {}, { status => 201, headers => [['X-A', 'one'], ['X-A', 'two']], body => '' }],
    [POST => {}, { status => 299, reason => "custom\tphrase", body => 'ok' }],
    [GET => {}, { status => 599 }],
    [HEAD => {}, { status => 200, body => 'hidden' }],
    [GET => {}, { status => 204 }],
    [GET => {}, { status => 205 }],
    [GET => {}, { status => 304, headers => [['Content-Length', '10']] }],
    [GET => { headers => [['Connection', 'close']] }, { status => 200, body => 'bye' }],
    [GET => { version => '1.0' }, { status => 200, body => 'old' }],
    [GET => {}, { status => 200, headers => [['cOnTenT-LeNgTh', '2']], body => 'ok' }],
    [GET => {}, { status => 200, headers => [['Transfer-Encoding', 'chunked']], body => 'ok' }],
    [GET => {}, { status => 200, trailers => [['X-End', 'yes']], body => 'ok' }],
);
for my $i (0 .. $#cases) {
    my ($method, $request, $response) = @{ $cases[$i] };
    my %req = (method => $method, target => '/', version => '1.1', %$request);
    my $native = Unblock::HTTP1::_Wire::response_plan(
        Uniform::HTTP::Request->new(%req), Uniform::HTTP::Response->new(%$response));
    my $portable = Unblock::HTTP1::_Wire::response_plan(
        PortableRequest->new(%req), PortableResponse->new(%$response));
    is_deeply($native, $portable, "native/general parity case $i");
}

for my $fields (
    [['Content-Length', '99']],
    [['Content-Length', '2'], ['Transfer-Encoding', 'chunked']],
    [['Connection', 'invalid option']],
) {
    my $ok = eval { Unblock::HTTP1::_Wire::response_plan(
        Uniform::HTTP::Request->new(method => 'GET', target => '/'),
        Uniform::HTTP::Response->new(status => 200, body => 'ok', headers => $fields)); 1 };
    ok(!$ok, 'framing validation is not bypassed');
}

SKIP: {
    skip 'Perl without ithreads', 1 unless $Config{useithreads};
    require threads;
    my $thread = threads->create(sub {
        Unblock::HTTP1::_Wire::response_plan(
            Uniform::HTTP::Request->new(method => 'GET', target => '/'),
            Uniform::HTTP::Response->new(status => 200, body => 'child'))->{wire};
    });
    like($thread->join, qr/Content-Length: 5\r\n\r\nchild\z/,
        'native Uniform handle is initialized in cloned interpreter');
}
done_testing;
