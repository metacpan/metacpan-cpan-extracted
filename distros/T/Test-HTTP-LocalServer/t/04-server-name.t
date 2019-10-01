#!perl -w
use strict;
use warnings;
use Test::HTTP::LocalServer;

use Test::More tests => 3;

my $server = Test::HTTP::LocalServer->spawn;

my $pid = $server->{_pid};
my $res = kill 0, $pid;
is $res, 1, "PID $pid is an existing process";

my $real_url = $server->url;

$server->server_url->host('example.com');

like $server->url, qr!^http://example\.com:!, "We can override the hostname";

# Except that this doesn't help us anyhow, but still ...

$server->server_url->host( $real_url->host );

$server->stop;

my $timeout = time + 5;

# just give it more time to be really sure
while ( time < $timeout ) {
    sleep 0.1;
    $res = kill 0, $pid;
    last if defined $res and $res == 0;
};

is $res, 0, "PID $pid doesn't exist anymore";
