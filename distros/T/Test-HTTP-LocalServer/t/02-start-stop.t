#!perl -w
use strict;
use warnings;
use Test::HTTP::LocalServer;
use LWP::Simple qw(get);

use Test::More tests => 2;

my $server = Test::HTTP::LocalServer->spawn;

my $pid = $server->{_pid};
my $res = kill 0, $pid;
is $res, 1, "PID $pid is an existing process";

$server->stop;

sleep 5; # just give it more time to be really sure

$res = kill 0, $pid;
is $res, 0, "PID $pid doesn't exist anymore";