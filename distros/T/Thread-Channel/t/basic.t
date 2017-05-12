#! perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Fatal;
use Thread::Channel;

my $channel = Thread::Channel->new;

ok($channel, 'Channel defined');

is(ref($channel), 'Thread::Channel', 'Channel is a Thread::Channel');

is(exception { $channel->enqueue('test') }, undef, 'Can enqueue');

my $ret;
is(exception { $ret = $channel->dequeue }, undef, 'Can dequeue');

is($ret, 'test', 'Dequeued \'test\'');

is(exception { $ret = $channel->dequeue_nb }, undef, 'Can dequeue nonblockingly');

is($ret, undef, 'Dequeued nothing');

done_testing;
