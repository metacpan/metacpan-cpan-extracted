#!/usr/bin/env perl
use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use Web::Request;

$Plack::Test::Impl = 'Server';
local $ENV{PLACK_SERVER} = "HTTP::Server::PSGI";

my $app = sub {
    my $req = Web::Request->new_from_env(shift);
    return [200, [], [ $req->uri ]];
};

test_psgi app => $app, client => sub {
    my $cb = shift;
    my $res = $cb->(GET "http://localhost/foo");
    ok $res->content !~ /:\d+:\d+/;
};

done_testing;


