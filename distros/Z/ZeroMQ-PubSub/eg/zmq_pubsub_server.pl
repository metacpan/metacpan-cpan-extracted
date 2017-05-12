#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use ZeroMQ::PubSub::Server;

my $server = ZeroMQ::PubSub::Server->new(
    publish_addrs   => [ 'tcp://0.0.0.0:4000', 'ipc:///tmp/0mq_pub.sock' ],
    subscribe_addrs => [ 'tcp://0.0.0.0:4001', 'ipc:///tmp/0mq_sub.sock' ],
    debug           => 1,
);

$server->run;
