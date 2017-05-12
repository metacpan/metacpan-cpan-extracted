#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use Web::Request;

my ($content_before, $content_after);

my $app = sub {
    my $env = shift;

    my $req = Web::Request->new_from_env($env);
    $content_before = $req->content;

    # emulate other PSGI apps that reads from input, but not reset
    $env->{'psgi.input'}->read(my($dummy), $env->{CONTENT_LENGTH}, 0);

    $req = Web::Request->new_from_env($env);
    $content_after = $req->content;

    $req->new_response(status => 200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;

    my $req = HTTP::Request->new(POST => "/");
    $req->content("body");
    $req->content_type('text/plain');
    $req->content_length(4);
    my $res = $cb->($req);
    ok($res->is_success) || diag $res->content;
    is $content_before, "body";
    is $content_after, "body";
};

done_testing;

