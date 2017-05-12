#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use Web::Request;

my $app = sub {
    my $req = Web::Request->new_from_env(shift);
    is_deeply $req->body_parameters, { foo => 'bar' };
    is $req->content, 'foo=bar';
    $req->new_response(status => 200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(POST "/", { foo => "bar" });
    ok $res->is_success;
};

done_testing;
