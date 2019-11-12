package Thread::Needs;

# Make sure we have version info for this module
# Make sure we do everything by the book from now on

$VERSION = '0.06';
use strict;

# Do this at compilation time only
#  If Symbol.pm got already loaded, we're going to keep it
#   But make sure we can zap modules directly
#  Else
#   Get the Symbol stuff
#   Make sure we can zap modules directly
#   And zap the original module, our zap() should survive that.
#   Make sure it gets loaded again if needed

BEGIN {
    if (defined $Symbol::VERSION) {
        *zap = \&Symbol::delete_package;
    } else {
        require Symbol;
        *zap = \&Symbol::delete_package;
        zap( 'Symbol' );
        delete( $INC{'Symbol.pm'} );
    }
} #BEGIN

# Initialize the VERBOSE flag

our $VERBOSE;

# Initialize the hash of modules that we should keep

our %keep;

# Initialize the keep module hash
#  For all of the module names that we should always keep

BEGIN {
    foreach (qw(
AutoLoader
DynaLoader
Thread::Needs
threads
threads::shared
    )) {

#  Turn the module name into a filename (without extension)
#  Set a flag to keep this filename (including extension)

        (my $file = $_) =~ s#::#/#g;
        $keep{$file.'.pm'} = undef;
    }
}

# Satisfy -require-

1;

#---------------------------------------------------------------------------

# routines for standard perl features

#---------------------------------------------------------------------------
#  IN: 1 class for which to import (ignored)
#      2..N modules that should be kept
# OUT: 1..N modules that where not kept before

sub import {

# Obtain the class (we don't want to keep that!)
# Initialize the list of modules that were not already being kept

    my $class = shift;
    my @notyet;

# For all of the parameters
#  Postfix .pm if not already specified
#  Make it a filename instead of a module
#  Reloop if this module is already being kept
#  Add this module to list of not already kept
#  Mark this module to be kept

    foreach (@_) {
        my $file = m#\.pm$# ? $_ : "$_.pm";
        $file =~ s#::#/#g;
        next if exists( $keep{$file} );
        push( @notyet,$_ );
        $keep{$file} = undef;
    }

# Return the modules that were not yet being kept

    @notyet;
} #import

#---------------------------------------------------------------------------
#  IN: 1 class for which to unimport (ignored)
#      2..N modules that should be removed

sub unimport {

# Obtain the class (we don't want to do anything with that)
# For all of the parameters
#  Postfix .pm if not already specified
#  Make it a filename instead of a module
#  Mark this module to be removed

    my $class = shift;
    foreach (@_) {
        my $file = m#\.pm$# ? $_ : "$_.pm";
        $file =~ s#::#/#g;
	delete( $keep{$file} );
    }

# Make sure we return an empty list

    ();
} #unimport

#---------------------------------------------------------------------------

sub CLONE {

# Obtain the sorted list of modules that we need to remove
# Allow for every dirty trick in the book

    my @module =
     sort {lc($a) cmp lc($b)} map {exists $keep{$_} ? () : ($_)} keys %INC;
    no strict 'refs';

# For all of the modules
#  Reloop if we need to keep this one
#  Remove knowledge of it being loaded
#  Remove perl module extension
#  Delete that module

    foreach (@module) {
        next if m#^/#; # absolute path in %INC?
warn "Deleting $_ from %INC\n" if $VERBOSE;
        delete( $INC{$_} );
        s#\.pm$##;
	s#/#::#g;
warn "Removing $_\n" if $VERBOSE;
        zap( $_ );
    }
} # CLONE

#---------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Needs - remove unneeded modules from CLONEd memory

=head1 SYNOPSIS

    use Thread::Needs;
    use Thread::Needs (Config Thread::Pool);
    no Thread::Needs (Config); # only if previously in -use-

=head1 DESCRIPTION

                  *** A note of CAUTION ***

 This module only functions on Perl versions 5.8.0 and later.
 And then only when threads are enabled with -Dusethreads.  It
 is of no use with any version of Perl before 5.8.0 or without
 threads enabled.

                  *************************

In many threaded applications, threads do only very simple things that
do not need many (if any) modules.  The current threading model however,
copies all modules that are available at the moment a thread is started,
to the memory of the thread (ensuring an identical environment to the thread
from which it was started).  Memory that is not being used and which is
not being shared between processes.  In other words, pretty much wasted
memory.

The C<Thread::Needs> module is an B<experimental> module for reducing the
memory footprint of threaded Perl applications.  It attempts to reduce the
amount of memory used by removing B<all> modules, B<except> the ones it is
told to keep, from memory in any threads that are started from the thread
in which C<Thread::Needs> is invoked.

