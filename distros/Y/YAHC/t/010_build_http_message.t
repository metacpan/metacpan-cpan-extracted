#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use YAHC;

my $CRLF = "\x0d\x0a";

sub _build_conn_object {
    my $args = shift;
    my $host = delete $args->{host};
    return {
        request => $args,
        selected_target => [ $host ],
    };
}

for my $protocol ("HTTP/1.0", "HTTP/1.1") {
    is YAHC::_build_http_message(_build_conn_object({ protocol => $protocol, host => "www.example.com" })),
        "GET / $protocol${CRLF}".
        "Host: www.example.com${CRLF}".
        "${CRLF}";

    is YAHC::_build_http_message(_build_conn_object({ protocol => $protocol, host => "example.com" })),
        "GET / $protocol${CRLF}".
        "Host: example.com${CRLF}".
        "${CRLF}";

    is YAHC::_build_http_message(_build_conn_object({ method => "HEAD", protocol => $protocol, host => "example.com" })),
        "HEAD / $protocol${CRLF}".
        "Host: example.com${CRLF}".
        "${CRLF}";

    is YAHC::_build_http_message(_build_conn_object({ protocol => $protocol, host => "www.example.com", port => "8080" })),
        "GET / $protocol${CRLF}".
        "Host: www.example.com${CRLF}".
        "${CRLF}";

    is YAHC::_build_http_message(_build_conn_object({ protocol => $protocol, host => "www.example.com", query_string => "a=b" })),
        "GET /?a=b $protocol${CRLF}".
        "Host: www.example.com${CRLF}".
        "${CRLF}";

    is YAHC::_build_http_message(_build_conn_object({ protocol => $protocol, host => "www.example.com", path => "/flower" })),
        "GET /flower $protocol${CRLF}".
        "Host: www.example.com${CRLF}".
        "${CRLF}";

    is YAHC::_build_http_message(_build_conn_object({ protocol => $protocol, host => "www.example.com", path => "/flower", query_string => "a=b" })),
        "GET /flower?a=b $protocol${CRLF}".
        "Host: www.example.com${CRLF}".
        "${CRLF}";

    is YAHC::_build_http_message(_build_conn_object({ protocol => $protocol, host => "www.example.com", body => "morning" })),
        "GET / $protocol${CRLF}".
        "Content-Length: 7${CRLF}".
        "Host: www.example.com${CRLF}".
        "${CRLF}".
        "morning";

    is YAHC::_build_http_message(_build_conn_object({ protocol => $protocol, host => "www.example.com", body => "0" })),
        "GET / $protocol${CRLF}".
        "Content-Length: 1${CRLF}".
        "Host: www.example.com${CRLF}".
        "${CRLF}".
        "0";

    is YAHC::_build_http_message(_build_conn_object({ protocol => $protocol, host => "www.example.com", body => undef })),
        "GET / $protocol${CRLF}".
        "Host: www.example.com${CRLF}".
        "${CRLF}";

    is YAHC::_build_http_message(_build_conn_object({ protocol => $protocol, host => "www.example.com", body => "" })),
        "GET / $protocol${CRLF}".
        "Content-Length: 0${CRLF}".
        "Host: www.example.com${CRLF}".
        "${CRLF}";

    is YAHC::_build_http_message(_build_conn_object({ protocol => $protocol, host => "www.example.com", head => undef, body => "OHAI" })),
        "GET / $protocol${CRLF}".
        "Content-Length: 4${CRLF}".
        "Host: www.example.com${CRLF}".
        "${CRLF}".
        "OHAI";

    is YAHC::_build_http_message(_build_conn_object({ protocol => $protocol, host => "www.example.com", head => [], body => "OHAI" })),
        "GET / $protocol${CRLF}".
        "Content-Length: 4${CRLF}".
        "Host: www.example.com${CRLF}".
        "${CRLF}".
        "OHAI";

    is YAHC::_build_http_message(_build_conn_object({ protocol => $protocol, host => "www.example.com", head => ["X-Head" => "extra stuff"] })),
        "GET / $protocol${CRLF}".
        "X-Head: extra stuff${CRLF}".
        "Host: www.example.com${CRLF}".
        "${CRLF}";

    is YAHC::_build_http_message(_build_conn_object({ protocol => $protocol, host => "www.example.com", head => ["X-Head" => "extra stuff", "X-Hat" => "ditto"] })),
        "GET / $protocol${CRLF}".
        "X-Head: extra stuff${CRLF}".
        "X-Hat: ditto${CRLF}".
        "Host: www.example.com${CRLF}".
        "${CRLF}";

    is YAHC::_build_http_message(_build_conn_object({ protocol => $protocol, host => "www.example.com", head => ["X-Head" => "extra stuff"], body => "OHAI" })),
        "GET / $protocol${CRLF}".
        "Content-Length: 4${CRLF}".
        "X-Head: extra stuff${CRLF}".
        "Host: www.example.com${CRLF}".
        "${CRLF}".
        "OHAI";
}

done_testing;
