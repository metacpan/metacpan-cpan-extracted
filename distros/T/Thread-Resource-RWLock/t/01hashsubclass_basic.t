use vars qw($loaded);

BEGIN { $| = 1; print "1..22\n"; }
END {print "not ok 1\n" unless $loaded;}

package LockedObject;

use threads;
use threads::shared;
use Thread::Queue::Queueable;
use Thread::Resource::RWLock;

use base qw(Thread::Queue::Queueable Thread::Resource::RWLock);

use strict;
use warnings;

sub new {
	my $class = shift;

	my %obj : shared = ();

	my $self = bless \%obj, $class;

	$self->{_value} = 0;
#
#	init the locking members
#
	return $self->Thread::Resource::RWLock::adorn();
}

sub increment {
	return ++$_[0]{_value};
}

sub decrement {
	return --$_[0]{_value};
}

sub getValue {
	return $_[0]{_value};
}

sub setValue {
	return $_[0]{_value} = $_[1];
}
#
#	TQQ method override
#
sub redeem {
	my ($class, $self);

	return bless $self, $class;
}

1;

package main;
use threads;
use threads::shared;
use Thread::Queue::Duplex;

use strict;
use warnings;

my $testtype = 'basic hash subclass, single threaded';

sub report_result {
	my ($testno, $result, $testmsg, $okmsg, $notokmsg) = @_;

	if ($result) {

		$okmsg = '' unless $okmsg;
		print STDOUT (($result eq 'skip') ?
			"ok $$testno # skip $testmsg for $testtype\n" :
			"ok $$testno # $testmsg $okmsg for $testtype\n");
	}
	else {
		$notokmsg = '' unless $notokmsg;
		print STDOUT
			"not ok $$testno # $testmsg $notokmsg for $testtype\n";
	}
	$$testno++;
}
#
#	prelims: use shared test count for eventual
#	threaded tests
#
my $testno : shared = 1;
$loaded = 1;

report_result(\$testno, 1, 'load');
#
#	in threaded app:
#
my $resource = LockedObject->new();

report_result(\$testno, $resource && $resource->isa('Thread::Resource::RWLock'),
	'subclass constructor');
#
#	Basic API test:
#		readlock once => verify timestamp result
my $firsttoken = $resource->read_lock();
report_result(\$testno, $firsttoken && ($firsttoken > 0), '1st readlock');

#		readlock again => verify -1 result
my $nexttoken = $resource->read_lock();
report_result(\$testno, $nexttoken && ($nexttoken < 0), '2nd readlock');

#		readlock again => verify -1 result
$nexttoken = $resource->read_lock();
report_result(\$testno, $nexttoken && ($nexttoken < 0), '2nd readlock');

#		writelock once => verify -1 result (upgrade)
$nexttoken = $resource->write_lock();
report_result(\$testno, $nexttoken && ($nexttoken < 0), 'writelock upgrade');

#		writelock again => verify -1 result
$nexttoken = $resource->write_lock();
report_result(\$testno, $nexttoken && ($nexttoken < 0), '2nd writelock');

#		readlock => verify -1 result
$nexttoken = $resource->read_lock();
report_result(\$testno, $nexttoken && ($nexttoken < 0), 'readlock downgrade');

#		readlock_nb => verify -1 result
$nexttoken = $resource->read_lock_nb();
report_result(\$testno, $nexttoken && ($nexttoken < 0), 'read_lock_nb');

#		readlock_timed => verify -1 result
$nexttoken = $resource->read_lock_timed(10);
report_result(\$testno, $nexttoken && ($nexttoken < 0), 'read_lock_timed');

#		writelock_nb => verify -1 result
$nexttoken = $resource->write_lock_nb();
report_result(\$testno, $nexttoken && ($nexttoken < 0), 'write_lock_nb upgrade');

#		readlock_nb => verify -1 result
$nexttoken = $resource->read_lock_nb();
report_result(\$testno, $nexttoken && ($nexttoken < 0), 'read_lock_nb downgrade');

#		writelock_timed => verify -1 result
$nexttoken = $resource->write_lock_timed(10);
report_result(\$testno, $nexttoken && ($nexttoken < 0), 'write_lock_timed upgrade');

#		readlock_timed => verify -1 result
$nexttoken = $resource->read_lock_timed(10);
report_result(\$testno, $nexttoken && ($nexttoken < 0), 'read_lock_timed downgrade');

#		unlock(-1) => verify undef result
report_result(\$testno, !$resource->unlock($nexttoken), 'unlock, bad token');

#		unlock($token) => verify 1 result
report_result(\$testno, $resource->unlock($firsttoken), 'unlock, good token');

#		readlock => verify timestamp result
$firsttoken = $resource->read_lock();
report_result(\$testno, $firsttoken && ($firsttoken > 0), 'new readlock');

#		unlock() => verify 1 result
report_result(\$testno, $resource->unlock(), 'unconditional unlock on locked');

#		unlock() => verify 1 result
report_result(\$testno, $resource->unlock(), 'unconditional unlock on unlocked');

#		writelock => verify timestamp result
$firsttoken = $resource->write_lock();
report_result(\$testno, $firsttoken && ($firsttoken > 0), 'new writelock');

#		unlock(-1) => verify undef result
report_result(\$testno, !$resource->unlock(-1), 'unlock, bad token');

#		unlock($token) => verify 1 result
report_result(\$testno, $resource->unlock($firsttoken), 'unlock, good token');
