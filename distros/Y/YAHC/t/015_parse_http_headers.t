#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use YAHC;

my $CRLF = "\x0d\x0a";

my @test_cases = (
    [
        join($CRLF,
            'HTTP/1.1 200 OK',
            'Date: Sat, 23 Nov 2013 23:10:28 GMT',
            'Last-Modified: Sat, 26 Oct 2013 19:41:47 GMT',
            'ETag: "4b9d0211dd8a2819866bccff777af225"',
            'Content-Type: text/html',
            'Server: Example',
            'Content-Length: 4'
        ),
        {
            "Date" => "Sat, 23 Nov 2013 23:10:28 GMT",
            "Last-Modified" => "Sat, 26 Oct 2013 19:41:47 GMT",
            "ETag" => '"4b9d0211dd8a2819866bccff777af225"',
            "Content-Type" => "text/html",
            "Content-Length" => "4",
            "Server" => "Example",
        },
    ]
);

is_deeply( YAHC::_parse_http_headers({}, $_->[0]), $_->[1])
    foreach @test_cases;

done_testing;
