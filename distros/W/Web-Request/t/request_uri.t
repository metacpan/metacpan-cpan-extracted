#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use Web::Request;

my $app = sub {
    my $req = Web::Request->new_from_env(shift);
    return [ 200, [], [ $req->request_uri ] ];
};

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/foo%20bar");
    is $res->content, '/foo%20bar';

    $res = $cb->(GET "http://localhost:2020/FOO/bar,baz");
    is $res->content, '/FOO/bar,baz';
};

done_testing;
