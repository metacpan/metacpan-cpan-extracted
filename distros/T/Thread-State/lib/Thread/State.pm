package Thread::State;

use strict;
use warnings;

our $VERSION = '0.09';

require XSLoader;
XSLoader::load('Thread::State', $VERSION);

BEGIN {
    if (threads->VERSION < 1.34) {
        *threads::is_running  = *threads::_is_running;
        *threads::is_detached = *threads::_is_detached;
        *threads::is_joinable = *threads::_is_joinable;
        *threads::wantarray   = *threads::_wantarray;
    }

    *threads::in_context = *threads::wantarray; # for old version
}


#################################################
1;
__END__

=head1 NAME

Thread::State -  check threads state, context, priority

=head1 SYNOPSIS

 use threads;
 use Thread::State;
 
 my $thr  = threads->new(sub { ... });
 
 while ( $thr->is_running ) {
   ...
 }
 
 if( $thr->wantarray ){
     ...
 }
 
 if ($thr->is_joined) {
   ...
 }

 if ($thr->is_joinable) {
   ...
 }

 if ($thr->is_not_joined_or_detached) { # until version 0.07, this method was is_joinable().
   ...
 }

 
 print threads->is_detached; # main thread is detached.

 ...

 # get thread priority
 my $priority = $thr->priority;
 # set thread priority (WIN32 thread only)
 $thr->priority(2);


=head1 DESCRIPTION

**************************** CAUTION ********************************

Since CPAN threads version 1.34, threads module has some new methods
which are offered by Thread::State:
C<is_running>, C<is_detached>, C<is_joinable> and C<wantarray>.
On such a version, you can still use this module.

*********************************************************************

This module adds some methods to threads which are used to check
threads' state (is detached? joined? finished?) and created context,
code reference(start function) and thread priority.

L<Thread::Running> is also for the same aim. It hacks threads::new,
threads::join, and threads::detach. On the other hand,
Thread::State peeks at the ithread structures directly.

You must use L<threads> before using Thread::State.

This module requires  Perl core threads (<= 1.07) or
CPAN threads (>= 1.23).

=head1 METHODS

All below methods can be used as class methods. In that case,
they return a current thread's state.

=over 4

=item is_running

The thread is not finished.

=item is_finished

The thread is finished.

=item is_joined

The thread is joined.

=item is_detached

The thread is detached.

=item is_joinable

The thread is joinable (not joined, not detached and already finished).
This behavior was changed in Thread::State 0.08 and previous method is
C<is_not_joined_nor_detached>;

=item is_not_joined_nor_detached

The thread is joinable (not joined, not detached) but might not finished yet.

=item wantarray

Returns the created context of the thread.
As like C<wantarray>, if void context, returns C<undef>,
list context is true value, and scalar context is false.
C<in_context> is alias to this method.

=item coderef

Returns the thread coderef which was passed into C<create> or C<new>.
When a thread code is finished with L<threads> core version, the coderef
refcount is made to 0 and destroyed. In that case C<coderef> method
will return C<undef>.

=item priority

=item priority($int)

Note: This method is experimental and may be removed.

Returns the thread priority. You can pass the integer to set new priority
(the old priority is returned).
But setting priority will be meaningful on Win32 machine, because
to pthread implemented ithread, only 0 is acceptable.

When method fails in setting/getting priority, returns C<undef>.

=back


=head1 NOTE

With Perl 5.8.0 on Windows, C<is_joined> and C<is_joinable> may not
work correctly. This is the problem of threads itself.

This problem was fixed by Thread::State 0.04.

=head1 SEE ALSO

L<Thread::Running>,
L<threads>

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]donzoko.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
