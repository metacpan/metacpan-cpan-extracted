package Timer::Wheel;

use 5.008003;
use strict;
use warnings;

use Object::Proto ();
use Heap::PQ 'import';

our $VERSION = '0.01';

BEGIN {
	Object::Proto::define('Timer::Wheel::Timer',
		'id:Int:required:readonly',
		'epoch:Num:required',
		'callback:CodeRef:required',
		'interval:Num',
		'active:Bool:default(1)',
		'paused:Bool:default(0)',
		'group:Str',
	);
	Object::Proto::define('Timer::Wheel',
		'heap:Object',
		'next_id:Int',
		'paused:Bool:default(0)',
	);
	Object::Proto::import_accessors('Timer::Wheel::Timer');
	Object::Proto::import_accessor('Timer::Wheel', 'heap', 'tw_heap');
	Object::Proto::import_accessor('Timer::Wheel', 'next_id', 'tw_next_id');
	Object::Proto::import_accessor('Timer::Wheel', 'paused', 'tw_paused');
}

sub BUILD {
	tw_heap($_[0], Heap::PQ::new('min', 'epoch'));
	tw_next_id($_[0], 1);
}

sub at {
	my ($self, $epoch, $cb, %opts) = @_;
	my $i = tw_next_id($self);
	tw_next_id($self, $i + 1);
	my $timer = new Timer::Wheel::Timer $i, $epoch, $cb, ($opts{interval} || 0), 1, 0, ($opts{group} || "");
	heap_push(tw_heap($self), { epoch => $epoch, timer => $timer });
	return $i;
}

sub in {
	my ($self, $seconds, $cb, %opts) = @_;
	return at($self, time() + $seconds, $cb, %opts);
}

sub every {
	my ($self, $seconds, $cb, %opts) = @_;
	my $start = delete $opts{start} // (time() + $seconds);
	return at($self, $start, $cb, %opts, interval => $seconds);
}

sub tick {
	my ($self, $now) = @_;
	$now //= time();
	return 0 if tw_paused($self);

	my $h = tw_heap($self);
	my $fired = 0;

	while (!heap_is_empty($h)) {
		my $entry = heap_peek($h);
		last if $entry->{epoch} > $now;
		heap_pop($h);
		my $timer = $entry->{timer};
		next unless active($timer);

		if (paused($timer)) {
			heap_push($h, $entry);
			last;
		}

		callback($timer)->();
		$fired++;

		if (interval($timer)) {
			my $next_epoch = epoch($timer) + interval($timer);
			epoch($timer, $next_epoch);
			heap_push($h, { epoch => $next_epoch, timer => $timer });
		}
	}

	return $fired;
}

sub drain {
	my ($self) = @_;
	my $h = tw_heap($self);
	my $fired = 0;
	while (!heap_is_empty($h)) {
		my $entry = heap_pop($h);
		my $timer = $entry->{timer};
		next unless active($timer) && !paused($timer);

		callback($timer)->();
		$fired++;
	}
	return $fired;
}

sub next {
	my $h = tw_heap($_[0]);
	return undef if heap_is_empty($h);
	return heap_peek($h)->{epoch};
}

sub sleep_time {
	my $next = $_[0]->next;
	return undef unless defined $next;
	my $delay = $next - time();
	return $delay > 0 ? $delay : 0;
}

sub pending {
	my @found = heap_search(tw_heap($_[0]), sub { active($_->{timer}) });
	return scalar @found;
}

sub is_empty {
	return heap_is_empty(tw_heap($_[0])) || pending($_[0]) == 0;
}

sub _find_timer {
	my ($self, $tid) = @_;
	my @found = heap_search(tw_heap($self), sub { id($_->{timer}) == $tid && active($_->{timer}) });
	return @found ? $found[0]->{timer} : undef;
}

sub cancel {
	my $timer = _find_timer($_[0], $_[1]);
	if ($timer) {
		active($timer, 0);
		return 1;
	}
	return 0;
}

sub cancel_group {
	my ($self, $group_name) = @_;
	my @found = heap_search(tw_heap($self), sub {
		active($_->{timer}) && group($_->{timer}) eq $group_name
	});
	my $count = 0;
	for my $entry (@found) {
		active($entry->{timer}, 0);
		$count++;
	}
	return $count;
}

