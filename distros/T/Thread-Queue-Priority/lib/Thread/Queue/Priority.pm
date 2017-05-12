package Thread::Queue::Priority;

use strict;
use warnings;

our $VERSION = '1.03';
$VERSION = eval $VERSION;

use threads::shared 1.21;
use Scalar::Util qw(looks_like_number);

# Carp errors from threads::shared calls should complain about caller
our @CARP_NOT = ("threads::shared");

sub new {
    my $class = shift;
    my %queue :shared = ();
    my %self :shared = (
        '_queue'   => \%queue,
        '_count'   => 0,
        '_ended'     => 0,
    );
    return bless(\%self, $class);
}

# add items to the tail of a queue
sub enqueue {
    my ($self, $item, $priority) = @_;
    lock(%{$self});

    # if the queue has "ended" then we can't enqueue anything
    if ($self->{'_ended'}) {
        require Carp;
        Carp::croak("'enqueue' method called on queue that has been 'end'ed");
    }

    my $queue = $self->{'_queue'};
    $priority = defined($priority) ? $self->_validate_priority($priority) : 50;

    # if the priority group hasn't been created then create it
    my @group :shared = ();
    $queue->{$priority} = \@group unless exists($queue->{$priority});

    # increase our global count
    ++$self->{'_count'};

    # add the new item to the priority list and signal that we're done
    push(@{$self->{'_queue'}->{$priority}}, shared_clone($item)) and cond_signal(%{$self});
}

# return a count of the number of items on a queue
sub pending {
    my $self = shift;
    lock(%{$self});

    # return undef if the queue has ended and is empty
    return if $self->{'_ended'} && !$self->{'_count'};
    return $self->{'_count'};
}

# indicate that no more data will enter the queue
sub end {
    my $self = shift;
    lock(%{$self});

    # no more data is coming
    $self->{'_ended'} = 1;

    # try to release at least one blocked thread
    cond_signal(%{$self});
}

# return 1 or more items from the head of a queue, blocking if needed
sub dequeue {
    my $self = shift;
    lock(%{$self});

    my $queue = $self->{'_queue'};
    my $count = scalar(@_) ? $self->_validate_count(shift(@_)) : 1;

    # wait for requisite number of items
    cond_wait(%{$self}) while (($self->{'_count'} < $count) && ! $self->{'_ended'});
    cond_signal(%{$self}) if (($self->{'_count'} > $count) || $self->{'_ended'});

    # if no longer blocking, try getting whatever is left on the queue
    return $self->dequeue_nb($count) if ($self->{'_ended'});

    # return single item
    if ($count == 1) {
        for my $priority (sort keys %{$queue}) {
            if (scalar(@{$queue->{$priority}})) {
                --$self->{'_count'};
                return shift(@{$queue->{$priority}});
            }
        }
        return;
    }

    # return multiple items
    my @items = ();
    for (1 .. $count) {
        for my $priority (sort keys %{$queue}) {
            if (scalar(@{$queue->{$priority}})) {
                --$self->{'_count'};
                push(@items, shift(@{$queue->{$priority}}));
            }
        }
    }
    return @items;
}

# return items from the head of a queue with no blocking
sub dequeue_nb {
    my $self = shift;
    lock(%{$self});

    my $queue = $self->{'_queue'};
    my $count = scalar(@_) ? $self->_validate_count(shift(@_)) : 1;

    # return single item
    if ($count == 1) {
        for my $priority (sort keys %{$queue}) {
            if (scalar(@{$queue->{$priority}})) {
                --$self->{'_count'};
                return shift(@{$queue->{$priority}});
            }
        }
        return;
    }

    # return multiple items
    my @items = ();
    for (1 .. $count) {
        for my $priority (sort keys %{$queue}) {
            if (scalar(@{$queue->{$priority}})) {
                --$self->{'_count'};
                push(@items, shift(@{$queue->{$priority}}));
            }
        }
    }

    return @items;
}

# return items from the head of a queue, blocking if needed up to a timeout
sub dequeue_timed {
    my $self = shift;
    lock(%{$self});

    my $queue = $self->{'_queue'};
    my $timeout = scalar(@_) ? $self->_validate_timeout(shift(@_)) : -1;
    my $count = scalar(@_) ? $self->_validate_count(shift(@_)) : 1;

    # timeout may be relative or absolute
    # convert to an absolute time for use with cond_timedwait()
    # so if the timeout is less than a year then we assume it's relative
    $timeout += time() if ($timeout < 322000000); # more than one year

    # wait for requisite number of items, or until timeout
    while ($self->{'_count'} < $count && !$self->{'_ended'}) {
        last unless cond_timedwait(%{$self}, $timeout);
    }
    cond_signal(%{$self}) if (($self->{'_count'} > $count) || $self->{'_ended'});

    # get whatever we need off the queue if available
    return $self->dequeue_nb($count);
}

# return an item without removing it from a queue
sub peek {
    my $self = shift;
    lock(%{$self});

    my $queue = $self->{'_queue'};
    my $index = scalar(@_) ? $self->_validate_index(shift(@_)) : 0;

    for my $priority (sort keys %{$queue}) {
        my $size = scalar(@{$queue->{$priority}});
        if ($index < $size) {
            return $queue->{$priority}->[$index];
        } else {
            $index = ($index - $size);
        }
    }

    return;
}

### internal functions ###

# check value of the requested index
sub _validate_index {
    my ($self, $index) = @_;

    if (!defined($index) || !looks_like_number($index) || (int($index) != $index)) {
        require Carp;
        my ($method) = (caller(1))[3];
        my $class_name = ref($self);
        $method =~ s/${class_name}:://;
        $index = 'undef' unless defined($index);
        Carp::croak("Invalid 'index' argument (${index}) to '${method}' method");
    }

    return $index;
}

