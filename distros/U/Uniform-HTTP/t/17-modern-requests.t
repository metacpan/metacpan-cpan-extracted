use strict;
use warnings;
use Test::More;
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;

for my $version (undef, '1.1', '2', '3') {
    for my $target ('/a%2fb?x=1&x=2', 'https://Example.com:443/a%2Fb?',
            '[2001:db8::1]:443', '*') {
        my $r = Uniform::HTTP::Request->new(method => 'OPTIONS', target => $target,
            version => $version, headers => [['Host', 'example.com'], ['Upgrade', 'websocket']]);
        is $r->version, $version, 'version preserved including undef';
        is $r->target, $target, 'target form and bytes retained';
        ok $r->target_is_exact, 'supplied target is exact';
        is $r->scheme, undef, 'no scheme inference';
        is $r->authority, undef, 'no authority inference from target or Host';
        is $r->protocol, undef, 'no protocol inference from Upgrade';
    }
}
for my $version ('1.1', '2', '3') {
    my $authority = '[2001:db8::1]:0443';
    my $ordinary = Uniform::HTTP::Request->new(method => 'CONNECT',
        target => $authority, authority => $authority, version => $version);
    is $ordinary->target, $authority, 'ordinary CONNECT authority-form unchanged';
    is $ordinary->authority, $authority, 'ordinary CONNECT authority unchanged';
    is $ordinary->scheme, undef, 'ordinary CONNECT has no scheme';
    is $ordinary->protocol, undef, 'ordinary CONNECT has no protocol';
    ok $ordinary->target_is_exact, 'copied CONNECT target remains exact';
}
for my $version (undef, '2', '3') {
    for my $protocol ('websocket', 'connect-udp', 'webtransport', 'webtransport-h3',
            'Future.Protocol+V42', q{!#$%&'*+-.^_`|~09AZaz}) {
        my $r = Uniform::HTTP::Request->new(method => 'CONNECT', protocol => $protocol,
            scheme => 'https', authority => 'Example.com:8443', target => '/chat%2f?q=1',
            version => $version, headers => [['Priority', 'u=1, i'], ['Capsule-Protocol', '?1']]);
        is $r->protocol, $protocol, 'extended protocol token exact';
        is $r->target, '/chat%2f?q=1', 'extended CONNECT target remains path';
        is $r->authority, 'Example.com:8443', 'extended authority preserved';
        is $r->scheme, 'https', 'extended scheme preserved';
        is $r->version, $version, 'no version inferred from protocol';
        is $r->header_count, 2, 'pseudo-fields not inserted into headers';
        is $r->header('Priority'), 'u=1, i', 'priority remains an opaque field';
        ok $r->target_is_exact, 'extended path exact';
        is $r->protocol(undef), $r, 'protocol may be cleared';
        is $r->protocol, undef, 'protocol cleared';
        is $r->protocol($protocol), $r, 'protocol setter chainable';
        $r->freeze;
        is $r->version, $version, 'frozen neutral request need not be stamped by sender';
    }
}
my $r = Uniform::HTTP::Request->new(method => 'GET', target => '/');
for my $bad ('', [], 'two tokens', 'websocket/13', 'x,y', "x\r", "x\n", "x\0", "x\t", "x\x7f", "x\xff", chr(256)) {
    eval { $r->protocol($bad) };
    like $@, qr/protocol must be/, 'invalid token rejected';
    is $r->protocol, undef, 'failed token mutation atomic';
    eval { Uniform::HTTP::Request->new(method => 'CONNECT', target => '/', protocol => $bad) };
    like $@, qr/protocol must be/, 'constructor validates protocol';
}
eval { $r->protocol('x', 'y') };
like $@, qr/at most one/, 'protocol checks arity';
# Local construction can be incremental. Cross-field validity is a sender concern.
$r->protocol('future');
is $r->method, 'GET', 'protocol setter does not rewrite method';
is $r->scheme, undef, 'protocol setter does not invent scheme';
is $r->authority, undef, 'protocol setter does not invent authority';
$r->method('CONNECT');
is $r->protocol, 'future', 'method setter does not rewrite protocol';

for my $status (100 .. 199) {
    my $response = Uniform::HTTP::Response->new(status => $status);
    is $response->status, $status, 'informational status representable';
    ok $response->is_complete, 'individual informational message may be complete';
    is $response->reason, undef, 'no invented reason';
}
my @responses = map { Uniform::HTTP::Response->new(status => $_) } (100, 103, 200);
$responses[1]->add_header('Link', '</style.css>; rel=preload');
is $responses[2]->header_count, 0, 'separate responses do not share headers';
is $responses[0]->status, 100, 'final response does not mutate informational object';
done_testing;
