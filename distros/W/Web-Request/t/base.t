#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Web::Request;

my @tests = (
  { host => 'localhost',
    base => 'http://localhost/' },
  { script_name => '/foo',
    host => 'localhost',
    base => 'http://localhost/foo' },
  { script_name => '/foo bar',
    host => 'localhost',
    base => 'http://localhost/foo%20bar' },
  { scheme => 'http',
    host => 'localhost:91',
    base => 'http://localhost:91/' },
  { scheme => 'http',
    host => 'example.com',
    base => 'http://example.com/' },
  { scheme => 'https',
    host => 'example.com',
    base => 'https://example.com/' },
  { scheme => 'http',
    server_name => 'example.com',
    server_port => 80,
    base => 'http://example.com/',
    expected_host => 'example.com:80' },
  { scheme => 'http',
    server_name => 'example.com',
    server_port => 8080,
    base => 'http://example.com:8080/',
    expected_host => 'example.com:8080' },
  { host => 'foobar.com',
    server_name => 'example.com',
    server_port => 8080,
    base => 'http://foobar.com/' },
);

for my $block (@tests) {
    my $env = {
        'psgi.url_scheme' => $block->{scheme} || 'http',
        HTTP_HOST => $block->{host} || undef,
        SERVER_NAME => $block->{server_name} || undef,
        SERVER_PORT => $block->{server_port} || undef,
        SCRIPT_NAME => $block->{script_name} || '',
    };

    my $req = Web::Request->new_from_env($env);
    is $req->base_uri, $block->{base};
    my $expected_host = $block->{expected_host} || $block->{host};
    is $req->host, $expected_host;
}

done_testing;
