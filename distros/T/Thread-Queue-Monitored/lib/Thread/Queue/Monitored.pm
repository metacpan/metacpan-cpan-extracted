use 5.014;
#package Thread::Queue::Monitored '1.04'; # not supported by PAUSE/MetaCPAN :-(
package Thread::Queue::Monitored;         # please remove if no longer needed

# initializations
our @ISA= qw( Thread::Queue );
our $VERSION= '1.04';                     # please remove if no longer needed

# be as verbose as possible
use warnings;

# modules that we need
use Thread::Queue (); # no need to pollute namespace

# self referencing within monitoring thread
my $SELF;

# satisfy -require-
1;

#-------------------------------------------------------------------------------
# new
#
# Create a monitored queue
#
#  IN: 1 class to bless with
#      2 reference/name of subroutine doing the monitoring
#      3 value to consider end of monitoring action (default: undef)
# OUT: 1 instantiated object
#      2 (optional) thread object of monitoring thread

sub new {
    my $class= shift;
    my $param= shift;

    # sanity check
    my $monitor= $param->{monitor};
    die "Must specify a subroutine to monitor the queue" if !$monitor;

    # make sure it is a code ref
    my $namespace= caller() . '::';
    $monitor= _makecoderef( $namespace, $monitor ) if !ref($monitor);

    # get pre and post code
    my $pre= $param->{pre};
    $pre= _makecoderef( $namespace, $pre )   if $pre and !ref($pre);
    my $post= $param->{post};
    $post= _makecoderef( $namespace, $post ) if $post and !ref($post);

    # obtain the queue object
    my $self= $param->{queue}
      ? bless $param->{queue}, $class
      : $class->SUPER::new;

    # create the thread
    no strict 'refs';
    my $thread= threads->new(
     \&{ $class . '::_monitor' },
     $self,
     wantarray,
     $monitor,
     $param->{exit},	# don't care if not available: then undef = exit value
     $post,
     $pre,
     @_,
    );

    return wantarray ? ($self,$thread) : $self;
} #new

#-------------------------------------------------------------------------------
# self
#
# return singleton
#
#  IN: 1 class (ignored)
# OUT: 1 instantiated queue object

sub self { $SELF } #self

#-------------------------------------------------------------------------------
# dequeue
#
# not allowed to do this
#
#  IN: 1 instantiated object (ignored)
# OUT: 1 dequeued value (not returned)

sub dequeue { _die() } #dequeue

#-------------------------------------------------------------------------------
# dequeue_dontwait
#
# not allowed to do this
#
#  IN: 1 instantiated object (ignored)
# OUT: 1 dequeued value (not returned)

sub dequeue_dontwait { _die() } #dequeue_dontwait

#-------------------------------------------------------------------------------
# dequeue_nb
#
# not allowed to do this
#
#  IN: 1 instantiated object (ignored)
# OUT: 1 dequeued value (not returned)

sub dequeue_nb { _die() } #dequeue_nb

#-------------------------------------------------------------------------------
# dequeue_keep
#
# not allowed to do this
#
#  IN: 1 instantiated object (ignored)
# OUT: 1 dequeued value (not returned)

sub dequeue_keep { _die() } # dequeue_keep

#-------------------------------------------------------------------------------
#
# Internal subroutines
#
#-------------------------------------------------------------------------------
# _die
#
# die as if in caller
#
#  IN: 1 instantiated object (ignored)

sub _die {
    ( my $caller= ( caller(1) )[3] ) =~ s#^.*::##;
    die "You cannot '$caller' on a monitored queue";
} #_die

#-------------------------------------------------------------------------------
# _makecoderef
#
# Return coderef for given namespace / sub
#
#  IN: 1 namespace prefix
#      2 subroutine name
# OUT: 1 code reference

sub _makecoderef {
    my ( $namespace, $code )= @_;

    # ensure fully qualified
    $code= $namespace.$code if $code !~ m#::#;

    return \&{$code};
} #_makecoderef

#-------------------------------------------------------------------------------
# _monitor
#
# monitor a queue
#
#  IN: 1 queue object to monitor
#      2 flag: to keep thread attached
#      3 code reference of monitoring routine
#      4 exit value
#      5 code reference of preparing routine (if available)
#      6..N parameters passed to creation routine

sub _monitor {
    my $queue= $SELF= shift;
    threads->self->detach if !shift;
    my $monitor= shift;
    my $exit=    shift;

    # get pre/post processing
    my $post= shift || sub {};
    my $pre=  shift;
    $pre->( @_ ) if $pre;

    # processing
    my @value;
    while (1) {

        # get all values from the queue
        {
            lock( @{$queue} );
            threads::shared::cond_wait @{$queue} until @{$queue};
            @value= @{$queue};
            @{$queue}= ();
        }

        # process all values
        foreach (@value) {

            # done, we've seen the exit value
            return $post->(@_) when $exit;

            # perform the monitoring for this value
            $monitor->($_);
        }
    }
} #_monitor

#-------------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Queue::Monitored - monitor a queue for specific content

