package Thread::Tie;

# Default thread to be used
# When we're compiling
#  Make sure we can start the thread
#  And start the default thread
# Make sure the default thread is shut down when we're done

my $THREAD;
BEGIN {
    require Thread::Tie::Thread;
    $THREAD = Thread::Tie::Thread->new;
}
END { Thread::Tie->shutdown }

# Make sure we have version info for this module
# Make sure we do everything by the book from now on

$VERSION = '0.13';
use strict;

# Clone detection logic

our $CLONE = 0;

# Satisfy -require-

1;

#---------------------------------------------------------------------------

# class methods

#---------------------------------------------------------------------------
#  IN: class (ignored)

sub shutdown {

# If there is a default thread running
#  Shut it down
#  Mark it shut down

    if ($THREAD) {
        $THREAD->shutdown;
	undef( $THREAD );
    }
} #shutdown

#---------------------------------------------------------------------------

# instance methods

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 module to which variable is tied in thread

sub module { shift->{'module'} } #module

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 reference to semaphore for lock()

sub semaphore { shift->{'semaphore'} } #semaphore

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 Thread::Tie::Thread object hosting this variable

sub thread { shift->{'thread'} } #thread

#---------------------------------------------------------------------------

# internal methods

#---------------------------------------------------------------------------
#  IN: 1 class for which to bless
#      2 default module to tie to in thread
#      4 reference to hash containing parameters
#      5..N any parameters
# OUT: 1 instantiated object

sub _tie {

# Obtain the class
# Obtain the default module
# Create the tie subroutine name
# Obtain the hash reference
# Make it a blessed object

    my $class = shift;
    my $default_module = shift;
    my $tie_sub = 'TIE'.uc($default_module);
    my $self = shift || {};
    bless $self,$class;

# Set the thread that will be used
# Set the module that should be used to tie to
# Save the clone level

    my $thread = $self->{'thread'} ||= $THREAD ||= ($class.'::Thread')->new;
    my $module = $self->{'module'} ||= $class.'::'.$default_module;
    $self->{'CLONE'} = $CLONE;

# Obtain the reference to the thread shared ordinal area
# Make sure we're the only one doing stuff now
# Save the current ordinal number on the tied object, incrementing on the fly
# Obtain reference to the method to be executed

    my $ordinal = $thread->{'ordinal'};
    {lock( $ordinal );
     $self->{'ordinal'} = $$ordinal++;
     my $code = $self->can( '_handle' );

# Use additional modules if we have additional modules that should be used
# Eval additional code if we have additional code to execute

     $self->_code_uc_field( $code,'use' ) if exists( $self->{'use'} );
     $self->_code_uc_field( $code,'eval' ) if exists( $self->{'eval'} );

# Make sure that the module is available in the thread
# Handle the tie request in the thread

     $code->( $self, 'USE', $module );
     $code->( $self, $module.'::'.$tie_sub, @_ );
    } #$ordinal

# Create a semaphore for external locking
# Save a reference to it in the object
# Return the instantiated object

    my $semaphore : shared;
    $self->{'semaphore'} = \$semaphore;
    $self;
} #_tie

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 subroutine to execute inside the thread
#      3..N data to be sent (optional)
# OUT: 1..N result of action (optional)

sub _handle {

# Obtain the object
# Obtain the subroutine
# Obtain the thread object being used
# Return now if there is no thread

    my $self = shift;
    my $sub = shift;
    my $thread = $self->{'thread'};
    return unless $thread; # needed for pbs during global destruction

# If there is no thread anymore
#  Return now if we're destroying or untieing
#  Die now with error message, we can't handle anymore
# Handle it using the thread object

    unless ($thread->tid) {
        return if $sub =~ m#(?:DESTROY|UNTIE)$#;
        die "Cannot handle $sub after shutdown\n";
    }
    $thread->_handle( $sub,$self->{'ordinal'},@_ );
} #_handle

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 code reference to execute
#      3 name of field to check

