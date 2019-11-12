package Thread::Bless;

# Make sure we have version info for this module
# Make sure we do everything by the book from now on

$VERSION = '0.07';
use strict;

# Make sure we can find out the refaddr of an object and weaken it

use Scalar::Util qw(blessed refaddr weaken);

# Thread local hash keyed to name of package being handled

our %handled;

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

#  Obtain the reference to the curren "bless" function
#  Steal the system bless with a sub
#   Obtain the class
#   Create the object with the given parameters
#   Save weakened ref keyed to address if objects of this package are handled
#   Return the blessed object

    *CORE::GLOBAL::bless = sub {
        my $class = $_[1] || caller();
        my $object = $old ? $old->( $_[0],$class ) : CORE::bless $_[0],$class;
        register( __PACKAGE__,$object );
        $object;
    };
} #BEGIN

# Satisfy -require-

1;

#---------------------------------------------------------------------------

# standard Perl features

#---------------------------------------------------------------------------
#  IN: 1 class
#      2..N method/value hash

sub import {

# Obtain the default class we're doing this for
# Initialize array for all classes
# Allow for dirty tricks here

    my $class = [scalar caller()];
    my @all = $class->[0];
    no strict 'refs';

# Drop the class
# While there are parameters to be handled
#  Obtain method and value
#  If it is a package setting
#   Obtain the associated package names
#   Save the class names for later checks
#   And make sure the default setting for DESTROY applies there
#  Elseif it is a known method
#   Call class method for all classes
#  Else
#   Let the world know we don't know how to handle this

    shift;
    while (@_) {
        my ($method,$value) = (shift,shift);
        if ($method eq 'package') {
            $class = ref( $value ) ? $value : [$value];
            push @all,@{$class};
            destroy->( $_,0 ) foreach @{$class};
        } elsif ($method =~ m#^(?:destroy|fixup|initialize)$#) {
            $method->( $_,$value ) foreach @{$class};
        } else {
            warn "Don't know how to handle '$method' in ".__PACKAGE__."->import\n";
        }
    }

# Make sure we know about all the classes if we don't already
# Make sure we don't do anything for 'main'

    $handled{$_} ||= {} foreach @all;
    delete $handled{'main'};
} #import

#---------------------------------------------------------------------------
# This should really just be a subroutine called INIT, but unfortunately,
# you cannot call a subroutine named INIT from a program, so we call the
# subroutine that does the actual work "initialize" and let the INIT block
# goto this subroutine to do the actual work.

sub initialize {

# Allow for tricky stuff without warnings
# For all the classes that we're doing
#  Obtain the reference to the settings of this class
#  Reloop if we did this one before
#  Obtain the reference to the current DESTROY method (if any)

    no strict 'refs'; no warnings 'redefine';
    while (my $class = each %handled) {
        my $settings = $handled{$class};
        next if $settings->{'DESTROY'};
        my $old = $settings->{'DESTROY'} = $class->can( 'DESTROY' );

#  Put our DESTROY method in there which
#   Remove the object ref from the hash, keep flag whether existed
#   Calls the old if there is an old and this object should be handled

        *{$class.'::DESTROY'} = sub {
            my $existed = delete $settings->{'object'}->{refaddr $_[0]};
            goto &$old if $old and ($settings->{'destroy'} or $existed);
        };
    }
} #initialize
INIT { goto &initialize } #INIT

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)

sub CLONE {

# For all of the packages that are being handled
#  Reloop if objects of this package should not be fixupped
#  Ensure we have a code reference of the fixup subroutine

    while (my ($class,$settings) = each %handled) {
        next unless my $sub = $settings->{'fixup'};

#  For all of the objects of this package
#   Call the fixup routine for this object

        while (my ($adress,$object) = each %{$settings->{'object'}}) {
           $sub->( $object );
        }
    }
} #CLONE

#---------------------------------------------------------------------------

# class methods

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new setting of destroy flag
# OUT: 1 current setting of destroy flag

sub destroy {

# Obtain the class
# Set new destroy flag if one specified
# Return current setting

    my $class = shift; $class = caller() if $class eq __PACKAGE__;
    $handled{$class}->{'destroy'} = $_[0] if @_;
    $handled{$class}->{'destroy'};
} #destroy

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new subroutine specification (undef to disable)
# OUT: 1 current code reference

sub fixup {

# Obtain the class
# If new fixup subroutine specified
#  Set it
# Return current setting

    my $class = shift; $class = caller() if $class eq __PACKAGE__;
    if (@_) {
        $handled{$class}->{'fixup'} = eval {
         ref( $_[0] ) ? $_[0] : \&{$_[0] =~ m#::# ? $_[0] : $class.'::'.$_[0]};
        }; # passing undef causes eval to fail and undef to be stored
    }
    $handled{$class}->{'fixup'};
} #fixup

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2..N objects to register

sub register {

# Lose the class
# For all objects specified
#  Reloop if we're not handling this class
#  Register this object with a weakened reference, keyed by address

    shift;
    foreach (@_) {
        next unless my $settings = $handled{blessed $_};
        weaken( $settings->{'object'}->{refaddr $_} = $_ );
    }
} #register

#---------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Bless - make blessed objects thread-aware

=head1 SYNOPSIS

    use Thread::Bless;     # make objects of this class thread-aware

    use Thread::Bless      # for your own module
     destroy => 1,         # default: 0 = original thread only
     fixup   => 'subname', # default: undef = no special cloning
    ;

    sub new { bless {},shift } # bless now thread aware for selected modules

    Thread::Bless->destroy( 0|1 );       # set/adapt destroy setting
    $destroy = Thread::Bless->destroy;   # obtain setting

    Thread::Bless->fixup( \&fixup_sub ); # set/adapt fixup sub later
    Thread::Bless->fixup( undef );       # disable fixup sub
    $fixup = Thread::Bless->fixup;       # obtain setting

    use Thread::Bless (        # provide settings for other packages
     package => 'Foo',                       # Foo
      fixup => sub { 'Fixup for Foo' },      # destroy => 0 implied
     package => 'Bar',                       # Bar, destroy => 0, no fixup
     package => [qw(Baz Baz::Boo Baz::Bee)], # listed modules
      destroy => 1,                          # destroy also in threads
      fixup => 'Baz::fixup',                 # call this sub for fixup
    );

    Thread::Bless->register( @object ); # for objects from XSUBs only

=head1 DESCRIPTION

                  *** A note of CAUTION ***

 This module only functions on Perl versions 5.8.0 and later.
 And then only when threads are enabled with -Dusethreads.  It
 is of no use with any version of Perl before 5.8.0 or without
 threads enabled.

                  *************************

This module adds two features to threads that are sorely missed by some.

The first feature is that the DESTROY method is called only on the object if
the object is destroyed in the thread it was created in.  This feature is
automatically activated when Thread::Bless is used.

The second feature is that an optional fixup method is called on the object
(automatically by Thread::Bless) just after the object is cloned (automatically
by Perl) when a thread is started.  This is needed if the object contains
(references to) data structures that are not automatically handled by Perl.

Both features can be switched on/off seperately at compile or runtime to
provide the utmost flexibility.

For external modules that need to be thread aware but aren't yet (most notably
the ones that cannot handle having DESTROY called when cloned versions are
destroyed in threads), you can also activate Thread::Bless on them.

=head1 CLASS METHODS

These are the class methods.

=head2 destroy

 Thread::Bless->destroy( 0 );        # call DESTROY on original only

 Thread::Bless->destroy( 1 );        # call DESTROY on all objects

 $destroy = Thread::Bless->destroy;  # return current setting

The input parameter recognizes the following values:

=over 2

=item original (0)

If the value B<0> is specified, then B<only> objects will have the DESTROY
method called on them in the thread in which they were created.  This is the
default setting.

=item all (1)

If the value B<1> is specified, then B<all> objects will have the DESTROY
method called on them when they are going out of scope.

=back

=head2 fixup

 Thread::Bless->fixup( undef );             # don't execute anything on cloning

 Thread::Bless->fixup( 'fixup' );           # call 'fixup' as an object method

 Thread::Bless->fixup( \&fixup );           # code reference is also ok

 $fixup = Thread::Bless->fixup;             # return current code reference

