#!perl 

use strict;
use warnings;
use experimental 'smartmatch';

use Test::More tests => 6;
use Test::Differences;

use threads::lite qw/spawn receive self/;

my $thread = spawn({ modules => ['Carp', 'Time::HiRes'], monitor => 1 }, \&thread );

$thread->send(self());

sub thread {
	my $other = threads::lite::receiveq;
	Time::HiRes::sleep(.1);
	$other->send('foo');
	$other->send('bar');
	$other->send('something else');
	return 42;
}

ok(1, 'Created thread');

alarm 5;

my $state = 0;
for (1 .. 3) {
	receive {
		when ([ 'exit', 'normal', $thread->id, 42]) {
			eq_or_diff $_, [ 'exit', 'normal', $thread->id, 42], "Got return value 42";
			is $state++, 1, 'State is now 1';
		};
		when (['exit', 'error']) {
			ok(0, 'Got return value 42');
			is $state++, 1, 'State is now 1';
		};
		when (['bar']) {
			is $state++, 0, 'Received bar';
			receive {
				when (['bar']) {
					fail 'Should match foo after bar';
					diag('Matched bar instead')
				}
				when (['foo']) {
					pass 'Should match foo after bar';
				}
			};
		}
		default {
			continue if $_->[0] eq 'foo';
			is $_->[0], 'something else', '$_ is "something else"';
		}
	};
}