sub cancel_all {
	my $h = tw_heap($_[0]);
	my $count = 0;
	while (!heap_is_empty($h)) {
		my $entry = heap_pop($h);
		active($entry->{timer}, 0);
		$count++;
	}
	return $count;
}

sub pause {
	my $timer = _find_timer($_[0], $_[1]);
	if ($timer) {
		paused($timer, 1);
		return 1;
	}
	return 0;
}

sub resume {
	my $timer = _find_timer($_[0], $_[1]);
	if ($timer) {
		paused($timer, 0);
		return 1;
	}
	return 0;
}

sub pause_all {
	tw_paused($_[0], 1);
}

sub resume_all {
	tw_paused($_[0], 0);
}

1;

__END__

=head1 NAME

Timer::Wheel - Lightweight timer/event scheduler

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	use Timer::Wheel;

	my $tw = new Timer::Wheel;

	# Fire in 5 seconds from now
	my $id = $tw->in(5, sub { say "5 seconds elapsed" });

	# Fire at an absolute epoch time
	$tw->at(time() + 10, sub { say "fires at epoch" });

	# Recurring timer
	$tw->every(1.0, sub { say "every second" });

	# Cancel a timer
	$tw->cancel($id);

	# Run loop
	while ($tw->pending) {
	    if (defined(my $d = $tw->sleep_time)) {
	        select(undef, undef, undef, $d) if $d > 0;
	    }
	    $tw->tick;
	}

	# IO::Async integration
	use IO::Async::Loop;
	use IO::Async::Timer::Periodic;

	my $loop = IO::Async::Loop->new;
	my $tw   = new Timer::Wheel;

	$tw->every(5, sub { say "heartbeat" });
	$tw->in(30, sub { say "timeout"; $tw->cancel_all; $loop->stop });

	my $tick = IO::Async::Timer::Periodic->new(
	    interval => 0.1,
	    on_tick  => sub { $tw->tick },
	);
	$tick->start;
	$loop->add($tick);
	$loop->run;

=head1 DESCRIPTION

Timer::Wheel is a lightweight timer scheduler that uses L<Heap::PQ> with
key-path comparison for O(log n) insert and O(1) peek, and L<Object::Proto>
for fast object construction. Timers can be one-shot or recurring, grouped
for bulk cancellation, and paused/resumed individually or globally.

=head1 METHODS

=head2 new

	my $tw = new Timer::Wheel;

Create a new timer wheel.

=head2 at($epoch, \&callback, %opts)

	my $id = $tw->at(time() + 5, sub { ... });
	my $id = $tw->at($epoch, \&cb, group => 'network');

Schedule a callback to fire at an absolute epoch time. Returns a timer ID.

=head2 in($seconds, \&callback, %opts)

	my $id = $tw->in(2.5, sub { ... });

Schedule a callback to fire in C<$seconds> from now.

=head2 every($seconds, \&callback, %opts)

	my $id = $tw->every(1.0, sub { ... });
	my $id = $tw->every(1.0, \&cb, start => $epoch);

Schedule a recurring callback. First fire is after C<$seconds> unless
C<start> is given.

=head2 tick([$now])

	my $fired = $tw->tick;
	my $fired = $tw->tick($epoch);

Fire all callbacks due at or before C<$now> (defaults to C<time()>).
Returns the number of callbacks fired. Recurring timers are re-inserted.

=head2 drain

	my $fired = $tw->drain;

Fire all pending callbacks regardless of time. Recurring timers fire once.

=head2 next

	my $epoch = $tw->next;

Returns the epoch of the earliest pending timer, or C<undef>.

=head2 sleep_time

	my $delay = $tw->sleep_time;

Seconds until the next timer fires (from C<time()>), or C<undef>.

=head2 pending

	my $n = $tw->pending;

Number of active timers.

=head2 is_empty

	my $bool = $tw->is_empty;

True if no active timers remain.

=head2 cancel($id)

	$tw->cancel($id);

Cancel a timer by ID. Returns 1 if found, 0 otherwise.

=head2 cancel_group($group)

	$tw->cancel_group('network');

Cancel all active timers with the given group tag.

=head2 cancel_all

	$tw->cancel_all;

Cancel all timers and clear the heap.

=head2 pause($id) / resume($id)

	$tw->pause($id);
	$tw->resume($id);

Pause or resume an individual timer.

=head2 pause_all / resume_all

	$tw->pause_all;
	$tw->resume_all;

Pause or resume the entire wheel.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut
