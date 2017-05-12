#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use Data::Dumper;
use HTTP::Request::Common;
use Web::Request;

my $path_app = sub {
    my $req = Web::Request->new_from_env(shift);
    my $res = $req->new_response(status => 200);
    $res->content_type('text/plain');
    $res->content('my ' . Dumper([ $req->uri, $req->parameters ]));
    return $res->finalize;
};

test_psgi $path_app, sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/foo.bar-baz?a=b");
    is_deeply eval($res->content), [ URI->new("http://localhost/foo.bar-baz?a=b"), { a => 'b' } ];

    $res = $cb->(GET "http://localhost/foo%2fbar#ab");
    is_deeply eval($res->content), [ URI->new("http://localhost/foo/bar"), {} ],
        "%2f vs / can't be distinguished - that's alright";

    $res = $cb->(GET "http://localhost/%23foo?a=b");
    is_deeply eval($res->content), [ URI->new("http://localhost/%23foo?a=b"), { a => 'b' } ];
};

done_testing;
