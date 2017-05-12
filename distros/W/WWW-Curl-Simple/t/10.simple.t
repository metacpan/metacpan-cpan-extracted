#!/usr/bin/perl -w

use strict;
use Test::More;
use WWW::Curl::Simple;
BEGIN {
    eval "use Net::Server::Single";
    plan skip_all => 'Net::Server::Single is required for this test' if $@;
}

use t::Testserver;
my $port = int(rand(1024) + 1024);

my $pid = fork();

if (not defined $pid) {
    plan skip_all => "Fork not supported";
} elsif ($pid == 0) {
    ## In the child, do requests here?
    plan tests => 2;

    sleep(1);

    my $curl = WWW::Curl::Simple->new(timeout => 1);
    is($curl->timeout, 1);
    my $res = $curl->request(HTTP::Request->new(GET => 'http://localhost:' . $port));

    is($res->content, "OK");
} else {
    ## in the parent
    my $serv = TestServer->new({ port => $port, log_level => 0 });

    $serv->run;


    waitpid($pid, 0);
}
