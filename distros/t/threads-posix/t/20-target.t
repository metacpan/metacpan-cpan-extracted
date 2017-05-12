#! perl
use strict;
use warnings;

use threads::posix;
use Test::More tests => 1;

use POSIX qw/sigsuspend SIGUSR1 SIG_BLOCK/;
use Thread::SigMask qw/sigmask/;
use Thread::Semaphore;

alarm 2;

$SIG{USR1} = sub {
	fail("Shouldn't receive signal in main thread");
};

sub child {
	$SIG{USR1} = sub {
		pass("Received ARLM");
	};
	sigsuspend(POSIX::SigSet->new());
}

sigmask(SIG_BLOCK, POSIX::SigSet->new(SIGUSR1));
my $child = threads::posix->create(\&child);
kill(SIGUSR1, $$);
$child->join;

