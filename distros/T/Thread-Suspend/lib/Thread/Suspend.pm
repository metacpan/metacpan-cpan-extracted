package Thread::Suspend; {

use strict;
use warnings;

our $VERSION = '1.23';

use threads 1.39;
use threads::shared 1.01;

my %SUSPEND :shared;    # Thread suspension counts by TID

my $SIGNAL = 'STOP';    # Default suspension signal


sub import
{
    my $class = shift;   # Not used

    # Set the signal for suspend operations
    while (my $sig = shift) {
        $SIGNAL = $sig;
    }
    $SIGNAL =~ s/^SIG//;

    # Set up the suspend signal handler
    $SIG{$SIGNAL} = sub {
        my $tid = threads->tid();
        lock(%SUSPEND);
        while ($SUSPEND{$tid}) {
            cond_wait(%SUSPEND);
        }
    };
}


sub threads::suspend
{
    my ($thing, @threads) = @_;

    if ($thing eq 'threads') {
        if (@threads) {
            # Suspend specified list of threads
            @threads = grep { $_ }
                       map  { (ref($_) eq 'threads')
                                    ? $_
                                    : threads->object($_) }
                            @threads;
        } else {
            # Suspend all non-detached threads
            push(@threads, threads->list(threads::running));
        }
    } else {
        # Suspend a single thread
        push(@threads, $thing);
    }

    # Suspend threads
    lock(%SUSPEND);
    foreach my $thr (@threads) {
        my $tid = $thr->tid();
        # Increment suspension count
        if (! $SUSPEND{$tid}++) {
            # Send suspend signal if not currently suspended
            $thr->kill($SIGNAL);
            if (! $thr->is_running()) {
                # Thread terminated before it could be suspended
                delete($SUSPEND{$tid});
            }
        }
    }

    # Return list of affected threads
    return ($thing eq 'threads')
                    ? grep { $_->is_running() } @threads
                    : $thing;
}


sub threads::resume
{
    my ($thing, @threads) = @_;

    lock(%SUSPEND);
    if ($thing eq 'threads') {
        if (@threads) {
            # Resume specified threads
            @threads = grep { $_ }
                       map  { (ref($_) eq 'threads')
                                    ? $_
                                    : threads->object($_) }
                            @threads;
        } else {
            # Resume all threads
            @threads = grep { $_ }
                       map  { threads->object($_) }
                            keys(%SUSPEND);
        }
    } else {
        # Resume a single thread
        push(@threads, $thing);
    }

    # Resume threads
    my $resume = 0;
    foreach my $thr (@threads) {
        my $tid = $thr->tid();
        if ($SUSPEND{$tid}) {
            # Decrement suspension count
            if (! --$SUSPEND{$tid}) {
                # Suspension count reached zero
                $resume = 1;
                delete($SUSPEND{$tid});
            }
        }
    }
    # Broadcast any resumptions
    if ($resume) {
        cond_broadcast(%SUSPEND);
    }

    # Return list of affected threads
    return ($thing eq 'threads') ? @threads : $thing;
}


sub threads::is_suspended
{
    my $item = shift;

    lock(%SUSPEND);
    if ($item eq 'threads') {
        # Return list of all non-detached suspended threads
        return (grep { $_ }
                map  { threads->object($_) }
                    keys(%SUSPEND));

    } else {
        # Return suspension count for a single thread
        my $tid = $item->tid();
        return ($SUSPEND{$tid}) ? $SUSPEND{$tid} : 0;
    }
}

}

1;

__END__

=head1 NAME

Thread::Suspend - Suspend and resume operations for threads

=head1 VERSION

This document describes Thread::Suspend version 1.23

=head1 SYNOPSIS

    use Thread::Suspend 'SIGUSR1';      # Set the suspension signal
    use Thread::Suspend;                #  Defaults to 'STOP'

    $thr->suspend();                    # Suspend a thread
    threads->suspend();                 # Suspend all non-detached threads
    threads->suspend($thr, $tid, ...);  # Suspend multiple threads using
                                        #   objects or TIDs

    $thr->is_suspended();               # Returns suspension count
    threads->is_suspended();            # Returns list of all suspended threads

    $thr->resume();                     # Resume a thread
    threads->resume();                  # Resume all threads
    threads->resume($thr, $tid, ...);   # Resume multiple threads

