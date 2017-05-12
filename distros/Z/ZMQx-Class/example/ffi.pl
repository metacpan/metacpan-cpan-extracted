#!/usr/bin/env perl

use 5.014;
use ZMQ::FFI;


use ZMQ::FFI::Constants qw(ZMQ_SUB ZMQ_DONTWAIT);
use Time::HiRes q(usleep);
use AnyEvent;
use EV;

my $endpoint = "tcp://localhost:10000";
my $ctx      = ZMQ::FFI->new();

my $s = $ctx->socket(ZMQ_SUB);

$s->connect($endpoint);
$s->subscribe('');

my $fd = $s->get_fd();

my $watcher = AnyEvent->io(
    fh   => $fd,
    poll => "r",
    cb   => sub {
        while ( $s->has_pollin ) {
            say $s->recv_multipart();
        }
    }
);

AnyEvent->condvar->recv;