The "fixup" class method sets and returns the subroutine that will be executed
when an object of the class from which this class method is called.

=head2 initialize

 Thread::Bless->initialize;  # only needed in special cases

The "initialize" class method is needed B<only> in an environment where
modules are loaded at runtime with "require" or "eval" (such as the L<MOD_PERL>
environment).  It runs the initializations that are normally run automatically
in "normal" Perl environments.

=head2 register

 Thread::Bless->register( @object ); # only for blessed objects created in XSUBs

Not all blessed objects in Perl are necessarily created with "bless": they can
also be created in XSUBs and thereby bypass the registration mechanism that
Thread::Bless installs for "bless".  For those cases, it is possible to
register objects created in such a manner by calling the "register" class
function.  Any object passed to it will be registerd B<if> the class of the
object is a class for which Thread::Bless operates (either implicitely or
explicitely have the "package" class method called for).

=head1 REQUIRED MODULES

 Scalar::Util (1.08)

=head1 ORDER OF LOADING

The Thread::Bless module installs its own version of the "bless" system
function.  Without that special version of "bless", it can not work (unless
you L<register> your objects yourself).  This means that the Thread::Bless
module needs to be loaded B<before> any modules that you want the special
functionality of Thread::Bless to be applied to.

=head1 BUGS

None in the module itself (so far).  However, several Perl versions have
problems with cloned, weakened references (which are used by Thread::Bless
to keep record of the objects that need fixing up and/or destroying).  This
shows up as errors in the test-suite or lots of warnings being displayed.
Later versions of the Thread::Bless module may include XS code to circumvent
these problems for specific versions of Perl.

=over 2

=item Perl 5.8.0

Doesn't seem to handle weakened references at all: core dumps during the
test-suite with "Bizarre SvTYPE [80]" error.  It is not recommended to use
Thread::Bless on this version of Perl (yet) and therefore you cannot easily
install Thread::Bless with 5.8.0.

=item Perl 5.8.1

Issues warnings whenever a thread is shut down, one for each package that
has Thread::Bless enabled on it:

 "Attempt to free unreferenced scalar during global destruction."

So far, this warning does not seem to affect further execution of Perl.  The
test-suite should complete without finding any errors.

=item Perl 5.8.2, 5.8.3 and 5.9.0

Issues warnings whenever a thread is shut down, one for each package that
has Thread::Bless enabled on it:

 "Attempt to free unreferenced scalar: SV 0xdeadbeef during global destruction."

So far, this warning does not seem to affect further execution of Perl.  The
test-suite should complete without finding any errors.

=back

Futhermore, some interaction with L<Test::Harness> causes the warning:

 Too late to run INIT block at .../Thread/Bless.pm line NNN.

to be displayed during testing.  It does not seem to affect the outcome of the
test.  See also L</"MOD_PERL"> for more information about INIT {} related
issues.

=head1 MOD_PERL

This module's functioning depends on running the INIT {} subroutine
automatically when Perl starts executing.  However, this does B<not> happen
when running under mod_perl: the INIT state has passed long before this
module is loaded, see

 L<http://perl.apache.org/docs/1.0/guide/porting.html#CHECK_And_INIT_Blocks>

for more information.  Therefore this module does not work correctly unless
you execute this special initialization check yourself.  This, fortunately,
is easy to do, by adding:

 Thread::Bless->initialize;

Executing the "initialize" class method is enough to do the initializations
that Thread::Bless needs (provided Thread::Bless was loaded B<before> any of
the modules to which it should apply its magic).  And to ensure full
compatibility with this and future versions of this module, Perl and mod_perl,
you can call this class method as many times as you want: only modules that
have not been initialized before, will be initialized when this class method
is executed.

=head1 TODO

Examples should be added.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 ACKNOWLEDGEMENTS

Stas Bekman for the initial impetus, comments and suggestions.

=head1 COPYRIGHT

Copyright (c) 2003-2004 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<threads>, L<mod_perl>.

=cut
