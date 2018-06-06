#!perl -w
use strict;
use warnings;
use LWP::Simple qw(get);
use Test::HTTP::LocalServer;

use Test::More tests => 4;

my $server = Test::HTTP::LocalServer->spawn(
#    debug => 1
);

my $pid = $server->{_pid};
my $res = kill 0, $pid;
is $res, 1, "PID $pid is an existing process";

ok get $server->url, "Retrieve " . $server->url;

my @log = $server->get_log;

cmp_ok 0+@log, '>', 0, "We have some lines in the log file";

$server->stop;

sleep 5; # just give it more time to be really sure

$res = kill 0, $pid;
is $res, 0, "PID $pid doesn't exist anymore";
