#! perl

use strict;
use warnings FATAL => 'all';

use Config;
use Test::More $Config{useithreads} ? () : (skip_all => 'No threads available');
use Test::Fatal;
use threads;
use Thread::Channel;

my $channel = Thread::Channel->new;
my $other = threads->new(sub {
	for my $i (0 .. 1000) {
		$channel->enqueue($i);
	}
	for my $i (0 .. 100) {
		$channel->enqueue([ ($i) x $i ]);
	}
});


for my $i (0 .. 1000) {
	is($channel->dequeue, $i, "Expected $i");
}
for my $i (0 .. 100) {
	is_deeply($channel->dequeue, [ ($i) x $i ], "Expected [ $i x $i ]");
}

$other->join;

done_testing;
