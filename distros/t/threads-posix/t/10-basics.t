#! perl
use strict;
use warnings;
use Config;

use threads::posix;
use Test::More tests => 9;

use POSIX qw/sigaction pause SIGQUIT SIGTERM SIGTSTP/;
use Time::HiRes qw/sleep/;
use Thread::Queue;
use Thread::Semaphore;

my $q = Thread::Queue->new();

sub expect {
	my $name = shift;
	my $left = $q->dequeue;
	my $right = $q->dequeue;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	ok($left, $right);
	is($right, $name, "Receive \"$name\"");
}

alarm 10;

### Start of Testing ###
ok(1, 'Loaded');

### Thread cancel ###

# Set up to capture warning when thread terminates
my @errs : shared;

$SIG{__WARN__} = sub { push(@errs, @_); };

sub thr_func {
	my $q = shift;

	# Thread 'cancellation' signal handler
	my $handler = sub {
		note("In signal handler");
		$q->enqueue(1, 'Thread received signal');
		die("Thread killed\n");
	};
	my $action = POSIX::SigAction->new($handler, undef, 0);
	$action->safe(1);
	sigaction(SIGQUIT, $action);
	note("In thread...");

	# Thread sleeps until signalled
	$q->enqueue(1, 'Thread sleeping');
	pause;
	# Should not go past here
	$q->enqueue(0, 'Thread terminated normally');
	return ('ERROR');
}

# Create thread
my $thr = threads::posix->create(\&thr_func, $q);
ok($thr, 'Created thread');
expect('Thread sleeping');

# Signal thread
sleep 0.5;
ok($thr->kill('QUIT') == $thr, 'Signalled thread');
expect('Thread received signal');

# Cleanup
my $rc = $thr->join();
ok(!$rc, 'No thread return value');

# Check for thread termination message
ok(@errs && $errs[0] =~ /Thread killed/, 'Thread termination warning');