# check value of the requested count
sub _validate_count {
    my ($self, $count) = @_;

    if (!defined($count) || !looks_like_number($count) || (int($count) != $count) || ($count < 1)) {
        require Carp;
        my ($method) = (caller(1))[3];
        my $class_name = ref($self);
        $method =~ s/${class_name}:://;
        $count = 'undef' unless defined($count);
        Carp::croak("Invalid 'count' argument (${count}) to '${method}' method");
    }

    return $count;
}

# check value of the requested timeout
sub _validate_timeout {
    my ($self, $timeout) = @_;

    if (!defined($timeout) || !looks_like_number($timeout)) {
        require Carp;
        my ($method) = (caller(1))[3];
        my $class_name = ref($self);
        $method =~ s/${class_name}:://;
        $timeout = 'undef' unless defined($timeout);
        Carp::croak("Invalid 'timeout' argument (${timeout}) to '${method}' method");
    }

    return $timeout;
}

# check value of the requested timeout
sub _validate_priority {
    my ($self, $priority) = @_;

    if (!defined($priority) || !looks_like_number($priority) || (int($priority) != $priority) || ($priority < 0)) {
        require Carp;
        my ($method) = (caller(1))[3];
        my $class_name = ref($self);
        $method =~ s/${class_name}:://;
        $priority = 'undef' unless defined($priority);
        Carp::croak("Invalid 'priority' argument (${priority}) to '${method}' method");
    }

    return $priority;
}

1;

=head1 NAME

Thread::Queue::Priority - Thread-safe queues with priorities

=head1 VERSION

This document describes Thread::Queue::Priority version 1.03

=head1 SYNOPSIS

    use strict;
    use warnings;

    use threads;
    use Thread::Queue::Priority;

    # create a new empty queue
    my $q = Thread::Queue::Priority->new();

    # add a new element with default priority 50
    $q->enqueue("foo");

    # add a new element with priority 1
    $q->enqueue("foo", 1);

    # dequeue the highest priority on the queue
    my $value = $q->dequeue();

=head1 DESCRIPTION

This is a variation on L<Thread::Queue> that will dequeue items based on their
priority. This module is NOT a drop-in replacement for L<Thread::Queue> as it
does not implement all of its methods as they don't all make sense. However,
for the methods implemented and described below, consider the functionality to
be the same as that of L<Thread::Queue>.

=head1 QUEUE CREATION

=over

=item ->new()

Creates a new empty queue. A list cannot be created with items already on it.

=item ->enqueue(ITEM, PRIORITY)

Adds an item onto the queue with the givern priority. Only one item may be
added at a time. If no priority is given, it is given a default value of 50.
There are no constraints on the priority number with the exception that it must
be greater than zero and it must be a number. The smaller the number, the
greater the priority.

=item ->dequeue()

=item ->dequeue(COUNT)

Removes and returns the requested number of items (default is 1) in priority
order where smaller numbers indicate greater priority. If the queue contains
fewer than the requested number of items, then the thread will be blocked until
the requisite number of items are available (i.e., until other threads
<enqueue> more items).

=item ->dequeue_nb()

=item ->dequeue_nb(COUNT)

This functions the same as C<dequeue> but it will not block if the queue is
empty or the queue does not have COUNT items. Instead it will return whatever
is on the queue up to COUNT, or C<undef> if the queue is empty. Again, items
will come off the queue in priority order where smaller numbers have a higher
priority.

=item ->dequeue_timed(TIMEOUT)

=item ->dequeue_timed(TIMEOUT, COUNT)

This functions the same as C<dequeue> but will only block for the length of the
given timeout. If the timeout is reached, it returns whatever items there are
on the queue, or C<undef> if the queue is empty. Again, items will come off the
queue in priority order where smaller numbers have a higher priority.

The timeout may be a number of seconds relative to the current time (e.g., 5
seconds from when the call is made), or may be an absolute timeout in I<epoch>
seconds the same as would be used with
L<cond_timedwait()|threads::shared/"cond_timedwait VARIABLE, ABS_TIMEOUT">.
Fractional seconds (e.g., 2.5 seconds) are also supported (to the extent of
the underlying implementation).

If C<TIMEOUT> is missing, C<undef>, or less than or equal to 0, then this call
behaves the same as C<dequeue_nb>.

=item ->pending()

Returns the number of items still in the queue.  Returns C<undef> if the queue
has been ended (see below), and there are no more items in the queue.

=item ->end()

Declares that no more items will be added to the queue.

All threads blocking on C<dequeue()> calls will be unblocked with any
remaining items in the queue and/or C<undef> being returned.  Any subsequent
calls to C<dequeue()> will behave like C<dequeue_nb()>.

Once ended, no more items may be placed in the queue.

=item ->peek(INDEX)

Returns n item from the queue without dequeuing anything.  Defaults to the
the head of queue (at index position 0) if no index is specified.  Negative
index values are supported as with L<arrays|perldata/"Subscripts"> (i.e., -1
is the end of the queue, -2 is next to last, and so on).

If no items exists at the specified index (i.e., the queue is empty, or the
index is beyond the number of items on the queue), then C<undef> is returned.

Remember, the returned item is not removed from the queue, so manipulating a
C<peek>ed at reference affects the item on the queue.

=back

=head1 SEE ALSO

L<Thread::Queue>, L<threads>, L<threads::shared>

=head1 MAINTAINER

Paul Lockaby S<E<lt>plockaby AT cpan DOT orgE<gt>>

=head1 CREDIT

Significant portions of this module are directly from L<Thread::Queue> which is
maintained by Jerry D. Hedden, <jdhedden AT cpan DOT org>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
