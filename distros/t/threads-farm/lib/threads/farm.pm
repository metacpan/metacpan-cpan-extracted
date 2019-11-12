package threads::farm;

# Set the version information
# Make sure we do everything by the book from now on

$VERSION = '0.02';
use strict;

# Make sure we can do threads
# Make sure we can share here
# Make sure we can super duper queues
# Make sure we can freeze and thaw (just to make sure)

use threads ();
use threads::shared qw(share cond_wait cond_broadcast);
use threads::shared::queue::any;
use Storable ();

# Satisfy -require-

1;

#---------------------------------------------------------------------------
#  IN: 1 class with which to create
#      2 reference to hash with parameters
#      3..N parameters to be passed to <pre> routine
# OUT: 1 instantiated object

sub new {

# Obtain the class
# Obtain the hash with parameters and bless it
# Create a super duper queue for it
# Set the auto-shutdown flag unless it is specified already

    my $class = shift;
    my $self = bless shift,$class;
    $self->{'queue'} = threads::shared::queue::any->new;
    $self->{'autoshutdown'} = 1 unless exists $self->{'autoshutdown'};

# Initialize the hired/fired hash, jid counter, result hash and shutdown flag
# Make sure they're all shared

    my %hired : shared;
    my %fired : shared;
    my $jid : shared = 1;
    my %result : shared;
    my $shutdown : shared = 0;
    @$self{qw(hired fired jid result shutdown)} =
     (\%hired,\%fired,\$jid,\%result,\$shutdown);

# Save a frozen value to the parameters for later hiring
# Hire the number of workers indicated
# Return the instantiated object

    $self->{'startup'} = Storable::freeze( \@_ );
    $self->hire( $self->{'workers'} );
    return $self;
} #new

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N parameters to be passed for this job
# OUT: 1 job id (jid)

sub job { 

# Obtain the object
# If we're interested in the returned result of this job
#  Obtain a jid to be used
#  Have one of the threads handle this request with saving the result
#  Return the job id of this job
# Have one of the threads handle this request without saving the result

    my $self = shift;
    if (defined( wantarray )) {
        my $jid = $self->_jid;
        $self->{'queue'}->enqueue( $jid, \@_ );
        return $jid;
    }
    $self->{'queue'}->enqueue( \@_ );
} #job

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 number of jobs to be done still

sub todo { shift->{'queue'}->pending } #todo

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N tids of worker (default: all workers)
# OUT: 1 number of jobs done

sub done {

# Obtain the object
# Obtain references to the hashes with done values, keyed by tid
# Set to do all tids if none specified

    my $self = shift;
    my ($hired,$fired) = @$self{qw(hired fired)};
    @_ = (keys %{$hired},keys %{$fired}) unless @_;

# Initialize the number of jobs done
# Loop through all hired worker tids and add the number of jobs
# Loop through all fired worker tids and add the number of jobs
# Return the result

    my $done = 0;
    $done += ($hired->{$_} || 0) foreach (@_);
    $done += ($fired->{$_} || 0) foreach (@_);
    return $done;
} #done

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 job id for which to obtain result
# OUT: 1..N parameters returned from the job

sub result {

# Obtain the object
# Obtain the job id
# Obtain local copy of result hash
# Make sure we have a value outside the block

    my $self = shift;
    my $jid = shift;
    my $result = $self->{'result'};
    my $value;

# Lock the result hash
# Wait until the result is stored
# Obtain the frozen value
# Remove it from the result hash

    {
     lock( $result );
     cond_wait( $result ) until exists $result->{$jid};
     $value = $result->{$jid};
     delete( $result->{$jid} );
    }

# Return the result of thawing

    @{Storable::thaw( $value )};
} #result

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 job id for which to obtain result
# OUT: 1..N parameters returned from the job

sub result_nb {

# Obtain the object
# Obtain the job id
# Obtain local copy of the result hash ref
# Make sure we have a value outside the block

    my $self = shift;
    my $jid = shift;
    my $result = $self->{'result'};
    my $value;

# Lock the result hash
# Return now if there is no result
# Obtain the frozen value
# Remove it from the result hash

    {
     lock( $result );
     return unless exists $result->{$jid};
     $value = $result->{$jid};
     delete( $result->{$jid} );
    }

# Return the result of thawing

    @{Storable::thaw( $value )};
} #result_nb

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 number of workers to have
# OUT: 1..N thread ids of final workforce

sub workers {

# Obtain the object
# Obtain the number of workers
# Obtain local copy of workers list

    my $self = shift;
    my $workers = shift;
    my $hired = $self->{'hired'};

# Make sure we're the only one hiring or firing
# Obtain current number of workers
# If not enough workers
#  Hire workers
# Elseif too many workers
#  Fire workers

    lock( $hired );
    my $current = keys %{$hired};
    if ($current < $workers) {
        $self->hire( $workers - $current );
    } elsif( $current > $workers ) {
        $self->fire( $current - $workers );
    }

# Return the number of workers now if caller is interested

    $self->hired if defined( wantarray );
} #workers

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 number of workers to hire (default: 1)
# OUT: 1..N thread ids (optional)

