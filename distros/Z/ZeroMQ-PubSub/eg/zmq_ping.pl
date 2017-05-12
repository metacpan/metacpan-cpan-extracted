#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use ZeroMQ::PubSub::Client;
use Time::HiRes;

my $client = ZeroMQ::PubSub::Client->new(
    publish_address   => 'tcp://127.0.0.1:4000',
    subscribe_address => 'tcp://127.0.0.1:5000',
    debug             => 1,
);

my $ping_start_time;

# called when we receive our ping back
$client->subscribe(ping => sub {
    print "Ping time: " . (Time::HiRes::time() - $ping_start_time) . "s.\n";
});

$ping_start_time = Time::HiRes::time();

# publish ping event
$client->publish(ping => { 'time' => $ping_start_time });

# wait to receive our ping
$client->poll_once;

