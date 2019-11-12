use 5.014;
#package Thread::Queue::Any '1.15'; # not supported by PAUSE or MetaCPAN :-(
package Thread::Queue::Any;         # please remove if no longer needed

# initializations
our @ISA= qw( Thread::Queue );
our $VERSION= '1.15';               # please remove if no longer needed

# be as verbose as possble
use warnings;

# modules that we need
use Thread::Queue (); # no need to pollute namespace
BEGIN {
    *ISHASH = sub () { $Thread::Queue::VERSION >= 3 }
}

# synonym for dequeue_dontwait
{
    no warnings 'once';
    *dequeue_nb = \&dequeue_dontwait;
}

# thread local settings
my $SERIALIZER;
my $FREEZE;
my $THAW;

# satisfy -require-
1;

#-------------------------------------------------------------------------------
#
# Class methods
#
#-------------------------------------------------------------------------------
#  IN: 1 class (not used)
# OUT: 1 code ref used for thawing

sub THAW { $THAW } #THAW

#-------------------------------------------------------------------------------
#
# Instance methods
#
#-------------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N parameters to be passed as a set onto the queue

sub enqueue {
    return shift->SUPER::enqueue( $FREEZE->( \@_ ) );
} #enqueue

#-------------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N parameters returned from a set on the queue

sub dequeue {
    return wantarray
      ? @{ $THAW->( shift->SUPER::dequeue ) }
      : $THAW->( shift->SUPER::dequeue )->[0];
} #dequeue

#-------------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N parameters returned from a set on the queue

sub dequeue_dontwait {
    my $ref= shift->SUPER::dequeue_nb or return;
    return wantarray
      ? @{ $THAW->($ref) }
      : $THAW->($ref)->[0];
} #dequeue_dontwait

#-------------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N parameters returned from a set on the queue

sub dequeue_keep {

    # make sure we're the only one
    lock( ISHASH ? $_[0] : @{ $_[0] } );

    my $ref= ( ISHASH ? shift->{queue}->[0] : shift->[0] ) or return;
    return wantarray
      ? @{ $THAW->($ref) }
      : $THAW->($ref)->[0];
} #dequeue_keep

#-------------------------------------------------------------------------------
#
# Standard Perl features
#
#-------------------------------------------------------------------------------
#  IN: 1 class (not used)
#      2 .. N parameter hash

sub import {
    my ( undef, %param )= @_;
    my @errors;

    # parameters we know
    my $serializer= delete $param{serializer};
    my $freeze=     delete $param{freeze};
    my $thaw=       delete $param{thaw};

    # sanity check with serializer class
    if ($serializer) {
        push @errors, "Cannot serialize with '$serializer', already using '$SERIALIZER'"
          if $SERIALIZER and $serializer ne $SERIALIZER;
        push @errors, "Cannot serialize with '$serializer', already using freeze/thaw"
          if !$SERIALIZER and ( $FREEZE or $THAW );
        push @errors, "Cannot specify 'freeze', already using serializer '$serializer'"
          if $freeze;
        push @errors, "Cannot specify 'thaw', already using serializer '$serializer'"
          if $thaw;
    }

    # sanity if no serializer, but just freeze / thaw
    elsif ($freeze) {
        push @errors, "Cannot specify 'freeze', already using serializer '$SERIALIZER'"
          if $SERIALIZER;
        push @errors, "Cannot specify new 'freeze', already using freeze/thaw"
          if !$SERIALIZER and $FREEZE;
        push @errors, "Must also specify 'thaw' if specifying 'freeze'"
          if !$thaw;
    }

    # sanity if no serializer or freeze, but with thaw
    elsif ($thaw) {
        push @errors, "Cannot specify 'thaw', already using serializer '$SERIALIZER'"
          if $SERIALIZER;
        push @errors, "Cannot specify new 'thaw', already using freeze/thaw"
          if !$SERIALIZER and $THAW;
    }

    # huh?
    if ( my @huh= keys %param ) {
        push @errors, "Don't know what to do with: @huh";
    }
    die join "\n", "Found the following errors:", @errors
      if @errors;

    # found specific serializer
    if ($serializer) {
        _set_serializer($serializer);
    }

    # found separate freeze/thaw subs
    elsif ($freeze) {
        $FREEZE= $freeze;
        $THAW=   $thaw;
    }

    # use default serializer
    else {
        _set_serializer('Storable');
    }

    return;
} #import

