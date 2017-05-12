#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use ZeroMQ::Poller::Timer;

my $t1 = ZeroMQ::Poller::Timer->new(
    name  => 'testfoo',
    after => 123,
);

ok $t1, 'Constructor returned something';

done_testing;
