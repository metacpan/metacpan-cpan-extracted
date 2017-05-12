#!/usr/bin/perl

use strict;
use warnings;

$| = 1;

use threads;
use threads::shared;
use Thread::Suspend;

### Global Variables ###

# Flag to inform all threads that application is terminating
my $TERM :shared = 0;


### Signal Handling ###

# Gracefully terminate application on ^C
# or command line 'kill'
$SIG{'INT'} = $SIG{'TERM'} = sub { $TERM = 1; };


### Main Processing Section ###
MAIN:
{
    print("To terminate demo, hit ctrl-C\n\n");

    # Start the worker thread
    my $worker = threads->new('worker');
    $worker->detach();
    threads->yield();

    # Start the controller thread
    threads->new('controller', $worker)->detach();
    threads->yield();

    # Hang around until told to terminate
    sleep(1) until ($TERM);

    print("\e[?25h\n\e[2K\n\e[2K\n");   # Restore cursor
}

print("Done\n");
exit(0);


### Thread Entry Point Subroutines ###

# A worker thread
sub worker
{
    ### INITIALIZE ###

    printf("Working thread started and waiting.\n\n");
    threads->self()->suspend();

    ### WORK ###

    my $cnt = 0;
    while (! $TERM) {
        print("\rWorking: $cnt");
        $cnt++;
    }
}


sub controller
{
    my $worker = shift;    # The worker thread

    print("\n\e[ATo start worker thread, hit return: ");
    my $user = <STDIN>;

    while (! $TERM) {
        print("\e[A\e[KTo suspend worker thread, hit return...\n");
        print("\e[3A\e[K\e[?25l");   # Hide cursor
        $worker->resume();
        $user = <STDIN>;
        $worker->suspend();
        threads->yield();
        print("\e[2K\e[?25h\n");     # Restore cursor
        print("\e[KTo resume worker thread, hit return: ");
        $user = <STDIN>;
    }
}

__END__

=head1 NAME

suspend.pl - Simple example illustrating threads suspend and resume operations

=head1 DESCRIPTION

A simplistic example with one thread controlling the execution of another
using suspend and resume operations.

=head1 SEE ALSO

L<threads> and L<threads::shared>

=head1 AUTHOR

Jerry D. Hedden, S<E<lt>jdhedden AT cpan DOT orgE<gt>>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 - 2009 Jerry D. Hedden. All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