=head1 DESCRIPTION

This module adds suspend and resume operations for threads.

Suspensions are cumulative, and need to be matched by an equal number of
resume calls.

=head2 Declaration

This module must be imported prior to any threads being created.

Suspension is accomplished via a signal handler which is used by all threads
on which suspend operations are performed.  The signal for this operation can
be specified when this module is declared, and defaults to C<SIGSTOP>.
Consequently, the application and its threads must not specify some other
handler for use with the suspend signal.

=over

=item use Thread::Suspend;

Declares this module, and defaults to using C<SIGSTOP> for suspend operations.

=item use Thread::Suspend 'SIGUSR1';

=item use Thread::Suspend 'Signal' => 11;

Declares this module, and uses the specified signal for suspend operations.
Signals may be specified by the same names or (positive) numbers as supported
by L<kill()|perlfunc/"kill SIGNAL, LIST">.

=back

=head2 Methods

=over

=item $thr->suspend()

Adds 1 to the suspension count of the thread, and suspends its execution if
running.  Returns the I<threads> object.

It is possible for a thread to suspend itself.  This is useful for starting a
thread early in an application, and having it C<wait> until needed:

    sub thr_func
    {
        # Suspend until needed
        threads->self()->suspend();
        ...
    }

=item threads->suspend()

Adds 1 to the suspension count of all non-detached threads, and
suspends their execution if running.  Returns a list of those threads.

=item threads->suspend($thr, $tid, ...)

Adds 1 to the suspension count of the threads specified by their objects or
TIDs (for non-detached threads), and suspends their execution if running.
Returns a list of the corresponding I<threads> objects affected by the call.

=item $thr->is_suspended()

Returns the suspension count for the thread.

=item threads->is_suspended()

Returns a list of currently suspended, non-detached threads.

=item $thr->resume()

Decrements the suspension count for a thread.  The thread will resume
execution if the count reaches zero.  Returns the I<threads> object.

=item threads->resume()

Decrements the suspension count for all currently suspended, non-detached
threads.  Those threads that reach a count of zero will resume execution.
Returns a list of the threads operated on.

Given possible multiple levels of suspension, you can ensure that all
(non-detached) threads are running using:

    while (threads->resume()) { }

=item threads->resume($thr, $tid, ...)

Decrements the suspension count of the threads specified by their objects or
TIDs (for non-detached threads).  Those threads that reach a count of zero
will resume execution.  Returns a list of the threads operated on.

=back

=head1 CAVEATS

Subject to the limitations of L<threads/"THREAD SIGNALLING">.

A thread that has been suspended will not respond to any other signals or
commands until its suspension count is brought back to zero via resume calls.

Any locks held by a thread when it is suspended will remain in effect.  To
alleviate this potential problem, lock any such variables as part of a limited
scope that also contains the suspension call:

    {
        lock($var);
        $thr->suspend();
    }

Calling C<-E<gt>resume()> on an non-suspended thread is ignored.

Detached threads can only be operated upon if their I<threads> object is used.
For example, the following works:

    my $thr = threads->create(...);
    $thr->detach();
    ...
    $thr->suspend();  # or threads->suspend($thr);
    ...
    $thr->resume();   # or threads->resume($thr);

Threads that have finished execution are, for the most part, ignored by this
module.

=head1 REQUIREMENTS

Perl 5.8.0 or later

L<threads> 1.39 or later

L<threads::shared> 1.01 or later

L<Test::More> 0.50 or later (for installation)

=head1 SEE ALSO

Thread::Suspend on MetaCPAN:
L<https://metacpan.org/release/Thread-Suspend>

Code repository:
L<https://github.com/jdhedden/Thread-Suspend>

L<threads>, L<threads::shared>

Sample code in the I<examples> directory of this distribution on CPAN.

=head1 AUTHOR

Jerry D. Hedden, S<E<lt>jdhedden AT cpan DOT orgE<gt>>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 - 2009 Jerry D. Hedden. All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