=head1 SYNOPSIS

    use Thread::Queue::Monitored;
    my ( $q, $t)= Thread::Queue::Monitored->new( {
      monitor => sub { print "monitoring value $_[0]\n" }, # is a must
      pre     => sub { print "prepare monitoring\n" },     # optional
      post    => sub { print "stop monitoring\n" },        # optional
      queue   => $queue, # use existing queue, create new if not specified
      exit    => 'exit', # default to undef
     }
    );

    $q->enqueue("foo");
    $q->enqueue(undef); # exit value by default

    @post= $t->join; # optional, wait for monitor thread to end

    $queue= Thread::Queue::Monitored->self; # "pre", "do", "post" only

=head1 VERSION

This documentation describes version 1.04.

=head1 DESCRIPTION

                    *** A note of CAUTION ***

 This module only functions if threading has been enabled when building
 Perl, or if the "forks" module has been installed on an unthreaded Perl.

                    *************************

A queue, as implemented by C<Thread::Queue::Monitored> is a thread-safe 
data structure that inherits from C<Thread::Queue>.  But unlike the
standard C<Thread::Queue>, it starts a single thread that monitors the
contents of the queue by taking new values off the queue as they become
available.

It can be used for simply logging actions that are placed on the queue. Or
only output warnings if a certain value is encountered.  Or whatever.

The action performed in the thread, is determined by a name or reference
to a subroutine.  This subroutine is called for every value obtained from
the queue.

Any number of threads can safely add elements to the end of the list.

=head1 CLASS METHODS

=head2 new

 ( $queue, $thread )= Thread::Queue::Monitored->new( {
   pre     => \&pre,
   monitor => 'monitor',
   post    => 'module::done',
   queue   => $queue, # use existing queue, create new if not specified
   exit    => 'exit', # default to undef
 } );

The C<new> function creates a monitoring function on an existing or on an new
(empty) queue.  It returns the instantiated Thread::Queue::Monitored object
in scalar context: in that case, the monitoring thread will be detached and
will continue until the exit value is passed on to the queue.  In list
context, the thread object is also returned, which can be used to wait for
the thread to be really finished using the C<join()> method.

The first input parameter is a reference to a hash that should at least
contain the "monitor" key with a subroutine reference.

The other input parameters are optional.  If specified, they are passed to the
the "pre" routine which is executed once when the monitoring is started.

The following field B<must> be specified in the hash reference:

=over 2

=item do

 monitor => 'monitor_the_queue',	# assume caller's namespace

or:

 monitor => 'Package::monitor_the_queue',

or:

 monitor => \&SomeOther::monitor_the_queue,

or:

 monitor => sub { print "anonymous sub monitoring the queue\n" },

The "monitor" field specifies the subroutine to be executed for each value
that is removed from the queue.  It must be specified as either the name of
a subroutine or as a reference to a (anonymous) subroutine.

The specified subroutine should expect the following parameter to be passed:

 1  value obtain from the queue

What the subroutine does with the value, is entirely up to the developer.

=back

The following fields are B<optional> in the hash reference:

=over 2

=item pre

 pre => 'prepare_monitoring',		# assume caller's namespace

or:

 pre => 'Package::prepare_monitoring',

or:

 pre => \&SomeOther::prepare_monitoring,

or:

 pre => sub {print "anonymous sub preparing the monitoring\n"},

The "pre" field specifies the subroutine to be executed once when the
monitoring of the queue is started.  It must be specified as either the
name of a subroutine or as a reference to a (anonymous) subroutine.

The specified subroutine should expect the following parameters to be passed:

 1..N  any parameters that were passed with the call to L<new>.

=item post

 post => 'stop_monitoring',		# assume caller's namespace

or:

 post => 'Package::stop_monitoring',

or:

 post => \&SomeOther::stop_monitoring,

or:

 post => sub {print "anonymous sub when stopping the monitoring\n"},

The "post" field specifies the subroutine to be executed once when the
monitoring of the queue is stopped.  It must be specified as either the
name of a subroutine or as a reference to a (anonymous) subroutine.

The specified subroutine should expect the following parameters to be passed:

 1..N  any parameters that were passed with the call to L<new>.

Any values returned by the "post" routine, can be obtained with the C<join>
method on the thread object.

=item queue

 queue => $queue,  # create new one if not specified

The "queue" field specifies the Thread::Queue object that should be monitored.
A new L<Thread::Queue> object will be created if it is not specified.

=item exit

 exit => 'exit',   # default to undef

The "exit" field specifies the value that will cause the monitoring thread
to seize monitoring.  The "undef" value will be assumed if it is not specified.
This value should be L<enqueue>d to have the monitoring thread stop.

=back

=head2 self

 $queue = Thread::Queue::Monitored->self; # only "pre", "do" and "post"

The class method "self" returns the object for which this thread is
monitoring.  It is available within the "pre", "do" and "post" subroutine
only.

=head1 OBJECT METHODS

=head2 enqueue

 $queue->enqueue( $value1, $value2 );
 $queue->enqueue( 'exit' ); # stop monitoring

The C<enqueue> method adds all specified parameters on to the end of the
queue.  The queue will grow as needed to accommodate the list.  If the
"exit" value is passed, then the monitoring thread will shut itself down.

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

=head1 CAVEATS

You cannot remove any values from the queue, as that is done by the monitoring
thread.  Therefore, the methods "dequeue", "dequeue_dontwait", "dequeue_nb" and
"dequeue_keep" are disabled on this object.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2002, 2003, 2007, 2012 Elizabeth Mattijsen <liz@dijkmat.nl>.
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<threads>, L<threads::shared>, L<Thread::Queue>.

=cut