sub hire {

# Obtain the object
# Obtain the number of workers to hire
# Obtain local copy of worker tids
# Initialize the list with tid's

    my $self = shift;
    my $tohire = shift || 1;
    my $hired = $self->{'hired'};
    my @tid;

# Make sure we're the only one hiring now
# For all of the workers we want to hire
#  Start the thread with the starup parameters
#  Obtain the tid of the thread
#  Save the tid in the list
#  Initialize the number of jobs done by this worker

    lock( $hired );
    foreach (1..$tohire) {
        my $thread = threads->new(
         \&_dispatcher,
         $self,
         @{Storable::thaw( $self->{'startup'} )}
        );
	my $tid = $thread->tid;
        push( @tid,$tid );
        $hired->{$tid} = 0;
    }

# Return the thread id(s) of the worker threads created

    return wantarray ? @tid : $tid[0];
} #hire

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N job id (optional)

sub fire {

# Obtain the object
# Obtain the number of workers to hire
# Initialize the list with jid's

    my $self = shift;
    my $tofire = shift || 1;
    my @jid;

# If we want a jid to be returned (we're interested in the <post> result)
#  For all of the workers we want to fire
#   Obtain a jid to be used
#   Indicate we want to stop and keep the result
#   Add the job id to the list

    if (defined( wantarray )) {
        foreach (1..$tofire) {
            my $jid = $self->_jid;
            $self->{'queue'}->enqueue( 0,$jid );
            push( @jid,$jid );
        }

# Else (we're not interested in results)
#  Just indicate we're want to stop as many as specified (without result saving)

    } else {
        $self->{'queue'}->enqueue( 0 ) foreach 1..$tofire;
    }

# Return either the first or all of the job ids created

    return wantarray ? @jid : $jid[0];
} #fire

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 1..N tid values of worker threads currently hired in this farm

sub hired { keys %{$_[0]->{'hired'}} if defined $_[0]->{'hired'} } #hired

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 1..N tid values of worker threads currently fired in this farm

sub fired { keys %{$_[0]->{'fired'}} } #fired

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N values returned by <pre>

sub pre { wantarray ? @{shift->{'pre'}} : shift->{'pre'}->[0] } #pre

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 new setting of autoshutdown flag
# OUT: 1 current/new setting of autoshutdown

sub autoshutdown {

# Obtain the object
# Set new setting if so specified
# Return the current/new setting

  my $self = shift;
  $self->{'autoshutdown'} = shift if @_;
  $self->{'autoshutdown'};
} #autoshutdown

#---------------------------------------------------------------------------
#  IN: 1 instantiated object

sub shutdown {

# Obtain the object
# Obtain local copy of the hired list reference

    my $self = shift;
    my $hired = $self->{'hired'};

# If there are still workers hired
#  Fire all the workers
#  Lock the has with worker tids
#  Wait until all workers fired
#  Wait until all worker threads have actually finished

    if (my @worker = keys %{$hired}) {
        $self->fire( scalar(@worker) );
	lock( $hired );
        cond_wait( $hired ) while keys %{$hired};

#  For all of the workers
#   Obtain the thread object of this worker
#   Wait for it to end if there is still an object available

        foreach (@worker) {
            my $thread = threads->object( $_ );
            $thread->join if $thread;
        }
    }
} #shutdown

#---------------------------------------------------------------------------

# Internal subroutines

#---------------------------------------------------------------------------
#  IN: 1 hash reference
#      2..N parameters to be passed to <pre>

sub _dispatcher {

# Obtain the object
# Reset auto-shutdown flag in copy of object in this thread
# Save the tid of the thread we're in
# Save a reference to the hired pool for faster access

    my $self = shift;
    $self->{'autoshutdown'} = 0;
    my $tid = threads->tid;
    my $hired = $self->{'hired'};

# Perform the pre actions, save a reference to the result in the local object

    $self->{'pre'} = [exists $self->{'pre'} ? $self->{'pre'}->($self,@_) : ()];

# Create a local copy of the queue object
# Initialize the list of parameters returned (we need it outside later)
# While we're handling requests
#  Fetch the next job when it becomes available
#  Outloop if we're supposed to die

    my $queue = $self->{'queue'};
    my @list;
    while (1) {
        @list = $queue->dequeue;
	last unless $list[0];

#  If no one is interested in the result
#   Execute the job without saving the result
#  Else (someone is interested, so first parameter is jid)
#   Execute the job and save the frozen result
#  Increment number of jobs done by this worker

        if (ref($list[0])) {
            $self->{'do'}->( $self,@{$list[0]} );
        } else {
            $self->_freeze( $list[0], $self->{'do'}->( $self, @{$list[1]} ) );
        }
        $hired->{$tid}++;
    }

# If someone is interested in the result of <end> (so we have a job id)
#  Execute the post-action (if there is one) and save the frozen result
# Else (nobody's interested)
#  Execute the post-action if there is one

    if ($list[1]) {
	$self->_freeze(
	 $list[1],
	 exists $self->{'post'} ? $self->{'post'}->( $self,@_ ) : ()
	);
    } else {
        $self->{'post'}->( $self,@_ ) if exists $self->{'post'};
    }

# Make sure we're the only one working on the hired list
# Mark this worker thread as fired
# Forget this worker thread as hired
# Notify everybody else about changes here

    lock( $hired );
    $self->{'fired'}->{$tid} = $hired->{$tid};
    delete( $hired->{$tid} );
    cond_broadcast( $hired );
} #_dispatcher

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 job id

