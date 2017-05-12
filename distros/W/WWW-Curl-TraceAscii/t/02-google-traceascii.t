#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;

use WWW::Curl::TraceAscii;
my $response;
my $post = "some post data";
my $curl = WWW::Curl::TraceAscii->new; #<--- note this is using TraceAscii
$curl->setopt(CURLOPT_POST, 1);
$curl->setopt(CURLOPT_POSTFIELDS, $post);
$curl->setopt(CURLOPT_URL,'http://www.google.com/');
$curl->setopt(CURLOPT_WRITEDATA,\$response);
$curl->perform;

like  ($response, qr/<html.*/is, 'Testing that an HTML page was returned');

my $trace_ascii = eval{ $curl->trace_ascii };
like  ($$trace_ascii, qr/$post/, 'Testing that data was posted');

my $headers = eval{ $curl->trace_headers };
cmp_ok(scalar(@$headers), '>', 0, 'Testing header returned');
