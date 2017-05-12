#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use ZeroMQ::Poller::Timer;

my $t1 = ZeroMQ::Poller::Timer->new(
    name     => 'testfoo',
    after    => 123,
    interval => 456,
);

ok 1, 'foo';

done_testing;