#-------------------------------------------------------------------------------
#
# Internal subroutines
#
#-------------------------------------------------------------------------------
# _set_serializer
#
#  IN: 1 class

sub _set_serializer {
    my ($class)= @_;

    # sanity check
    my @errors;
    eval "require $class; 1" or push @errors, $@;
    my $freeze= $class->can( 'freeze' )
      or push @errors, "$class does not provide a 'freeze' method";
    my $thaw=   $class->can( 'thaw' )
      or push @errors, "$class does not provide a 'thaw' method";

    # huh?
    die join "\n", "Found the following errors:", @errors
      if @errors;

    # it's all ok
    $SERIALIZER= $class;
    $FREEZE=     $freeze;
    $THAW=       $thaw;

    return;
} #_set_serializer

#-------------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Queue::Any - thread-safe queues for any data-structure

=head1 SYNOPSIS

    use Thread::Queue::Any;
    my $q= Thread::Queue::Any->new;
    $q->enqueue("foo", ["bar"], {"zoo"});
    my ( $foo, $bar, $zoo )= $q->dequeue;
    my ( $foo, $bar, $zoo )= $q->dequeue_dontwait;
    my ( $iffoo, $ifbar, $ifzoo)= $q->dequeue_keep;
    my $left= $q->pending;

    # specify class with "freeze" and "thaw" methods
    use Thread::Queue::Any serializer => 'Storable';

    # specify custom freeze and thaw subroutines
    use Thread::Queue::Any freeze => \&solid, thaw => \&liquid;

    # thaw hook for subclasses
    package Thread::Queue::Any::Foo;
    @ISA= 'Thread::Queue::Any';
    my $THAW= __PACKAGE__->THAW;

=head1 VERSION

This documentation describes version 1.15.

=head1 DESCRIPTION

                    *** A note of CAUTION ***

 This module only functions if threading has been enabled when building
 Perl, or if the "forks" module has been installed on an unthreaded Perl.

                    *************************

A queue, as implemented by C<Thread::Queue::Any> is a thread-safe 
data structure that inherits from C<Thread::Queue>.  But unlike the
standard C<Thread::Queue>, you can pass (a reference to) any data
structure to the queue.

Apart from the fact that the parameters to C<enqueue> are considered to be
a set that needs to be enqueued together and that C<dequeue> returns all of
the parameters that were enqueued together, this module is a drop-in
replacement for C<Thread::Queue> in every other aspect.

Any number of threads can safely add elements to the end of the list, or
remove elements from the head of the list.

=head1 CLASS METHODS

=head2 new

 $queue= Thread::Queue::Any->new;

The C<new> function creates a new empty queue.

=head2 THAW

 $THAW= $subclass->THAW;

Return the code reference for de-serializing enqueued data.  Intended to be
used by subclasses only, such as L<Thread::Queue::Any::Monitored>.

=head1 OBJECT METHODS

=head2 enqueue LIST

 $queue->enqueue( 'string', $scalar, [], {} );

The C<enqueue> method adds a reference to all the specified parameters on to
the end of the queue.  The queue will grow as needed.

=head2 dequeue

 ( $string, $scalar, $listref, $hashref )= $queue->dequeue;

 $string= $queue->dequeue;          # first only in scalar context

The C<dequeue> method removes a reference from the head of the queue,
dereferences it and returns the resulting values.  If the queue is currently
empty, C<dequeue> will block the thread until another thread C<enqueue>s.

