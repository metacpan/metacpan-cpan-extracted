=head1 NAME

Thread::Resource::RWLock - read/write lock base class for Perl ithreads

=head1 SYNOPSIS

	package LockedObject;

	use threads;
	use threads::shared;
	use Thread::Queue::Queueable;
	use Thread::Resource::RWLock;

	use base qw(Thread::Queue::Queueable Thread::Resource::RWLock);

	sub new {
		my $class = shift;

		my %obj : shared = ();

		my $self = bless \%obj, $class;
	#
	#	init the locking members
	#
		$self->Thread::Resource::RWLock::adorn();
		return $self;
	}

	sub redeem {
		my ($class, $self);

		return bless $self, $class;
	}

	package main;
	use threads;
	use threads::shared;
	use Thread::Queue::Duplex;
	use LockedObject;
	#
	#	in threaded app:
	#
	my $read_write = LockedObject->new();
	my $tqd = Thread::Queue::Duplex->new();
	my $thrdA = threads->new(\&read_thread, $tqd);
	my $thrdB = threads->new(\&write_thread, $tqd);
	#
	# pass the shared object to each thread
	#
	$tqd->enqueue_and_wait($read_write);
	$tqd->enqueue_and_wait($read_write);

	# Reader
	sub read_thread {
		my $tqd = shift;
		my $request = $tqd->dequeue();
		$tqd->respond($request->[0], 1);
		my $obj = $request->[1];

		my $locktoken = $obj->read_lock();
	#
	#	do some stuff
	#
		$obj->unlock($locktoken);
	}

	# Writer
	sub write_thread {
		my $tqd = shift;
		my $request = $tqd->dequeue();
		$tqd->respond($request->[0], 1);
		my $obj = $request->[1];
	#
	#	first grab a readlock
	#
		my $locktoken = $obj->read_lock();
	#
	#	do some stuff, then upgrade to a writelock
	#
		$obj->write_lock();
	#
	#	do some stuff, then unlock
	#
		$obj->unlock($locktoken);
	}

=head1 DESCRIPTION

Thread::Resource::RWLock provides both an inheritable abstract class,
as well as a concrete object implementation, to regulate concurrent
access to resources.
Multiple concurrent reader threads may hold a Thread::Resource::RWLock
readlock at the same time, while a single writer thread holds the lock
exclusively.

New reader threads are blocked if any writer is currently waiting to
obtain the lock. The read lock is granted after all pending write lock
requests have been released.

Thread::Resource::RWLock accomodates a thread which already holds
a lock and then requests another lock on the resource, as follows:

=over 4

=item B<no lock held, requests readlock>

Lock is granted when any pending writelock requests
are applied, and then released. Returned value is a unique
locktoken value.

=item B<no lock held, requests writelock>

Lock is granted when any current readlocks
are released. If multiple writelock requests are pending,
the writelock will be granted in a random fashion.
Returned value is a unique locktoken value.

=item B<holds readlock, requests readlock>

The lock level remains the same, but the returned value
is -1, indicating a lock was already held.

=item B<holds readlock, requests writelock>

The lock level is upgraded to write when all other
readers have unlocked, and the returned value
is -1, indicating a lock was already held.

=item B<holds writelock, requests readlock>

The lock level is downgraded to read, regardless
if any other writelock requests are pending.
The returned value is -1, indicating a lock was
already held.

=item B<holds writelock, requests writelock>

The lock level remains the same, but the returned value
is -1, indicating a lock was already held.

=back

In addition, both nonblocking and timed interfaces are
provided to permit acquiring a lock only if the lock can be granted
immediately, or within a specified number of seconds. If the lock
is B<not> granted, the returned value is C<undef>.

This implementation provides 2 constructors:
the usual C<new()> method which constructs a shared object instance,
suitable for use as a member of a shared object,
and an C<adorn()> method for classes which subclass Thread::Resource::RWLock.

Finally, note that this implementation supports both array and hash
based objects. I<Array-based subclasses should reserve the first 4 entries
in their array for the Thread::Resource::RWLock member variables.>