Please note that this module uses some dirty tricks that may crash your
application, specifically with segmentation faults.  A segmentation fault
is usually an indication that a module got removed when it shouldn't have
been.  But usually, you will just get an error when a thread starts (or
is already running for a while) indicating the absence of a particular
module.  In that case, you just need to add the name of the module to
the list of modules that you need to keep.  Beware though that this can be
a process that takes a number of iterations, as one module may be using
other modules that you are not aware of and which are needed anyway.

Memory savings are greatly dependent on the number and type of modules that
have been C<use>d when a threads is started.  It naturally also depends on
the number of threads that are started.  Observer memory savings have ranged
from 1% (with only a few modules and only 1 thread) upto more than 25%
(with 100 threads and some modules), effectively making the difference
between having a server go into swap or not on my development machine.
Your Mileage May Vary.

=head1 CLASS METHODS

There are only 2 class methods that can be called either explicitely or
implicitely.

=head2 import

 use Thread::Needs qw(Must::Keep::This::Module);

 @notyet = Thread::Needs->import( qw(Must::Keep::This::Module) );

With the "import" class method you can specify additional modules that must
L<not> be removed in any threads that are started from the current thread.

The "import" method is called implicitely when parameters are specified with
C<use>.

If you call the "import" method explicitely, then the modules that were
not already marked to be saved, will be returned.  This allows a module to
mark modules to be kept, start threads, and then unmark the modules to be
kept using the L<unimport> class method.

You should also note that you can call the C<import()> method of a module
B<without> having to be sure whether the module is actually loaded.
If the "import" method is called without the Thread::Needs module being
available, it will execute the UNIVERSAL->import method, effectively turning
it into a no-op.  So modules can easily call the Thread::Needs->import
without having to worry about Thread::Needs being available: if is B<is>
available, then you will get the memory savings.  If it is not available,
then you will not get the memory savings, but it won't break either.

=head2 unimport

 no Thread::Needs qw(Must::Not::Keep::This::Module);

 Thread::Needs->unimport( qw(Must::Not::Keep::This::Module) );

With the "unimport" class method you can specify modules that must be removed
from the list of modules to be removed.  It only makes sense to call with a
specific module name of it was previously (implicitely) specified with
L<import>.

The "unimport" method is called implicitely when parameters are specified
with C<no>.

=head1 REQUIRED MODULES

 (none)

=head1 EXAMPLES

Some examples of using Thread::Needs.

=head2 using Thread::Pool

A simple example when using Thread::Pool:

 use Thread::Pool;
 use Thread::Needs qw(Thread::Pool Thread::Conveyor);

 my $pool = Thread::Pool->new(
  {
   do => sub { warn "Hello $_[0]!\n" },
   workers => 10,
  }
 );

 $pool->job( 'Liz' );
 <>; # Look at "top" when "Hello Liz" is shown
 $pool->job( 'Wendy' );

With the C<Thread::Needs> the memory usage of the above is B<7928> KByte.
Without it, the memory usage is B<9104> KByte.  That's over 1 Mbyte of
memory saved, about 12%.  Well, at least on my (Linux) development machine.

=head2 within Thread::Pool

Because the Thread::Pool module internally "knows" it will always need the
L<Thread::Pool> and L<Thread::Conveyor> modules, it can tell Thread::Needs
itself that the Thread::Pool and Thread::Conveyor modules need to be kept.
However, that would mean that any other threads would also keep these modules,
which may not be what you want.

The solution is simple: L<import> returns the modules that were not yet
marked to be saved, so you can later call the L<unimport> module after the
threads have been started.

 my @notyet = Thread::Needs->import( qw(Thread::Pool Thread::Conveyor) );
 $thread = threads->new( \&start_thread );
 Thread::Needs->unimport( @notyet );

Please note that the module itself does B<not> have to do a
C<use Thread::Needs>.  Because any class inherits from UNIVERSAL.pm, the
absence of Thread::Needs will cause the calls to "import" and "unimport"
to effectively become no-ops.

=head1 CAVEATS

Currently only the namespaces of the modules are zapped.  And because the
namespaces need to continue to exist because of the random order in which
CLONE subroutines are executed (otherwise causing segmentation faults),
the namespaces are re-created with just a CLONE stub.  Hopefully it will
be possible to also have these removed and even other stuff that namespace
zapping doesn't remove.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2002-2003 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<threads>.

=cut
