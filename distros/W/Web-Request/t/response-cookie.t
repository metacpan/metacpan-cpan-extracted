#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use Web::Response;

my $app = sub {
    my $res = Web::Response->new([200]);

    $res->cookies->{t1} = { value => "bar", domain => '.example.com', path => '/cgi-bin' };
    $res->cookies->{t2} = { value => "xxx yyy", expires => time + 3600 };
    $res->cookies->{t3} = { value => "123123", "max-age" => 15 };
    $res->finalize;
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");

    my @v = sort $res->header('Set-Cookie');
    is $v[0], "t1=bar; domain=.example.com; path=/cgi-bin";
    like $v[1], qr/t2=xxx%20yyy; expires=\w+, \d+-\w+-\d+ \d\d:\d\d:\d\d GMT/;
    is $v[2], "t3=123123; max-age=15";
};

done_testing;
