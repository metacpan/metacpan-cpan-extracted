use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::Server;
use Unblock::HTTP1::_Native;
use Unblock::HTTP1::_Wire;

{
    package Unblock::HTTP1::TestRequest;

    sub new { bless { target => $_[1] }, $_[0] }
    sub method { 'GET' }
    sub target { $_[0]{target} }
    sub version { undef }
    sub protocol { undef }
    sub has_buffered_body { 0 }
    sub trailer_count { 0 }
    sub header_count { 1 }
    sub header_name { 'Host' }
    sub header_value { 'example.test' }
}

sub parse {
    return Unblock::HTTP1::_Native->parse_request_head($_[0]);
}

subtest 'received CONNECT request target and framing are strict' => sub {
    my $valid = parse(
        "CONNECT example.test:443 HTTP/1.1\r\n" .
        "Host: example.test:443\r\n\r\n"
    );
    ok($valid->{ok}, 'valid CONNECT authority-form is accepted');

    my $ipv6 = parse(
        "CONNECT [::1]:443 HTTP/1.1\r\n" .
        "Host: [::1]:443\r\n\r\n"
    );
    ok($ipv6->{ok}, 'bracketed IPv6 CONNECT authority is accepted');

    my $host_without_port = parse(
        "CONNECT example.test:443 HTTP/1.1\r\n" .
        "Host: example.test\r\n\r\n"
    );
    ok($host_without_port->{ok},
        'CONNECT Host may omit the port carried by authority-form');

    my $zero_length = parse(
        "CONNECT example.test:443 HTTP/1.1\r\n" .
        "Host: example.test:443\r\nContent-Length: 0\r\n\r\n"
    );
    ok($zero_length->{ok}, 'zero Content-Length CONNECT is accepted');
    is($zero_length->{body_mode}, 'none',
        'zero Content-Length CONNECT remains bodyless');

    my @bad = (
        [
            'origin-form CONNECT target',
            "CONNECT /bad HTTP/1.1\r\nHost: example.test:443\r\n\r\n",
        ],
        [
            'CONNECT Host mismatch',
            "CONNECT example.test:443 HTTP/1.1\r\nHost: other.test:443\r\n\r\n",
        ],
        [
            'CONNECT missing port',
            "CONNECT example.test HTTP/1.1\r\nHost: example.test\r\n\r\n",
        ],
        [
            'CONNECT zero port',
            "CONNECT example.test:0 HTTP/1.1\r\nHost: example.test:0\r\n\r\n",
        ],
        [
            'CONNECT oversized port',
            "CONNECT example.test:65536 HTTP/1.1\r\nHost: example.test:65536\r\n\r\n",
        ],
        [
            'CONNECT nonzero Content-Length',
            "CONNECT example.test:443 HTTP/1.1\r\n" .
            "Host: example.test:443\r\nContent-Length: 1\r\n\r\n",
        ],
        [
            'CONNECT Transfer-Encoding',
            "CONNECT example.test:443 HTTP/1.1\r\n" .
            "Host: example.test:443\r\nTransfer-Encoding: chunked\r\n\r\n",
        ],
        [
            'HTTP/1.0 CONNECT',
            "CONNECT example.test:443 HTTP/1.0\r\n" .
            "Host: example.test:443\r\n\r\n",
        ],
    );

    for my $case (@bad) {
        my ($name, $wire) = @$case;
        my $result = parse($wire);
        ok(!$result->{ok}, "$name is rejected");
        is($result->{status}, 400, "$name maps to 400");
    }
};

subtest 'outgoing CONNECT Host may omit authority port' => sub {
    my $request = Uniform::HTTP::Request->new(
        method  => 'CONNECT',
        target  => 'example.test:443',
        headers => [ [ Host => 'example.test' ] ],
    );

    my $plan = Unblock::HTTP1::_Wire::request_plan($request);
    like(
        $plan->{wire},
        qr/\ACONNECT example\.test:443 HTTP\/1\.1\r\nHost: example\.test\r\n/,
        'CONNECT serializes with Host that identifies the target host',
    );
};

subtest 'asterisk and basic request-target forms are validated' => sub {
    my $options = parse(
        "OPTIONS * HTTP/1.1\r\nHost: example.test\r\n\r\n"
    );
    ok($options->{ok}, 'OPTIONS asterisk-form is accepted');

    my $get_star = parse(
        "GET * HTTP/1.1\r\nHost: example.test\r\n\r\n"
    );
    ok(!$get_star->{ok}, 'asterisk-form is rejected for non-OPTIONS');

    my $relative = parse(
        "GET relative/path HTTP/1.1\r\nHost: example.test\r\n\r\n"
    );
    ok(!$relative->{ok}, 'relative request-target is rejected');

    my $fragment = parse(
        "GET /path#fragment HTTP/1.1\r\nHost: example.test\r\n\r\n"
    );
    ok(!$fragment->{ok}, 'fragment is rejected from origin-form');

    my $absolute = parse(
        "GET http://example.test/path?q=1 HTTP/1.1\r\n" .
        "Host: example.test\r\n\r\n"
    );
    ok($absolute->{ok}, 'absolute-form is accepted');

    my $userinfo = parse(
        "GET http://user\@example.test/path HTTP/1.1\r\n" .
        "Host: example.test\r\n\r\n"
    );
    ok(!$userinfo->{ok}, 'http absolute-form userinfo is rejected on receipt');

    my $missing_authority = parse(
        "GET http:path HTTP/1.1\r\nHost: \r\n\r\n"
    );
    ok(!$missing_authority->{ok},
        'http absolute-form without authority is rejected on receipt');

    my $empty_http_host = parse(
        "GET http://:80/path HTTP/1.1\r\nHost: :80\r\n\r\n"
    );
    ok(!$empty_http_host->{ok},
        'http absolute-form with an empty host identifier is rejected');
};