sub _code_uc_field {

# Obtain the parameters
# Create uppercase version of field name (=command to execute in thread)

    my ($self,$code,$field) = @_;
    my $FIELD = uc($field);

# If it is an (array) reference
#  Use all the modules specified in the thread
# Else (just one extra module)
#  Just use that single module in the thread

     if (ref( $self->{$field} )) {
         $code->( $self, $FIELD, $_ ) foreach @{$self->{$field}};
     } else {
         $code->( $self, $FIELD, $self->{$field} );
     }
} #_code_uc_field

#---------------------------------------------------------------------------

# standard Perl features

#---------------------------------------------------------------------------

# Increment the current clone value (mark this as a cloned version)

sub CLONE { $CLONE++ } #CLONE

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N input parameters
# OUT: 1..N output parameters

sub AUTOLOAD {

# Obtain the object
# Obtain the subroutine name
# Handle the command with the appropriate data

    my $self = shift;
    (my $sub = $Thread::Tie::AUTOLOAD) =~ s#^.*::#$self->{'module'}::#;
    $self->_handle( $sub,@_ );
} #AUTOLOAD

#---------------------------------------------------------------------------
#  IN: 1 instantiated object

sub DESTROY {

# Obtain the object
# Return if we're not in the originating thread
# Handle the command with the appropriate data

    my $self = shift;
    return if $self->{'CLONE'} != $CLONE;
    $self->_handle( $self->{'module'}.'::DESTROY',@_ );
} #DESTROY

#---------------------------------------------------------------------------
#  IN: 1 class for which to bless
#      2 reference to hash containing parameters
#      3 initial value of scalar
# OUT: 1 instantiated object

sub TIESCALAR { shift->_tie( 'Scalar',@_ ) } #TIESCALAR

#---------------------------------------------------------------------------
#  IN: 1 class for which to bless
#      2 reference to hash containing parameters
# OUT: 1 instantiated object

sub TIEARRAY { shift->_tie( 'Array',@_ ) } #TIEARRAY

#---------------------------------------------------------------------------
#  IN: 1 class for which to bless
#      2 reference to hash containing parameters
# OUT: 1 instantiated object

sub TIEHASH { shift->_tie( 'Hash',@_ ) } #TIEHASH

#---------------------------------------------------------------------------
#  IN: 1 class for which to bless
#      2 reference to hash containing parameters
#      3..N any parameters passed to open()
# OUT: 1 instantiated object

sub TIEHANDLE { shift->_tie( 'Handle',@_ ) } #TIEHANDLE

#---------------------------------------------------------------------------
#  IN: 1 instantiated object

sub UNTIE {

# Obtain the object
# Return if we're not in the originating thread
# Handle the command with the appropriate data

    my $self = shift;
    return if $self->{'CLONE'} != $CLONE;
    $self->_handle( 'UNTIE',$self->{'ordinal'} );
} #UNTIE

#---------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Tie - tie variables into a thread of their own

=head1 VERSION

This documentation describes version 0.13.

=head1 SYNOPSIS

    use Thread::Tie; # use as early as possible for maximum memory savings

    # use default thread + tieing + create thread when needed
    tie $scalar, 'Thread::Tie';
    tie @array, 'Thread::Tie';
    tie %hash, 'Thread::Tie';
    tie *HANDLE, 'Thread::Tie';

    # use alternate implementation
    tie $scalar, 'Thread::Tie',
     { module => 'Own::Tie::Implementation', # used automatically
       use    => 'Use::This::Module::Also',  # optional, also as []
       eval   => 'arbitrary Perl code',      # optional
     };

    # initialize right away
    tie $scalar, 'Thread::Tie', {}, 10;
    tie @array, 'Thread::Tie', {}, qw(a b c);
    tie %hash, 'Thread::Tie', {}, (a => 'A', b => 'B', c => 'C');
    tie *HANDLE, 'Thread::Tie', {},'>:layer','filename';
    
    # create an alternate thread and use that
    my $tiethread = Thread::Tie::Thread->new;
    tie $scalar, 'Thread::Tie', {thread => $tiethread};

    # object methods
    my $tied = tie stuff,'Thread::Tie',parameters;
    my $tied = tied( stuff );
    my $semaphore = $tied->semaphore; # scalar for lock()ing tied variable
    my $module = $tied->module;       # module tied to in thread
    my $tiethread = $tied->thread;    # thread to which variable is tied

    my $tid = $tiethread->tid;        # thread id of tied thread
    my $thread = $tiethread->thread;  # actual "threads" thread

    untie( stuff ); # calls DESTROY in thread, cleans up thoroughly

    Thread::Tie->shutdown; # shut down default handling thread
    $tiethread->shutdown;  # shut down specific thread

