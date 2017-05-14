#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';
use blib;

use ZeroMQ::Raw;
use ZeroMQ::Raw::Constants qw(ZMQ_PUB);

my $c = ZeroMQ::Raw::Context->new(threads => 1);
my $s = ZeroMQ::Raw::Socket->new($c, ZMQ_PUB);
$s->bind('tcp://lo:1234');

my $i = 0;
while(1){
    my $str = "debug: message $i";
    my $m = ZeroMQ::Raw::Message->new_from_scalar($str);
    $s->send($m, 0);
    say $str;
    $i++;
    sleep 1;
}
