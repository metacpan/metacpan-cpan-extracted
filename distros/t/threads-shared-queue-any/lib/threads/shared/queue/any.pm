package threads::shared::queue::any;

# Make sure we inherit from threads::shared::queue
# Make sure we have version info for this module
# Make sure we do everything by the book from now on

@ISA = qw(threads::shared::queue);
$VERSION = '0.02';
use strict;

# Make sure we have Storable
# Make sure we have queues

use Storable (); # no need to pollute namespace here
use threads::shared::queue;

# Satisfy -require-

1;

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N parameters to be passed as a set onto the queue

sub enqueue {
    shift->SUPER::enqueue( Storable::freeze( \@_ ) );
}

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N parameters returned from a set on the queue

sub dequeue {
    @{Storable::thaw( shift->SUPER::dequeue )};
}

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N parameters returned from a set on the queue

sub dequeue_nb {
    return unless my $ref = shift->SUPER::dequeue_nb;
    @{Storable::thaw( $ref )};
}

__END__

=head1 NAME

threads::shared::queue::any - thread-safe queues for any data-structure

=head1 SYNOPSIS

    use threads::shared::queue::any;
    my $q = threads::shared::queue::any->new;
    $q->enqueue("foo", ["bar"], {"zoo"});
    my ($foo,$bar,$zoo) = $q->dequeue;
    my ($foo,$bar,$zoo) = $q->dequeue_nb;
    my $left = $q->pending;

=head1 DESCRIPTION

A queue, as implemented by C<threads::shared::queue::any> is a thread-safe 
data structure that inherits from C<threads::shared::queue>.  But unlike the
standard C<threads::shared::queue>, you can pass (a reference to) any data
structure to the queue.

Apart from the fact that the parameters to C<enqueue> are considered to be
a set that needs to be enqueued together and that C<dequeue> returns all of
the parameters that were enqueued together, this module is a drop-in
replacement for C<threads::shared::queue> in every other aspect.

Any number of threads can safely add elements to the end of the list, or
remove elements from the head of the list. (Queues don't permit adding or
removing elements from the middle of the list).

=head1 FUNCTIONS AND METHODS

=over 8

=item new

The C<new> function creates a new empty queue.

=item enqueue LIST

The C<enqueue> method adds a reference to all the specified parameters on to
the end of the queue.  The queue will grow as needed.

=item dequeue

The C<dequeue> method removes a reference from the head of the queue,
dereferences it and returns the resulting values.  If the queue is currently
empty, C<dequeue> will block the thread until another thread C<enqueue>s.

=item dequeue_nb

The C<dequeue_nb> method, like the C<dequeue> method, removes a scalar from
the head of the queue and returns it. Unlike C<dequeue>, though,
C<dequeue_nb> won't block if the queue is empty, instead returning
C<undef>.

=item pending

The C<pending> method returns the number of items still in the queue.

=back

=head1 CAVEATS

Passing unshared values between threads is accomplished by serializing the
specified values using C<Storable> when enqueuing and de-serializing the queued
value on dequeuing.  This allows for great flexibility at the expense of more
CPU usage.  It also limits what can be passed, as e.g. code references can
B<not> be serialized and therefor not be passed.

=head1 SEE ALSO

L<threads>, L<threads::shared>, L<threads::shared::queue>.

=cut