=head1 DESCRIPTION

                  *** A note of CAUTION ***

 This module only functions on Perl versions 5.8.0 and later.
 And then only when threads are enabled with -Dusethreads.  It
 is of no use with any version of Perl before 5.8.0 or without
 threads enabled.

                  *************************

The standard shared variable scheme used by Perl, is based on tie-ing the
variable to some very special dark magic.  This dark magic ensures that
shared variables, which are copied just as any other variable when a thread
is started, update values in all of the threads where they exist as soon as
the value of a shared variable is changed.

Needless to say, this could use some improvement.

The Thread::Tie module is a proof-of-concept implementation of another
approach to shared variables.  Instead of having shared variables exist
in all the threads from which they are accessible, shared variable exist
as "normal", unshared variables in a seperate thread.  Only a tied object
exists in each thread from which the shared variable is accesible.

Through the use of a client-server model, any thread can fetch and/or update
variables living in that thread.  This client-server functionality is hidden
under the hood of tie().  So you could say that one dark magic (the current
shared variables implementation) is replaced by another dark magic.

I see the following advantages to this approach:

=over 2

=item memory usage

This implementation circumvents the memory leak that currently
(threads::shared version 0.90) plagues any shared array or shared hash access.

=item tieing shared variables

Because the current implementation uses tie-ing, you can B<not> tie a shared
variable.  The same applies for this implementation you might say.  However,
it B<is> possible to specify a non-standard tie implementation for use
B<within> the thread.  So with this implementation you B<can> C<tie()> a
shared variable.  So you B<could> tie a shared hash to a DBM file à la
dbmopen() with this module.

=back

Of course there are disadvantages to this approach:

=over 2

=item pure perl implementation

This module is currently a pure perl implementation.  This is ok for a proof
of concept, but may need re-implementation in pure XS or in Inline::C for
production use.

=item tradeoff between cpu and memory

This implementation currently uses (much) more cpu than the standard shared
variables implementation.  Whether this would still be true when re-implemented
in XS or Inline::C, remains to be seen.

=back

=head1 tie()

You cannot activate this module with a named class method.  Instead, you
should tie() a scalar, array, hash or glob (handle).  The appropriate class
method will then be selected for you by Perl.

Whether you tie a scalar, array, hash or glob, the first parameter to tie(),
the second and third parameter (if specified) to tie() are always the same.
And the tie() always returns the same thing: the blessed Thread::Tie object
to which the variable is tied.  You may or may not need that in your
application.  If you need to do lock()ing on the tied variable, then you
need the object to be able to call the L<semaphore> method.

=head2 class to tie with

You should always tie() to the class B<Thread::Tie>.  So the second parameter
should always read B<'Thread::Tie'>.  This parameter is B<not> optional.

=head2 reference to parameter hash

The third parameter is optional.  If specified, it should be a reference to
a hash with key/value pairs.  The following fields may be specified in the
hash.

=over 2

=item module

 module => 'Your::Tie::Implementation',

The optional "module" field specifies the module to which the variable should
be tied inside the thread.  If there is no "module" field specified, a
standard tie implementation, associated with the type of the variable, will
be assumed.

Please note that you should probably B<not> use() the module yourself.  The
specified module will be use()d automatically inside the thread (only),
avoiding bloat in all the other threads.

=item use

 use => 'Additional::Module',

 use => [qw(Additional::Module::1 Additional::Module::2)],

The optional "use" field specifies one or more modules that should B<also>
be loaded inside the thread before the variable is tied.  These can e.g. be
prerequisites for the module specified in the "module" field.

