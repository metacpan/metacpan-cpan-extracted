#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use ZeroMQ::Poller::Timer;

### Valid object ###

my $t1 = ZeroMQ::Poller::Timer->new(
    name     => 'testfoo',
    after    => 123,
    interval => 456,
);

is ref($t1), 'ZeroMQ::Poller::Timer', 'Correct object type';

my $name = $t1->{'name'};
ok $name, 'Has a name';

my $after = $t1->{'after'};
ok $after, 'Has an after timeout value';
like $after, qr/^\d+$/, 'After timeout is an integer';

my $interval = $t1->{'interval'};
ok $interval, 'Has an after timeout value';
like $interval, qr/^\d+$/, 'After timeout is an integer';

my $addr = $t1->{'_addr'};
ok $addr, 'Has a ZeroMQ inproc address';
is $addr, "inproc://$name", 'Correct ZeroMQ inproc address';

my $socket = $t1->{'_sock'};
ok $socket, 'Socket was created';
is ref($socket), 'ZeroMQ::Socket', 'Socket is the correct object type';

### Invalid object ###

my $t2 = ZeroMQ::Poller::Timer->new(test => 1);

ok ! $t2, 'Invalid object should be undefined';

done_testing;
