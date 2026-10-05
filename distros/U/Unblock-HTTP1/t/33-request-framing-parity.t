use strict;
use warnings;
use Test::More;

use Unblock::HTTP1::_Native;

sub parse {
    return Unblock::HTTP1::_Native->parse_request_head($_[0]);
}

subtest 'Content-Length normalization and conflict rules' => sub {
    my $same = parse(
        "POST / HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Content-Length: 7\r\n" .
        "Content-Length: 7\r\n\r\n"
    );
    ok($same->{ok}, 'identical duplicate Content-Length is accepted');
    is($same->{content_length}, 7, 'duplicate length is retained once semantically');

    my $combined = parse(
        "POST / HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Content-Length: 7, 7\r\n\r\n"
    );
    ok($combined->{ok}, 'identical comma-combined Content-Length is accepted');
    is($combined->{content_length}, 7, 'combined identical value is canonicalized');

    for my $wire (
        "Content-Length: 7\r\nContent-Length: 8\r\n",
        "Content-Length: 7, 8\r\n",
        "Content-Length: 184467440737095516160\r\n",
        "Content-Length: +7\r\n",
    ) {
        my $bad = parse(
            "POST / HTTP/1.1\r\nHost: example.test\r\n" .
            $wire . "\r\n"
        );
        ok(!$bad->{ok}, 'invalid Content-Length form is rejected');
        is($bad->{status}, 400, 'invalid Content-Length maps to 400');
    }
};

subtest 'Transfer-Encoding request rules are unambiguous' => sub {
    my $chunked = parse(
        "POST / HTTP/1.1\r\nHost: example.test\r\n" .
        "Transfer-Encoding: chunked\r\n\r\n"
    );
    ok($chunked->{ok}, 'single chunked transfer coding is accepted');
    is($chunked->{body_mode}, 'chunked', 'chunked selects chunk decoder');

    my @bad = (
        "Transfer-Encoding: chunked, gzip\r\n",
        "Transfer-Encoding: chunked, chunked\r\n",
        "Transfer-Encoding: chunked;foo=bar\r\n",
    );
    for my $field (@bad) {
        my $result = parse(
            "POST / HTTP/1.1\r\nHost: example.test\r\n" .
            $field . "\r\n"
        );
        ok(!$result->{ok}, 'invalid chunked ordering/form is rejected');
        is($result->{status}, 400, 'invalid chunked syntax maps to 400');
    }

    my $unsupported = parse(
        "POST / HTTP/1.1\r\nHost: example.test\r\n" .
        "Transfer-Encoding: gzip, chunked\r\n\r\n"
    );
    ok(!$unsupported->{ok}, 'unsupported transfer coding is rejected');
    is($unsupported->{status}, 501, 'unsupported transfer coding maps to 501');

    my $ambiguous = parse(
        "POST / HTTP/1.1\r\nHost: example.test\r\n" .
        "Transfer-Encoding: chunked\r\nContent-Length: 0\r\n\r\n"
    );
    ok(!$ambiguous->{ok}, 'Transfer-Encoding plus Content-Length is rejected');
    is($ambiguous->{status}, 400, 'TE plus CL maps to 400');
};

subtest 'Host and persistence rules' => sub {
    my $missing = parse("GET / HTTP/1.1\r\n\r\n");
    ok(!$missing->{ok}, 'HTTP/1.1 missing Host is rejected');
    is($missing->{status}, 400, 'missing Host maps to 400');

    my $duplicate = parse(
        "GET / HTTP/1.1\r\nHost: one.test\r\nHost: two.test\r\n\r\n"
    );
    ok(!$duplicate->{ok}, 'multiple Host fields are rejected');

    my $space = parse(
        "GET / HTTP/1.1\r\nHost: bad host\r\n\r\n"
    );
    ok(!$space->{ok}, 'Host containing whitespace is rejected');

    my $ipv6 = parse(
        "GET / HTTP/1.1\r\nHost: [::1]:8080\r\n\r\n"
    );
    ok($ipv6->{ok}, 'bracketed IPv6 Host is accepted');

    my $empty_port = parse(
        "GET / HTTP/1.1\r\nHost: example.test:\r\n\r\n"
    );
    ok($empty_port->{ok}, 'Host with explicit empty port is accepted');

    my $close = parse(
        "GET / HTTP/1.1\r\nHost: example.test\r\nConnection: close\r\n\r\n"
    );
    ok(!$close->{keep_alive}, 'HTTP/1.1 Connection close disables persistence');

    my $http10 = parse("GET / HTTP/1.0\r\n\r\n");
    ok($http10->{ok}, 'HTTP/1.0 request may omit Host');
    ok(!$http10->{keep_alive}, 'HTTP/1.0 closes by default');

    my $http10_keep = parse(
        "GET / HTTP/1.0\r\nConnection: keep-alive\r\n\r\n"
    );
    ok($http10_keep->{keep_alive}, 'HTTP/1.0 keep-alive option enables persistence');
};

subtest 'obsolete folding is rejected and higher HTTP/1 minors interoperate' => sub {
    my $folded = parse(
        "GET / HTTP/1.1\r\nHost: example.test\r\n" .
        "X-Test: one\r\n two\r\n\r\n"
    );
    ok(!$folded->{ok}, 'obsolete folded field is rejected');
    is($folded->{status}, 400, 'obs-fold maps to 400');

    my $version = parse(
        "GET / HTTP/1.9\r\nHost: example.test\r\n\r\n"
    );
    ok($version->{ok}, 'higher HTTP/1 minor version is accepted');
    is($version->{version}, '1.9', 'actual received minor version is retained');
    ok($version->{keep_alive},
        'higher HTTP/1 minor uses HTTP/1.1 persistence semantics');

    my $missing_host = parse("GET / HTTP/1.9\r\n\r\n");
    ok(!$missing_host->{ok},
        'higher HTTP/1 minor still uses HTTP/1.1 Host requirements');
    is($missing_host->{status}, 400, 'missing Host remains a request error');
};

done_testing;
