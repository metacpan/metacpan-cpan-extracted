#!/usr/bin/perl

use strict;
use warnings;

use threads;
use threads::shared;
use Thread::Cancel;
use Thread::Queue;

### Global Variables ###

# Maximum working threads
my $MAX_THREADS = 10;

# Maximum thread working time
my $TIMEOUT = 10;

# Flag to inform all threads that application is terminating
my $TERM :shared = 0;


### Signal Handling ###

# Gracefully terminate application on ^C
# or command line 'kill'
$SIG{'INT'} = $SIG{'TERM'} =
    sub {
        print(">>> Terminating <<<\n");
        $TERM = 1;
    };


### Main Processing Section ###
MAIN:
{
    # Start timer thread
    my $queue = Thread::Queue->new();
    threads->create('timer', $queue)->detach();

    # Manage the thread pool until signalled to terminate
    while (! $TERM) {
        # Keep max threads running
        for (my $needed = $MAX_THREADS - threads->list();
             $needed && ! $TERM;
             $needed--)
        {
            # New thread
            threads->new('worker', $queue, $TIMEOUT);
        }

        # Wait for any threads to finish
        sleep(1);
    }

    ### CLEANING UP ###

    # Wait for max timeout for threads to finish
    while ((threads->list() > 0) && $TIMEOUT--) {
        sleep(1);
    }

    # Detach and cancel any remaining threads
    $_->cancel() foreach (threads->list());
    sleep(1);
}

print("Done\n");
exit(0);


### Thread Entry Point Subroutines ###

# A worker thread
sub worker
{
    my ($queue, $timeout) = @_;

    ### INITIALIZE ###

    # My thread ID
    my $tid = threads->tid();
    printf("Working -> %3d\n", $tid);

    # Register with timer thread
    $queue->enqueue($tid, $timeout);


    ### WORK ###

    # Do some work while monitoring $TERM
    my $sleep = 5 + int(rand(10));
    while (($sleep > 0) && ! $TERM) {
        $sleep -= sleep($sleep);
    }


    ### DONE ###

    # Unregister with timer thread
    $queue->enqueue($tid, undef);

    # Tell user we're done
    printf("           %3d <- Finished\n", $tid);

    # Detach and terminate
    threads->detach() if ! threads->is_detached();
    threads->exit();
}


# The timer thread that monitors other threads for timeout
sub timer
{
    my $queue = shift;   # The registration queue
    my %timers;          # Contains threads and timeouts

    # Loop until told to quit
    while (! $TERM) {
        # Check queue
        while (my $tid = $queue->dequeue_nb()) {
            if (! ($timers{$tid}{'timeout'} = $queue->dequeue()) ||
                ! ($timers{$tid}{'thread'}  = threads->object($tid)))
            {
                # No timeout - unregister thread
                delete($timers{$tid});
            }
        }

        # Cancel timed out threads
        foreach my $tid (keys(%timers)) {
            if (--$timers{$tid}{'timeout'} < 0) {
                $timers{$tid}{'thread'}->cancel;
                printf("           %3d <- Cancelled\n", $tid);
                delete($timers{$tid});
            }
        }

        # Tick tock
        sleep(1);
    }
}

__END__

=head1 NAME

cancel.pl - Simple 'threads' example

=head1 DESCRIPTION

A simplistic example illustrating the following:

=over

=item * Management of a pool of threads

=item * Communication between threads using queues

=item * Timing out and cancelling threads

=item * Interrupting a threaded program

=item * Cleaning up threads before terminating

=back

=head1 SEE ALSO

L<threads>, L<threads::shared>, and L<Thread::Queue>

=head1 AUTHOR

Jerry D. Hedden, S<E<lt>jdhedden AT cpan DOT orgE<gt>>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 - 2009 Jerry D. Hedden. All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