=head3 Locks Do Not Accumulate

The application is responsible for tracking and preserving lock consistency
when it repeatedly requests locks on a resource for which it already
holds locks. In support of this, Thread::Resource::RWLock's lock methods
return a positive locktoken value when the lock is initially granted
(the timestamp returned by L<Time::HiRes>::time()), and returns -1 when a
thread is granted a lock on a resource on which it already holds a lock.

The C<unlock()> method takes a single (optional) C<$locktoken> parameter.
If the $locktoken matches the locktoken returned when the thread was originally
locked, then the lock will be released; otherwise, the C<unlock()> is ignored,
and the lock will continue to be held. If no C<$locktoken> parameter is provided,
then the unlock is applied unconditionally.

=cut

package Thread::Resource::RWLock;

BEGIN {
	use Config;
	die 'Thread::Resource::RWLock: Your Perl was not built with ithreads, exitting...'
		unless $Config{useithreads};
};

use threads;
use threads::shared;
use Time::HiRes qw(time);

use strict;
use warnings;

our $VERSION = '2.01';

=head1 METHODS

=over 8

=item adorn

Adorns the input resource object with Thread::Resource::RWLock object
member variables in an unlocked state.

=cut

sub adorn {
    my $self = shift;
#
#	we should verify $self is shared!
#
	return Thread::Resource::RWLock::Array::adorn($self)
		unless $self->isa('HASH');

	my %lockers : shared = ();

    $self->{_trw_readers} = 0;			# current number of readlocks
    $self->{_trw_lockmap} = \%lockers;	# maps TIDs to locktokens
    $self->{_trw_writer} = undef;		# TID of writelock holder
    $self->{_trw_pending} = 0;			# count of pending writelock requestors
    return $self;
}

=item new

Creates a new concrete instance of an unlocked Thread::Resource::RWLock object.

=cut

#
#	as a concrete class, we always use array based object
#	for performance
#
sub new {
	return Thread::Resource::RWLock::Array->new();
}

=item I<$locktoken> = I<$resource-E<gt>>B<read_lock()>

Requests a read lock. If another thread currently
holds a writelock on the resource, C<read_lock> blocks
until all pending writelock requests have been released.
If the requesting thread holds a writelock on the resource,
the lock is downgraded to a readlock, without granting the writelock
to any pending requestors. Returned value is L<Time::HiRes>::time()
if the requestor did not already hold a lock on the resource, or -1
if it did.

=cut

sub _cmn_read_lock {
	my ($self, $tid) = @_;
#
#	check if we're downgrading
#
	delete $self->{_trw_writer},
    $self->{_trw_readers}++
		if (defined($self->{_trw_writer}) &&
			($self->{_trw_writer} == $tid));
#
#	only return timestamp if we don't hold the lock
#
	return -1
		if $self->{_trw_lockmap}{$tid};

    $self->{_trw_lockmap}{$tid} = time();
    $self->{_trw_readers}++;
    return $self->{_trw_lockmap}{$tid};
}

sub read_lock {
    my $self = shift;

	my $tid = threads->self()->tid();

	lock($self);
#
#	check for pending writers, or if we're the writer
#
	cond_wait $self
		until (($self->{_trw_pending} == 0) && (!defined($self->{_trw_writer}))) ||
			(defined($self->{_trw_writer}) && ($self->{_trw_writer} == $tid));

	return $self->_cmn_read_lock($tid);
}

=item I<$locktoken> = I<$resource-E<gt>>B<read_lock_nb()>

Same as C<read_lock()>, except it returns immediately without
granting the readlock if the resource is currently writelocked by another
thread. Returns C<undef> if the lock cannot be granted immediately,
L<Time::HiRes>::time() if the lock is granted and the requestor did not
already hold a lock on the resource, or -1 if it did hold a lock.

=cut

