#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use Web::Response;

my $res = Web::Response->new(status => 200);
$res->content("hello");

test_psgi $res->to_app, sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->code, 200, 'response code';
    is $res->content, 'hello', 'content';
};

done_testing;
