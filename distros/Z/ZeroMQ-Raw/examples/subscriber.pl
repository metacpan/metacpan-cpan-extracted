#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';
use blib;

use ZeroMQ::Raw;
use ZeroMQ::Raw::Constants qw(ZMQ_SUB ZMQ_SUBSCRIBE);

my $c = ZeroMQ::Raw::Context->new(threads => 1);
my $s = ZeroMQ::Raw::Socket->new($c, ZMQ_SUB);
$s->connect('tcp://127.0.0.1:1234');
$s->setsockopt(ZMQ_SUBSCRIBE, 'debug:');

do {
    my $m = ZeroMQ::Raw::Message->new;
    $s->recv($m, 0);
    say $m->data;
} while (1);