sub read_lock_nb {
    my $self = shift;

	my $tid = threads->self()->tid();

	lock($self);

    return undef
		unless (($self->{_trw_pending} == 0) && (!defined($self->{_trw_writer}))) ||
			(defined($self->{_trw_writer}) && ($self->{_trw_writer} == $tid));

	return $self->_cmn_read_lock($tid);
}

=item I<$locktoken> = I<$resource-E<gt>>B<read_lock_timed> I<($timeout)>

Same as C<read_lock()>, except it returns C<undef> if the readlock is
not granted within C<$timeout> seconds.
Returns L<Time::HiRes>::time() if the lock is granted and the requestor did not
already hold a lock on the resource, or -1 if it did.

=cut

sub read_lock_timed {
    my ($self, $timeout) = shift;

	my $tid = threads->self()->tid();

	$timeout += time();

	lock($self);

    cond_timedwait($self, $timeout)
    	until ($timeout < time()) ||
			(($self->{_trw_pending} == 0) && (!defined($self->{_trw_writer}))) ||
			(defined($self->{_trw_writer}) && ($self->{_trw_writer} == $tid));

	return undef
		unless (($self->{_trw_pending} == 0) && (!defined($self->{_trw_writer}))) ||
			(defined($self->{_trw_writer}) && ($self->{_trw_writer} == $tid));

	return $self->_cmn_read_lock($tid);
}

=item I<$locktoken> = I<$resource-E<gt>>B<write_lock()>

Requests a writelock on the resource. Writelocks are exclusive, so no
other readers or writers are granted access until the writelock is released.
Note that a thread may be granted the writelock if the
resource is currently only readlocked by the requesting thread
(i.e., the thread is requesting a lock upgrade).
C<write_lock()> blocks until the lock is available.
Returns L<Time::HiRes>::time() if the lock is granted and the requestor did not
already hold a lock on the resource, or -1 if it did hold a lock.

=cut

sub _cmn_write_lock {
	my ($self, $tid) = @_;

	$self->{_trw_writer} = $tid;
#
#	check for upgrade
#
	$self->{_trw_readers}--,
	return -1
		if $self->{_trw_readers};

	$self->{_trw_lockmap}{$tid} = time();
    return $self->{_trw_lockmap}{$tid};
}

sub write_lock {
    my $self = shift;

	my $tid = threads->self()->tid();

	lock($self);
#
#	return immediately if we're already the writer
#
	return -1
   		if (defined($self->{_trw_writer}) && ($self->{_trw_writer} == $tid));
#
#	if we're one of the readers, wait til we're the last one
#
	$self->{_trw_pending}++;

    cond_wait $self
    	until (($self->{_trw_lockmap}{$tid} && ($self->{_trw_readers} == 1))) ||
    		(($self->{_trw_readers} == 0) && (!defined($self->{_trw_writer})));

	$self->{_trw_pending}--;
	return $self->_cmn_write_lock($tid);
}

=item I<$locktoken> = I<$resource-E<gt>>B<write_lock_nb()>

Same as C<write_lock()>, but returns C<undef> immediately if the
writelock cannot be granted (i.e., another thread holds
a read or write lock on the resource).
Returns L<Time::HiRes>::time() if the lock is granted and the requestor did not
already hold a lock on the resource, or -1 if it did hold a lock.

=cut

sub write_lock_nb {
    my $self = shift;

	my $tid = threads->self()->tid();

	lock($self);
#
#	return immediately if we're already the writer
#
	return -1
   		if (defined($self->{_trw_writer}) && ($self->{_trw_writer} == $tid));
#
#	if we're one of the readers, wait til we're the last one
#
    return undef
    	unless (($self->{_trw_lockmap}{$tid} && ($self->{_trw_readers} == 1))) ||
    		(($self->{_trw_readers} == 0) && (!defined($self->{_trw_writer})));

	return $self->_cmn_write_lock($tid);
}

=item I<$locktoken> = I<$resource-E<gt>>B<write_lock_timed>I<($timeout)>