sub _jid {

# Obtain the object
# Obtain a local copy of the job id counter
# Lock the job id counter
# Return the current value, incrementing it on the fly

    my $self = shift;
    my $jid = $self->{'jid'};
    lock( $jid );
    ${$jid}++;
} #_jid

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 job id
#      3..N values to store

sub _freeze {

# Obtain the object
# Obtain the job id
# Obtain local copy of the result hash

    my $self = shift;
    my $jid = shift;
    my $result = $self->{'result'};

# Make sure we have only access to the result hash
# Store the already frozen result
# Make sure other threads get woken up

    lock( $result );
    $result->{$jid} = Storable::freeze( \@_ );
    cond_broadcast( $result );
} #_freeze

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 job id
# OUT: 1..N result from indicated job

sub _thaw {

# Obtain the object
# Obtain the job id
# Obtain local copy of result hash
# Make sure we have a value outside of the block

    my $self = shift;
    my $jid = shift;
    my $result = $self->{'result'};
    my $value;

# Make sure we're the only ones in the result hash
# Obtain the frozen value
# Remove it from the result hash

    {
     lock( $result );
     $value = $result->{$jid};
     delete( $result->{$jid} );
    }

# Return the result of thawing

    @{Storable::thaw( $value )};
} #_thaw

#---------------------------------------------------------------------------

# Standard Perl functionality methods

#---------------------------------------------------------------------------
#  IN: 1 instantiated object

sub DESTROY {

# Obtain the object
# Fire all workers if so required

    my $self = shift;
    $self->shutdown if $self->{'autoshutdown'};
} #DESTROY

#---------------------------------------------------------------------------

# Additions to standard modules

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 tid of thread to return object of
# OUT: 1 thread object (if found, else undef)

sub threads::object {
    return undef unless @_ > 1;
    foreach (threads->list) {
        return $_ if $_->tid == $_[1];
    }
    return undef;
} #threads::object

#---------------------------------------------------------------------------

__END__

=head1 NAME

threads::farm - group of threads for performing similar jobs

=head1 SYNOPSIS

    use threads::farm;
    $farm = threads::farm->new(
     {
      autoshutdown => 1, # default: 1 = yes
      workers => 5,      # default: 1
      pre => sub {shift; print "starting worker with @_\n",
      do => sub {shift; print "doing job for @_\n"; reverse @_},
      post => sub {shift; print "stopping worker with @_\n",
     },
     qw(a b c)           # parameters to pre-job subroutine
    );

    $farm->job( qw(d e f) );              # not interested in result

    $jobid = $farm->job( qw(g h i) );
    @result = $farm->result( $jobid );    # wait for result to be ready
    print "Result is @result\n";

    $jobid = $farm->job( qw(j k l) );
    @result = $farm->result_nb( $jobid ); # do _not_ wait for result
    print "Result is @result\n";          # may be empty when not ready yet

    $farm->hire;          # add worker(s)
    $farm->fire;          # remove worker(s)
    $farm->workers( 10 ); # set number of workers

    $hired = $farm->hired; 
    $fired = $farm->fired;
    print "$hired workers hired, $fired workers fired\n";
    
    $todo = $farm->todo;
    $done = $farm->done;
    print "$done jobs done, still $todo jobs todo\n";

    $farm->autoshutdown( 1 ); # shutdown when object is destroyed
    $farm->shutdown;          # wait until all jobs done

    @pre = shift->pre; # inside do() and post() only;

=head1 DESCRIPTION

=head1 METHODS

=over 8

=item new

=item job

=item result

=item result_nb

=item todo

=item done

=item hire

=item fire

=item workers

=item hired

=item fired

=item autoshutdown

=item shutdown

=item pre

=back

=head1 CAVEATS

Passing unshared values between threads is accomplished by serializing the
specified values using C<Storable>.  This allows for great flexibility at
the expense of more CPU usage.  It also limits what can be passed, as e.g.
code references can B<not> be serialized and therefor not be passed.

=head1 SEE ALSO

L<threads>, L<threads::shared::queue::any>, L<Storable>.

=cut
