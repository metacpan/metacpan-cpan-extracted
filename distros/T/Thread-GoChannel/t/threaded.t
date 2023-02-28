#! perl

use strict;
use warnings;

use threads;

use Config;
use Test::More;
use Test::Fatal;
use Thread::GoChannel;

my $channel = Thread::GoChannel->new;
my $other = threads->new(sub {
	for my $i (0 .. 1000) {
		$channel->send($i);
	}
	for my $i (0 .. 100) {
		$channel->send([ ($i) x $i ]);
	}
});


for my $i (0 .. 1000) {
	is($channel->receive, $i, "Expected $i");
}
for my $i (0 .. 100) {
	is_deeply($channel->receive, [ ($i) x $i ], "Expected [ $i x $i ]");
}

$other->join;

done_testing;