Same as C<write_lock()>, but returns C<undef> if the
write lock cannot be granted within $timeout seconds
Returns L<Time::HiRes>::time() if the lock is granted and the requestor did not
already hold a lock on the resource, or -1 if it did hold a lock.

=cut

sub write_lock_timed {
    my ($self, $timeout) = @_;

	my $tid = threads->self()->tid();

    $timeout += time();

	lock($self);
#
#	return immediately if we're already the writer
#
	return -1
   		if (defined($self->{_trw_writer}) && ($self->{_trw_writer} == $tid));
#
#	if we're one of the readers, wait til we're the last one
#
	$self->{_trw_pending}++;

    cond_timedwait($self, $timeout)
    	until ($timeout < time()) ||
    		(($self->{_trw_lockmap}{$tid} && ($self->{_trw_readers} == 1))) ||
    		(($self->{_trw_readers} == 0) && (!defined($self->{_trw_writer})));

	$self->{_trw_pending}--;
#
#	if we're one of the readers, wait til we're the last one
#
    return undef
    	unless (($self->{_trw_lockmap}{$tid} && ($self->{_trw_readers} == 1))) ||
    		(($self->{_trw_readers} == 0) && (!defined($self->{_trw_writer})));

	return $self->_cmn_write_lock($tid);
}

=item I<$result> = I<$resource-E<gt>>B<unlock>I<( [ $locktoken ] )>

Releases a lock held by the requesting thread.
If a C<$locktoken> is provided, it must match the original
token returned when the requesting thread was granted the lock.
If C<$locktoken> is not provided, the lock is released unconditionally.
C<$result> is 1 if the lock is released, or undef if the lock is retained.

=cut

sub unlock {
    my ($self, $locktoken) = @_;

	my $tid = threads->self()->tid();

	lock($self);

	return 1
		unless $self->{_trw_lockmap}{$tid};

	return undef
		if $locktoken && ($self->{_trw_lockmap}{$tid} != $locktoken);

	delete $self->{_trw_lockmap}{$tid};
#
#	if we're the writer, just free us up
#
	delete $self->{_trw_writer},
	cond_broadcast($self),
	return 1
		if defined($self->{_trw_writer}) && ($self->{_trw_writer} == $tid);

	$self->{_trw_readers}--;
	cond_broadcast($self)
		unless $self->{_trw_readers};
	return 1;
}

1;

package Thread::Resource::RWLock::Array;
#
#	provides array-based class implementation
#
#	see pod for base T::R::RWLock for method
#	interfaces and descriptions
#
use threads;
use threads::shared;
#
#	inherit so UNIVERSAL::isa('Thread::Resource::RWLock') works
#
use Thread::Resource::RWLock;
use Time::HiRes qw(time);

use base qw(Thread::Resource::RWLock);

use strict;
use warnings;

use constant TRW_READERS => 0;
use constant TRW_LOCKMAP => 1;
use constant TRW_WRITER => 2;
use constant TRW_PENDING => 3;

sub adorn {
    my $self = shift;
#
#	we should verify $self is shared!
#
	my %lockers : shared = ();
#
#	better be an arrayref
#
    $self->[TRW_READERS] = 0;
    $self->[TRW_LOCKMAP] = \%lockers;
    $self->[TRW_WRITER] = undef;
    $self->[TRW_PENDING] = 0;
    return $self;
}
#
#	constructor for concrete instance
#
sub new {
	my $class = shift;
    my @self : shared = ();

	my $self = bless \@self, $class;

	return $self->adorn();
}
#
#	TQQ method override (for concrete instance only,
#	tho subclasses could rely on it if they're shared)
#
sub redeem {
	my ($class, $self) = @_;
	return bless $self, $class;
}

sub _cmn_read_lock {
    my ($self, $tid) = @_;
#
#	check if we're downgrading
#
	delete $self->[TRW_WRITER],
    $self->[TRW_READERS]++
		if defined($self->[TRW_WRITER]) && ($self->[TRW_WRITER] == $tid);
#
#	only return timestamp if we didn't hold the lock
#
	return -1
		if $self->[TRW_LOCKMAP]{$tid};

    $self->[TRW_LOCKMAP]{$tid} = time();
    $self->[TRW_READERS]++;
    return $self->[TRW_LOCKMAP]{$tid};
}