If called in scalar context, only the first value will be returned.  This is
only recommended if L<enqueue> is always only called with one parameter.

=head2 dequeue_dontwait

 ( $string, $scalar, $listref, $hashref )= $queue->dequeue_dontwait;

 $string= $queue->dequeue_dontwait; # first only in scalar context

The C<dequeue_dontwait> method, like the C<dequeue> method, removes a
reference from the head of the queue, dereferences it and returns the
resulting values.  Unlike C<dequeue>, though, C<dequeue_dontwait> won't wait
if the queue is empty, instead returning an empty list if the queue is empty.

For compatibility with L<Thread::Queue>, the name "dequeue_nb" is available
as a synonym for this method.

If called in scalar context, only the first value will be returned.  This is
only recommended if L<enqueue> is always only called with one parameter.

=head2 dequeue_keep

 ( $string, $scalar, $listref, $hashref )= $queue->dequeue_keep;

 $string= $queue->dequeue_keep;     # first only in scalar context

The C<dequeue_keep> method, like the C<dequeue_dontwait> method, takes a
reference from the head of the queue, dereferences it and returns the
resulting values.  Unlike C<dequeue_dontwait>, though, the C<dequeue_keep>
B<won't remove> the set from the queue.  It can therefore be used to test if
the next set to be returned from the queue with C<dequeue> or
C<dequeue_dontwait> will have a specific value.

If called in scalar context, only the first value will be returned.  This is
only recommended if L<enqueue> is always only called with one parameter.

=head2 pending

 $pending= $queue->pending;

The C<pending> method returns the number of items still in the queue.

=head1 USING ANOTHER SERIALIZER

Passing unshared values between threads is accomplished by serializing the
specified values when enqueuing and de-serializing the queued value on
equeuing.  This allows for great flexibility at the expense of more
CPU usage.  It also limits what can be passed, as e.g. code references can
B<not> be serialized with the default serializer and therefore not be passed.

By default, the L<Storable> module is used to serialize data.  If you want to
use a different serializer, you can specify this when you load this module
with the C<serializer> parameter:

 use Thread::Queue::Any serializer => 'Thread::Serialize';

The value of the parameter is the name of the class that will provide a
C<freeze> and C<thaw> subroutine.  It will be automatically loaded if
specified.

If you happen to have subroutines in another module with a different name,
you can also specify the C<freeze> and C<thaw> parameter with a code reference
of the subroutine to be called.  So the above example could also be specified
as:

 use Thread::Serialize;
 use Thread::Queue::Any
   freeze => \&Thread::Serialize::freeze,
   thaw   => \&Thread::Serialize::thaw,
 ;

=head1 REQUIRED MODULES

 Test::More (0.88)
 Thread::Queue (any)

=head1 INSTALLATION

This distribution contains two versions of the code: one maintenance version
for versions of perl < 5.014 (known as 'maint'), and the version currently in
development (known as 'blead').  The standard build for your perl version is:

 perl Makefile.PL
 make
 make test
 make install

This will try to test and install the "blead" version of the code.  If the
Perl version does not support the "blead" version, then the running of the
Makefile.PL will *fail*.  In such a case, one can force the installing of
the "maint" version of the code by doing:

 perl Makefile.PL maint

Alternately, if you want automatic selection behavior, you can set the
AUTO_SELECT_MAINT_OR_BLEAD environment variable to a true value.  On Unix-like
systems like so:

 AUTO_SELECT_MAINT_OR_BLEAD=1 perl Makefile.PL

If your perl does not support the "blead" version of the code, then it will
automatically install the "maint" version of the code.

Please note that any additional parameters will simply be passed on to the
underlying Makefile.PL processing.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2002, 2003, 2007, 2012 Elizabeth Mattijsen <liz@dijkmat.nl>.
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<threads>, L<threads::shared>, L<Thread::Queue>, L<Storable>.

=cut
