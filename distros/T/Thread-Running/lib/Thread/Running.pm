package Thread::Running;

# Make sure we have version info for this module
# Make sure we do everything by the book from now on

$VERSION = '0.08';
use strict;

# Only load the things we need on demand

use load;

# Make sure we can do threads
# Make sure we can do shared variables

use threads ();
use threads::shared ();

# Shared hash for keeping exited threads
#  ''    = thread did not start at all
#  undef = thread started successfully
#  0     = thread detached
#  1     = undetached thread exited
#  2     = thread joined or detached thread exited

our %status : shared;

# Enable Thread::Exit with thread marking stuff

use Thread::Exit

# Obtain the thread ID
# Set to joined if marked as detached, else as undetached exited

    end => sub {
        my $tid = threads->tid;
        $status{$tid} = 1 + defined $status{$tid};
    },
;

# Make sure we do this before anything else
#  Allow for dirty tricks

BEGIN {
    no strict 'refs'; no warnings 'redefine';
    my $new = \&threads::new; # closure!
    *threads::new = *threads::create = sub {
        my $thread = $new->( @_ );
        $status{$thread->tid} = undef;
        $thread;
    };

#  Keep reference to current detach routine
#  Hijack the thread detach routine with a sub that sets detached status
#  Keep reference to current join routine
#  Hijack the thread join routine with a sub that sets joined status

    my $detach = \&threads::detach; # closure!
    *threads::detach = sub { $status{$_[0]->tid} = 0; return &$detach };
    my $join = \&threads::join; #closure!
    *threads::join = sub { $status{$_[0]->tid} = 2; return &$join };
} #BEGIN

# Satisfy -require-

1;

#---------------------------------------------------------------------------

# Stuff that should really be in threads.pm

#---------------------------------------------------------------------------
#  IN: 1 class (ignored) or object to be checked
#      2..N additional thread (ID's) that should be checked (default: all)
# OUT: 1..N thread ID's that are still running

sub threads::running {

# Lose the class
# Go do the actual check

    shift unless ref $_[0];
    return &running;
} #threads::running

#---------------------------------------------------------------------------
#  IN: 1 class (ignored) or object to be checked
#      2..N additional thread (ID's) that should be checked (default: all)
# OUT: 1..N thread ID's that can be join()ed

sub threads::tojoin {

# Lose the class
# Go do the actual check

    shift unless ref $_[0];
    return &tojoin;
} #threads::tojoin

#---------------------------------------------------------------------------
#  IN: 1 class (ignored) or object to be checked
#      2..N additional thread (ID's) that should be checked (default: all)
# OUT: 1..N thread ID's that have exited

sub threads::exited {

# Lose the class
# Go do the actual check

    shift unless ref $_[0];
    return &exited;
} #threads::exited

#---------------------------------------------------------------------------

# The following subroutines are loaded only when they are needed

__END__

#---------------------------------------------------------------------------

# The subroutines

#---------------------------------------------------------------------------
#  IN: 1..N thread (ID's) that should be checked (default: all)
# OUT: 1..N thread ID's that are still running

sub running {

# For all of the threads specified
#  Make sure we have a thread ID
#  Reloop if we haven't seen this thread start or it has exited already
#  Return with succes now if in scalar context
#  Add thread ID to list
# Return list of thread ID's that have exited

    my @tid;
    foreach (@_ ? @_ : _listall()) {
        my $tid = ref( $_ ) ? $_->tid : $_;
        next if !exists $status{$tid} or $status{$tid};
        return 1 unless wantarray;
        push @tid,$tid;
    }
    @tid;
} #running

#---------------------------------------------------------------------------
#  IN: 1..N thread (ID's) that should be checked (default: all)
# OUT: 1..N threads that can be joined

sub tojoin {

# For all of the threads specified
#  Reloop if this thread is not ready to be joined
#  Return with succes now if in scalar context
#  Add thread ID to list if exited
# Return now if there are no objects

    my @tid;
    foreach (@_ ? @_ : _listall( 1 )) {
        my $tid = ref( $_ ) ? $_->tid : $_;
        next unless ($status{$tid} || 0) == 1;
        return 1 unless wantarray;
        push @tid,$tid;
    }
    return () unless @tid;

# Create hash of thread objects keyed to thread ID's
# Return the appropriate objects

    my %thread = map { $_->tid => $_ } threads->list;
    @thread{@tid};
} #tojoin

#---------------------------------------------------------------------------
#  IN: 1..N thread ID's that should be checked (default: all)
# OUT: 1..N threads that exited

sub exited {

# Set the threads to work on
# Return success if scalar context and nothing to check

    @_ = _listall() unless @_;
    return 1 unless wantarray or @_;

# For all of the threads specified
#  Return with failure now if in scalar context and not exited
#  Add thread ID to list if exited
# Return list of thread ID's that have exited or flag if all

    my @tid;
    foreach (@_) {
        my $tid = ref( $_ ) ? $_->tid : $_;
        return 0 unless wantarray or $status{$tid};
        push @tid,$tid;
    }
    return wantarray ? @tid : @tid == @_;
} #exited