sub read_lock {
    my $self = shift;

	my $tid = threads->self()->tid();

	lock($self);
#
#	check for pending writers, or if we're the writer
#
	cond_wait $self
		until (($self->[TRW_PENDING] == 0) && (!defined($self->[TRW_WRITER]))) ||
			(defined($self->[TRW_WRITER]) && ($self->[TRW_WRITER] == $tid));

	return $self->_cmn_read_lock($tid);
}

sub read_lock_nb {
    my $self = shift;

	my $tid = threads->self()->tid();

	lock($self);

    return undef
		unless (($self->[TRW_PENDING] == 0) && (!defined($self->[TRW_WRITER]))) ||
			(defined($self->[TRW_WRITER]) && ($self->[TRW_WRITER] == $tid));

	return $self->_cmn_read_lock($tid);
}

sub read_lock_timed {
    my ($self, $timeout) = shift;

	my $tid = threads->self()->tid();

	$timeout += time();

	lock($self);

    cond_timedwait($self, $timeout)
    	until ($timeout < time()) ||
			(($self->[TRW_PENDING] == 0) && (!defined($self->[TRW_WRITER]))) ||
			(defined($self->[TRW_WRITER]) && ($self->[TRW_WRITER] == $tid));

	return undef
		unless (($self->[TRW_PENDING] == 0) && (!defined($self->[TRW_WRITER]))) ||
			(defined($self->[TRW_WRITER]) && ($self->[TRW_WRITER] == $tid));

	return $self->_cmn_read_lock($tid);
}

sub _cmn_write_lock {
    my ($self, $tid) = @_;

	$self->[TRW_WRITER] = $tid;
#
#	check if we're upgrading
#
	$self->[TRW_READERS]--,
	return -1
		if $self->[TRW_READERS];

	$self->[TRW_LOCKMAP]{$tid} = time();
    return $self->[TRW_LOCKMAP]{$tid};
}

sub write_lock {
    my $self = shift;

	my $tid = threads->self()->tid();

	lock($self);
#
#	return immediately if we're already the writer
#
	return -1
   		if defined($self->[TRW_WRITER]) && ($self->[TRW_WRITER] == $tid);
#
#	if we're one of the readers, wait til we're the last one
#
	$self->[TRW_PENDING]++;

    cond_wait $self
    	until (($self->[TRW_LOCKMAP]{$tid} && ($self->[TRW_READERS] == 1))) ||
    		(($self->[TRW_READERS] == 0) && (!defined($self->[TRW_WRITER])));

	$self->[TRW_PENDING]--;
	return $self->_cmn_write_lock($tid);
}

sub write_lock_nb {
    my $self = shift;

	my $tid = threads->self()->tid();

	lock($self);
#
#	return immediately if we're already the writer
#
	return -1
   		if defined($self->[TRW_WRITER]) && ($self->[TRW_WRITER] == $tid);
#
#	if we're one of the readers, wait til we're the last one
#
    return undef
    	unless (($self->[TRW_LOCKMAP]{$tid} && ($self->[TRW_READERS] == 1))) ||
    		(($self->[TRW_READERS] == 0) && (!defined($self->[TRW_WRITER])));

	return $self->_cmn_write_lock($tid);
}

sub write_lock_timed {
    my ($self, $timeout) = @_;

	my $tid = threads->self()->tid();

	$timeout += time();

	lock($self);
#
#	return immediately if we're already the writer
#
	return -1
   		if defined($self->[TRW_WRITER]) && ($self->[TRW_WRITER] == $tid);
#
#	if we're one of the readers, wait til we're the last one
#
	$self->[TRW_PENDING]++;

    cond_timedwait($self, $timeout)
    	until ($timeout < time()) ||
    		(($self->[TRW_LOCKMAP]{$tid} && ($self->[TRW_READERS] == 1))) ||
    		(($self->[TRW_READERS] == 0) && (!defined($self->[TRW_WRITER])));

	$self->[TRW_PENDING]--;
#
#	check if we timed out
#
    return undef
    	unless (($self->[TRW_LOCKMAP]{$tid} && ($self->[TRW_READERS] == 1))) ||
    		(($self->[TRW_READERS] == 0) && (!defined($self->[TRW_WRITER])));

	return $self->_cmn_write_lock($tid);
}

