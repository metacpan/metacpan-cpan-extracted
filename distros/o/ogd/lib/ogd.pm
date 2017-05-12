package ogd;
require 5.008001; # must have a good B in the core

# Make sure we have version info for this module
# Make sure we do everything by the book from now on

$VERSION = '0.03';
use strict;

# At compile time
#  Create boolean for debug state
#  Create constant with that boolean
#  Create value for cleanup check
#  Create constant with that value

BEGIN {
    my $debug = ($ENV{OGD_DEBUG} || '') =~ m#^(\d+)$# ? $1 : '';
    eval "sub DEBUG () { $debug }";
    my $cleanup = ($ENV{OGD_CLEANUP} || '') =~ m#^(\d+)$# ? $1 : 10;
    eval "sub CLEANUP () { $cleanup }";
} #BEGIN

# Make sure we can find out the blessing of an object and to weaken it

use Scalar::Util qw(blessed weaken);

# Initialize counter for number of objects registered
# List with objects that should be destroyed (first is a dummy object)

my $registered = 0;
my @object;

# Make sure we do this before anything else
#  Allow for dirty tricks
#  Obtain current setting
#  See if we can call it
#  Use the core one if it was an empty subroutine reference

BEGIN {
    no strict 'refs'; no warnings 'redefine';
    my $old = \&CORE::GLOBAL::bless;
    eval {$old->()};
    $old = undef if $@ =~ m#CORE::GLOBAL::bless#;

#  Steal the system bless with a sub
#   Obtain the class
#   Create the object with the given parameters
#   Register object
#   Return the blessed object

    *CORE::GLOBAL::bless = sub {
        my $class = $_[1] || caller();
        my $object = $old ? $old->( $_[0],$class ) : CORE::bless $_[0],$class;
        __PACKAGE__->register( $object );
        $object;
    };
} #BEGIN

# When Perl is shutting down
#  Make sure we can do the nifty internal stuff
#  Push the shutting down sequence as the very last thing we'll do

END {
    require B;
    push @{B::end_av()->object_2svref},\&_shutting_down;
print STDERR "*\n" if DEBUG;
} #END

# Satisfy -require-

1;

#---------------------------------------------------------------------------
#
# Class methods
#
#---------------------------------------------------------------------------
# register
#
# Register one or more objects with ogd.  Also used internally.
#
#  IN: 1 class (ignored)
#      2..N objects to register

sub register {

# Lose the class
# Store weakened references to the object in the global list

    shift;
print STDERR "+".(@_)."\n" if DEBUG;
    weaken( $object[@object] = $_ ) foreach @_;

# Remember current number of objects registered (ever)
# Increment for number of objects registered
# If a cleanup is needed
#  Remember the number of objects before cleanup started
#  For all of the elements in reverse order (must access by index!)
#   Remove the entry if it is not defined

    my $old = $registered;
    $registered += @_;
    if (($registered >> CLEANUP) > ($old >> CLEANUP)) {
        my $before = @object;
        foreach (reverse 0..$#object) {
            splice @object,$_,1 unless defined $object[$_];
        }
print STDERR "-$before->".(@object)."\n" if DEBUG and $before > @object;
    }
} #register

#---------------------------------------------------------------------------
#
# Internal methods
#
#---------------------------------------------------------------------------
# _shutting_down
#
# The subroutine that will be called at the very, very end

sub _shutting_down {

# Initialize hash with packages handled
# Initialize counter of how many done
# While there are objects to process
#  Obtain newest object, reloop if it is already dead
#  Mark the package as used
#  Execute the DESTROY method on it (let it know it's being forced)

    my %package;
    my $done = 0;
    foreach (reverse 0..$#object) {
        next unless defined $object[$_];
        $package{blessed $object[$_]}++;
        $object[$_]->DESTROY( 1 );
$done++ if DEBUG;
    }
print STDERR "!$done\n" if DEBUG;

# Make sure we'll be silent about the dirty stuff
# Replace DESTROY subs of all packages found with an empty stub

    no strict 'refs'; no warnings 'redefine';
print STDERR qq{x@{[map { "$_($package{$_})" } sort keys %package]}\n} if DEBUG;
    *{$_.'::DESTROY'} = \&_destroy foreach keys %package;
} #_shutting_down

#---------------------------------------------------------------------------
# _destroy
#
#  IN: 1 instantiated object (ignored)
#
# This is the empty DESTROY stub that replaces any actual DESTROY subs
# after all objects have been destroyed.

sub _destroy { } #_destroy

#---------------------------------------------------------------------------

__END__

=head1 NAME

ogd - ordered global destruction

=head1 SYNOPSIS

 perl -mogd yourscript.pl # recommended

 export PERL5OPT=-mogd
 perl yourscript.pl

 use ogd;
 ogd->register( @object ); # for objects from XSUBs only

=head1 VERSION

This documentation describes version 0.03.

=head1 DESCRIPTION

This module adds ordered destruction of objects stored in global variables
in LIFO order during global destruction.

Ordered global destruction is only applicable to objects stored in non-lexical
variables (even if they are in file scope).  Apparently Perl destroys all
objects stored file-level lexicals B<before> the first END block is called.