#---------------------------------------------------------------------------

# Methods needed by Perl

#---------------------------------------------------------------------------
#  IN: 1 class
#      2..N subroutines to export

sub import {

# Lose the class
# Obtain the namespace
# Set the defaults if nothing specified
# Allow for evil stuff
# Export whatever needs to be exported

    shift;
    my $namespace = (scalar caller() ).'::';
    @_ = qw(exited running tojoin) unless @_;
    no strict 'refs';
    *{$namespace.$_} = \&$_ foreach @_;
} #import

#---------------------------------------------------------------------------

# Internal subroutines

#---------------------------------------------------------------------------
# OUT: 1..N all the thread ID's currently running (including detached threads)

sub _listall {

# For all the threads that we know about
#  Keep the thread ID if it's still running
# Return whatever we got

    my @tid;
    while (my $tid = each %status) {
        push @tid,$tid unless ($status{$tid} || 0) == 2;
    }
    @tid;
} #_listall

#---------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Running - provide non-blocking check whether threads are running

=head1 SYNOPSIS

    use Thread::Running;      # exports running(), exited() and tojoin()
    use Thread::Running qw(running);   # only exports running()
    use Thread::Running ();   # threads methods only

    my $thread = threads->new( sub { whatever } );
    while ($thread->running) {
    # do your stuff
    }

    $_->join foreach threads->tojoin;

    until (threads->exited( $tid )) {
    # do your stuff
    }

    sleep 1 while threads->running;

=head1 DESCRIPTION

                  *** A note of CAUTION ***

 This module only functions on Perl versions 5.8.0 and later.
 And then only when threads are enabled with -Dusethreads.  It
 is of no use with any version of Perl before 5.8.0 or without
 threads enabled.

                  *************************

This module adds three features to threads that are sorely missed by some:
you can check whether a thread is running, whether it can be joined or whether
it has exited without waiting for that thread to be finished (non-blocking).

=head1 METHODS

These are the methods.

=head2 running

 sleep 1 while threads->running; # wait until all threads stopped running

 sleep 1 while $thread->running; # wait until this thread stopped running

 @running = threads->running( @thread );  # list of threads still running

 while (running( @tid )) {  # subroutine: while at least 1 is still running
 # do your stuff
 }

The "running" method allows you to check whether one or more threads are
still running.  It accepts one or more thread objects or thread ID's (as
obtained by the C<threads::tid()> method).

If called as a class method or as a subroutine without parameters, then it
will check all threads of which it knows.  If called as an instance method
without parameters, it will only check the thread associated with the object.

In list context it returns the thread ID's of the threads that are still
running.  In scalar context, it just returns 1 or 0 to indicate whether any
of the (implicitely) indicated threads is still running.

=head2 tojoin

 sleep 1 until threads->tojoin; # wait until any thread can be joined

 sleep 1 until $thread->tojoin; # wait until this thread can be joined

 warn "Come on and join!\n" if threads->tojoin( $thread );

 $_->join foreach threads->tojoin; # join all joinable threads

The "tojoin" method allows you to check whether one or more threads have
finished executing and can be joined.  It accepts one or more thread objects
or thread ID's (as obtained by the C<threads::tid()> method).

If called as a class method or as a subroutine without parameters, then it
will check all threads of which it knows.  If called as an instance method
without parameters, it will only check the thread associated with the object.

In list context it returns thread objects of the threads that can be joined.
In scalar context, it just returns 1 or 0 to indicate whether any of the
(implicitely) indicated threads can be joined.

=head2 exited

 sleep 1 until $thread->exited; # wait until this thread exited

 sleep 1 until threads->exited; # wait until all threads exited

 @exited = threads->exited( @thread ); # threads that have exited

 until (exited( @tid )) { # subroutine: until all have exited
 # do your stuff
 }

The "exited" method allows you to check whether all of one or more threads
have exited.  It accepts one or more thread objects or thread ID's (as
obtained by the C<threads::tid()> method).

If called as a class method or as a subroutine without parameters, then it
will check all threads of which it knows.  If called as an instance method
without parameters, it will only check the thread associated with the object.

In list context it returns the thread ID's of the threads that have exited.
In scalar context, it just returns 1 or 0 to indicate whether B<all> of the
(implicitely) indicated threads have exited.

=head1 REQUIRED MODULES

 load (any)
 Thread::Exit (0.06)

=head1 CAVEATS

This module is dependent on the L<Thread::Exit> module, with all of its
CAVEATS applicable.

This module uses the L<load> module to make sure that subroutines are loaded
only when they are needed.

=head1 TODO

Examples should be added.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2003-2005 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<threads>, L<Thread::Exit>, L<load>.

=cut