sub unlock {
    my ($self, $locktoken) = @_;

	my $tid = threads->self()->tid();

	lock($self);

	return 1
		unless $self->[TRW_LOCKMAP]{$tid};

	return undef
		if $locktoken && ($self->[TRW_LOCKMAP]{$tid} != $locktoken);

	delete $self->[TRW_LOCKMAP]{$tid};
#
#	if we're the writer, just free us up
#
	delete $self->[TRW_WRITER],
	cond_broadcast($self),
	return 1
		if defined($self->[TRW_WRITER]) && ($self->[TRW_WRITER] == $tid);

	$self->[TRW_READERS]--;
	cond_broadcast($self)
		unless $self->[TRW_READERS];
	return 1;
}

=back

=head1 CAVEATS

=over 4

=item B<Differences from> L<Thread::RWLock>

Thread::Resource::RWLock provides a significantly different
interface than L<Thread::RWLock>. Most importantly, the latter
uses the old Perl 5.005 Thread module, and depends on its
C<locked> method attribute. In addition, L<Thread::RWLock>'s
interface

	- uses somewhat obscure method names (up_read, down_write, etc.)

	- does not support lock upgrades and downgrades

	- hence, can lead to deadlock, if a thread holding
		a readlock attempts to upgrade to a writelock,
		or attempts to downgrade to a readlock from a writelock

	- accumulates readlocks from the same thread, thereby
		requiring multple unlock() calls to completely
		release a resource which has been repeatedly readlocked

	- does not support a subclassing capability

=item B<Starvation>

Due to the ability to upgrade/downgrade locks, it is possible
for starvation to occur, wherein a thread waiting on a write lock
may be indefinitely blocked while another thread repeatedly upgrades,
then downgrades its lock without ever releasing the lock. Use of
lock upgrade/downgrade should be applied judiciously.

Multiple readers concurrently attempting to upgrade to writelocks
can also induce deadlock (since the readlocker count will never
drop to 1). A future release may provide an upgrade queue to handle
this case.

=item B<Zone Threading>

Applications using L<Thread::Apartment> to support zone threading
(i.e., multiple objects installed in a single apartment thread)
may need to implement extra locking functionality if the objects
within the thread are sharing the same resource in read and write
modes, as Thread::Resource::RWLock relies on the current
TID (via L<threads>::tid()) to disambiguate lockers of the same
resource. If all objects within the thread are using only readlocks,
there should be no impact. However, multiple objects using write locks,
or attempting upgrades or downgrades of locks, may cause unexpected
behavior, including deadlock or indeterminate values. Therefore,
best practice would be to segregate resource writers in their own
apartment thread. A future implementation may provide a
Thread::Resource::Locker interface which Thread::Apartment objects
can implement to disambiguate co-resident zone threaded objects.

=item B<Context Accumulation>

In the event a thread holding a lock exits without explicitly
unlock()'ing, the lock will be retained until the resource
object is DESTROY'ed, resulting in dead context accumulation,
deadlock, and/or starvation. A future release may inject an
occassional timer event to verify lock holders are still
running.

=back

=head1 SEE ALSO

L<threads>

L<threads::shared>

L<Thread::RWLock>

L<Thread::Semaphore>

=head1 AUTHOR AND COPYRIGHT

Copyright (c) 2005 Dean Arnold, Presicient Corp, USA. All rights reserved.

Permission to use and redistirbute this software is granted under the same
terms as Perl itself; refer to L<perlartistic> for license details.

=cut

1;
