package Thread::Cancel; {

use strict;
use warnings;

our $VERSION = '1.13';

use threads 1.39;

my $SIGNAL = 'KILL';    # Default cancellation signal

sub import
{
    my $class = shift;   # Not used

    # Set the signal for cancel operations
    while (my $sig = shift) {
        $SIGNAL = $sig;
    }
    $SIGNAL =~ s/^SIG//;

    # Set up the cancel signal handler
    $SIG{$SIGNAL} = sub { threads->exit(); };
}


sub threads::cancel
{
    my ($class, @threads) = @_;

    if ($class eq 'threads') {
        if (@threads) {
            # Cancel specified list of threads
            @threads = grep { $_ }
                       map  { (ref($_) eq 'threads')
                                    ? $_
                                    : threads->object($_) }
                            @threads;
        } else {
            # Cancel all threads
            push(@threads, threads->list());
        }
    } else {
        # Cancel a single thread
        push(@threads, $class);
    }

    # Cancel threads
    my $resumable = threads->can('resume');
    foreach my $thr (@threads) {
        $thr->detach() if (! $thr->is_detached());
        $thr->kill($SIGNAL);
        if ($resumable) {
            $thr->resume() if ($thr->is_suspended());
        }
    }
}

}

1;

__END__

=head1 NAME

Thread::Cancel - Cancel (i.e., kill) threads

=head1 VERSION

This document describes Thread::Cancel version 1.13

=head1 SYNOPSIS

    use Thread::Cancel 'SIGUSR1';      # Set the cancellation signal
    use Thread::Cancel;                #  Defaults to 'KILL'

    $thr->cancel();                    # Cancel a thread
    threads->cancel();                 # Cancel all non-detached threads
    threads->cancel($thr, $tid, ...);  # Cancel multiple threads using
                                        #   objects or TIDs

=head1 DESCRIPTION

This module adds cancellation capabilities for threads.  Cancelled threads are
terminated using C<threads-E<gt>exit()>.  The thread is then detached, and
hence automatically cleaned up.

Threads that are suspended using L<Thread::Suspend> do not need to be
I<resumed> in order to be cancelled.

It is possible for a thread to cancel itself.

=head2 Declaration

This module must be imported prior to any threads being created.

Cancellation is accomplished via a signal handler which is used by all threads
on which cancel operations are performed.  The signal for this operation can
be specified when this module is declared, and defaults to C<SIGKILL>.
Consequently, the application and its threads must not specify some other
handler for use with the cancel signal.

=over

=item use Thread::Cancel;

Declares this module, and defaults to using C<SIGKILL> for cancel operations.

=item use Thread::Cancel 'SIGUSR1';

=item use Thread::Cancel 'Signal' => 11;

Declares this module, and uses the specified signal for cancel operations.
Signals may be specified by the same names or (positive) numbers as supported
by L<kill()|perlfunc/"kill SIGNAL, LIST">.

=back

=head2 Methods

=over

=item $thr->cancel()

Cancels the threads.

=item threads->cancel()

Cancels all non-detached threads.  This offers a clean way to exit a threaded
application:

    # Terminate all threads and exit
    threads->cancel();
    exit(0);

=item threads->cancel($thr, $tid, ...)

Cancels the threads specified by their objects or TIDs (for non-detached
threads).

=back

=head1 CAVEATS

Subject to the limitations of L<threads/"THREAD SIGNALLING">.

Cancelled threads are automatically detached, so do not try to C<-E<gt>join()>
or C<-E<gt>detach()> a cancelled thread.

Detached threads can only be cancelled using their I<threads> object:

    $thr->detach();
    $thr->cancel();
    # or
    threads->cancel($thr);

Threads that have finished execution are, for the most part, ignored by this
module.

=head1 REQUIREMENTS

Perl 5.8.0 or later

L<threads> 1.39 or later

L<Test::More> 0.50 or later (for installation)

=head1 SEE ALSO

Thread::Cancel Discussion Forum on CPAN:
L<http://www.cpanforum.com/dist/Thread-Cancel>

L<threads>, L<threads::shared>

=head1 AUTHOR

Jerry D. Hedden, S<E<lt>jdhedden AT cpan DOT orgE<gt>>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 - 2009 Jerry D. Hedden. All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
