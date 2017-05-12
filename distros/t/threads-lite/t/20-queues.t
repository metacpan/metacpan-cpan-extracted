#!perl 

use strict;
use warnings;
use experimental 'smartmatch';

use Test::More tests => 4;
use Test::Differences;
use threads::lite qw/spawn receive/;

my $thread = spawn({ monitor => 1 }, sub {
	require Time::HiRes;
	my (undef, $queue) = threads::lite::receiveq('queue', qr//);
	$queue->enqueue(qw/foo bar baz/);
	$queue->enqueue(qw/1 2 3/);
	1;
	});

alarm 5;

my $queue = threads::lite::queue->new;
$thread->send('queue', $queue);

my @first = $queue->dequeue;
my @second = $queue->dequeue;
my @third = $queue->dequeue_nb;

eq_or_diff \@first, [ qw/foo bar baz/ ], 'first entry is right';
eq_or_diff \@second, [ qw/1 2 3/ ], 'Second entry is right';
is @third, 0, 'Third message was empty';

receive {
	when([ 'exit', 'normal', $thread->id, 1 ]) {
		eq_or_diff $_, [ 'exit', 'normal', $thread->id, 1 ], 'thread returned normally';
	}
	default {
		ok(0, 'thread returned normally');
	}
};