A single module can be specified by its name.  If you need more than one
module to be use()d, you can specify these in an array reference.

=item eval

 eval => 'any Perl code that you like;',

The optional "eval" field specifies additional Perl code that should be
executed inside the thread before the variable is tied.  This can e.g. be
used to set up prerequisites.

Please note that the code to be executed currently needs to be specified as
a string that is valid in an eval().

=item thread

 thread => Thread::Tie::Thread->new,

 thread => $thread,

The optional "thread" field specifies the instantiated L<Thread::Tie::Thread>
object that should be used to tie the variable in.  This is only needed if
you want to use more than one thread to tie variables in, which could e.g.
be needed if there is a conflict between different tie implementations.

You can create a new thread for tie()ing with the "new" class method of the
Thread::Tie::Thread module.

=back

All the other input parameters are passed through to the tie() implementation
of your choice.  If you are using the default tie() implementation for the
type of variable that you have specified, then the input parameters have the
following meaning:

=over 2

=item scalar

 tie my $scalar,'Thread::Tie',{},10;

Initialize the tied scalar to B<10>.

=item array

 tie my @array,'Thread::Tie',{},qw(a b c);

Initialize the tied array with the elements 'a', 'b' and 'c'.

=item hash

 tie my %hash,'Thread::Tie',{},(a => 'A', b => 'B', c => 'C');

Initialize the tied hash with the keys 'a', 'b' and 'c' with values that are
the uppercase version of the key.

=item glob

 tie *HANDLE,'Thread::Tie',{},">$file";   # 2 parameter open()

 tie *HANDLE,'Thread::Tie',{},'>',$file;  # 3 parameter open()

Initialize the tied glob by calling open() with the indicated parameters.

=back

=head1 CLASS METHODS

There is only one named class method.

=head2 shutdown

 Thread::Tie->shutdown;

The "shutdown" class method shuts down the thread that is used for variables
that have been tie()d without specifying an explicit thread with the "thread"
field.  It in fact calls the "shutdown" method of the L<Thread::Tie::Thread>
module on the instantiated object of the default thread.

Any variables that were tie()d, will not function anymore.  Any variables
that are tie()d B<after> the thread was shut down, will automatically create
a new default thread.

=head1 OBJECT METHODS

The following object methods are available for the instantiated Thread::Tie
object, as returned by the tie() function.

=head2 semaphore

 my $semaphore = $tied->semaphore;

 my $semaphore = (tie my $variable,'Thread::Tie)->semaphore;

 my $semaphore = tied( $variable )->semaphore;

 {lock( $semaphore ); do stuff with tied variable privately}

The "semaphore" object method returns a reference to a shared scalar that
is associated with the tied variable.  It can be used for lock()ing access
to the tied variable.  Scalar values can be assigned to the shared scalar
without any problem: it is not used internally for anything other than to
allow the developer to lock() access to the tied variable.

=head2 module

 my $module = $tied->module;

 my $module = (tie my $variable,'Thread::Tie)->module;

 my $module = tied( $variable )->module;

The "module" object method returns the name of the module to which the
variable is tied inside the thread.  It is the same as what was (implicitely)
specified with the "module" field when the variable was tied.

=head2 thread

 my $tiethread = $tied->thread;

 my $tiethread = (tie my $variable,'Thread::Tie)->thread;

 my $tiethread = tied( $variable )->thread;

The "thread" object method returns the instantiated 'Thread::Tie::Thread'
object to which the variable is tied.  It is the same as what was
(implicetely) specified with the "thread" field when the variable was tied.

=head1 REQUIRED MODULES

 load (0.11)
 Thread::Serialize (0.07)

=head1 CAVEATS

Because transport of data structures between threads is severely limited in
the current threads implementation (perl 5.8.0), data structures need to be
serialized.  This is achieved by using the L<Thread::Serialize> library.
Please check that module for information about the limitations (of any) of
data structure transport between threads.

=head1 TODO

Examples should be added.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2002-2003, 2010 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<threads>, L<Thread::Serialize>.

=cut