subtest 'outgoing request target uses the same form rules' => sub {
    my $options = Uniform::HTTP::Request->new(
        method  => 'OPTIONS',
        target  => '*',
        headers => [ [ Host => 'example.test' ] ],
    );
    like(
        Unblock::HTTP1::_Wire::request_plan($options)->{wire},
        qr/\AOPTIONS \* HTTP\/1\.1\r\n/,
        'OPTIONS asterisk-form serializes',
    );

    my @bad = (
        Uniform::HTTP::Request->new(
            method  => 'GET',
            target  => '*',
            headers => [ [ Host => 'example.test' ] ],
        ),
        Uniform::HTTP::Request->new(
            method  => 'GET',
            target  => 'relative/path',
            headers => [ [ Host => 'example.test' ] ],
        ),
        Uniform::HTTP::Request->new(
            method  => 'GET',
            target  => '/path#fragment',
            headers => [ [ Host => 'example.test' ] ],
        ),
    );

    for my $request (@bad) {
        my $ok = eval { Unblock::HTTP1::_Wire::request_plan($request); 1 };
        ok(!$ok, 'invalid outgoing request-target is rejected');
        like($@, qr/request target/i, 'outgoing target error is explicit');
    }

    my $absolute = Uniform::HTTP::Request->new(
        method  => 'GET',
        target  => 'http://example.test/path',
        headers => [ [ Host => 'example.test' ] ],
    );
    like(
        Unblock::HTTP1::_Wire::request_plan($absolute)->{wire},
        qr/\AGET http:\/\/example\.test\/path HTTP\/1\.1\r\n/,
        'absolute-form serializes unchanged',
    );

    my $absolute_empty_port = Uniform::HTTP::Request->new(
        method  => 'GET',
        target  => 'http://example.test:/path',
        headers => [ [ Host => 'example.test:' ] ],
    );
    like(
        Unblock::HTTP1::_Wire::request_plan($absolute_empty_port)->{wire},
        qr/\AGET http:\/\/example\.test:\/path HTTP\/1\.1\r\nHost: example\.test:\r\n/,
        'absolute-form permits an explicit empty port',
    );

    my $absolute_no_host = Uniform::HTTP::Request->new(
        method => 'GET',
        target => 'http://example.test/path',
    );
    like(
        Unblock::HTTP1::_Wire::request_plan($absolute_no_host)->{wire},
        qr/\r\nHost: example\.test\r\n/,
        'absolute-form synthesizes Host from request-target authority',
    );

    my $mismatch = Uniform::HTTP::Request->new(
        method  => 'GET',
        target  => 'http://example.test/path',
        headers => [ [ Host => 'other.test' ] ],
    );
    my $mismatch_ok = eval {
        Unblock::HTTP1::_Wire::request_plan($mismatch);
        1;
    };
    ok(!$mismatch_ok, 'absolute-form Host mismatch is rejected');
    like($@, qr/absolute-form Host must match/,
        'absolute-form mismatch error is explicit');

    my $userinfo = Uniform::HTTP::Request->new(
        method  => 'GET',
        target  => 'http://user\@example.test/path',
        headers => [ [ Host => 'example.test' ] ],
    );
    my $userinfo_ok = eval {
        Unblock::HTTP1::_Wire::request_plan($userinfo);
        1;
    };
    ok(!$userinfo_ok, 'http absolute-form userinfo is rejected');
    like($@, qr/must not contain userinfo/,
        'userinfo rejection is explicit');

    my $missing_authority_out = Uniform::HTTP::Request->new(
        method  => 'GET',
        target  => 'http:path',
        headers => [ [ Host => '' ] ],
    );
    my $missing_authority_ok = eval {
        Unblock::HTTP1::_Wire::request_plan($missing_authority_out);
        1;
    };
    ok(!$missing_authority_ok, 'outgoing http absolute-form requires authority');
    like($@, qr/requires an authority/,
        'missing authority error is explicit');

    my $bad_host = Uniform::HTTP::Request->new(
        method  => 'GET',
        target  => '/',
        headers => [ [ Host => 'bad host' ] ],
    );
    my $bad_host_ok = eval {
        Unblock::HTTP1::_Wire::request_plan($bad_host);
        1;
    };
    ok(!$bad_host_ok, 'outgoing invalid Host field is rejected');
    like($@, qr/invalid Host field/,
        'invalid Host error is explicit');

    my $space = Unblock::HTTP1::TestRequest->new('/bad path');
    my $space_ok = eval {
        Unblock::HTTP1::_Wire::request_plan($space);
        1;
    };
    ok(!$space_ok, 'outgoing request-target whitespace is rejected');
    like($@, qr/whitespace or control/,
        'request-target whitespace error is explicit');
};

done_testing;
