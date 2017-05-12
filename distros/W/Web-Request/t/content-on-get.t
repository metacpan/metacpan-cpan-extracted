#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use Web::Request;

my $app = sub {
    my $req = Web::Request->new_from_env(shift);
    is $req->content, '';
    $req->new_response(status => 200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");
    ok $res->is_success or diag $res->content;

    $res = $cb->(HEAD "/");
    ok $res->is_success or diag $res->content;
};

done_testing;