=head1 THE PROBLEM

If you store objects in global variables, and those objects contain
references to other objects stored in global variabkes, then you cannot be
sure of the order in which these objects are destroyed when executing of
Perl is stopped (by reaching the end of the script, or by an C<exit()>).

To get the proper behaviour, it is better to use file lexical variables.
But sometimes this is not possible, e.g. when you're using L<AutoLoader>.

The random way these objects are destroyed, can sometimes be a problem.
This pragma is intended to replace this random behaviour by a deterministic
behaviour.

=head1 THEORY OF OPERATION

The C<ogd> pragma install its own version of the C<bless()> system function.
This version keeps a list of weakened references to each and every object
created during the execution of Perl.  A cleanup run is done every 1024
objects that have been created, to reduce memory usage of this list of
weakened references.

When execution of Perl stops and C<END> code blocks are starting to get
called, an internal subroutine is added as the very last END code block to be
executed.  This is when the L<B> module is loaded to achieve this feat.

Once all other END code blocks have been executed, the internal subroutine
loops through all still valid weakened references in LIFO (Last In, First Out)
order and executes the C<DESTROY> method on them.  In case the DESTROY method
would like to differentiate between a "real" object destruction, or a forced
one, the parameter "1" is given to the DESTROY method.  While looping through
the list of objects, a list of packages in which still valid objects were
available, is built.

When DESTROY has been called on all objects, the internal sub loops through
all the packages it has seen and installs an empty DESTROY subroutine in
those packages.

The internal sub then relinquishes control back to Perl, which will then
call DESTROY on all the objects it still thinks are valid (in more or less
random order).  Since the DESTROY methods have all been replaced by empty
stubs, this is effectively a noop.

=head1 CLASS METHODS

=head2 register

 ogd->register( @object ); # only for blessed objects created in XSUBs

Not all blessed objects in Perl are necessarily created with "bless": they can
also be created in XSUBs and thereby bypass the registration mechanism that
ogd installs for "bless".  For those cases, it is possible to register objects
created in such a manner by calling the "register" class function.  Any object
passed to it will be registered.

=head1 REQUIRED MODULES

 B (any)
 Scalar::Util (any)

=head1 ORDER OF LOADING

Since the C<ogd> pragma installs its own version of the C<bless()> system
function and it can not work without that special version of bless (unless
you wish to L<register> your objects yourself).  This means that the C<ogd>
pragma needs to be loaded B<before> any modules that you want the special
functionality of C<ogd> to be applied to.

This can be achieved by loading the module from the command line (with the
C<-m> or C<-M> option), or by adding loading of the C<ogd> pragma in the
C<PERL5OPT> environment variable.

=head1 DEBUGGING

In order to facilitate debugging and testing of C<ogd>, the C<OGD_DEBUG>
environment variable can be set to a numeric value before loading the C<ogd>
pragma for the first time.  Currently, only the value B<1> is supported.
If set, the following messages will be sent to STDERR:

=over 2

=item object registration

As soon as one or more objects are registered, a line starting with "+",
followed by the number of objects registered, followed by a newline, will
be sent to STDERR.  Since this usually happens when the C<bless()> function
is executed, you will usually see this as:

 +1

on STDERR.

=item list cleanup

If a list cleanup is done (by default, every 1024 object registrations), and
destroyed objects have been removed, a line starting with "-", followed by
the original number of elements in the list, followed by "->", the number
of objects left after cleanup, and a newline.  You would e.g. see this as:

 -1024->564

on STDERR.

=item END block executed

As soon as the END block of C<ogd> itself is executed, a "*" followed by a
newline is sent to STDERR:

 *

=item objects destroyed

As soon as all of the valid objects registered have been called with the
DESTROY method, a "!" followed by the number of objects handled, will be sent
to STDERR.  E.g.:

 !234

=item packages patched

All of the packages of which the DESTROY method has been replaced by an
empty stub, followed by the number of objects forcibly destroyed of that
class between parentheses, will be sent to STDERR prefixed with "x".  For
instance:

 *Foo(123) Bar(234) Baz(13)

=back

=head1 CLEANUP

In order to reduce the memory requirements of C<ogd>, a regular cleanup is
performed on the list of registered objects (which may contain reference to
already destroyed objects).  By default, this happens every 1024 object
registrations, but this can be changed by setting the environment variable
C<OGD_CLEANUP> to a numeric value before loading C<ogd> the first time.  The
value represents the power of 2 at which a cleanup will be performed: by
default this is 10 (as 2**10 = 1024), but any other positive integer value is
allowed (allowing for more or lesser aggressive cleanup checks).

=head1 TODO

Maybe an C<after> and C<before> class method should be added to manipulate
the order in which objects will be destroyed at global destruction?

Examples should be added.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 ACKNOWLEDGEMENTS

Mark Jason Dominus for the initial impetus.  Yitzchak Scott-Thoennes for
the suggestion of using the B module.  Inspired by similar work on
L<Thread::Bless>.

=head1 COPYRIGHT

Copyright (c) 2004, 2012 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Thread::Bless>.

=cut
