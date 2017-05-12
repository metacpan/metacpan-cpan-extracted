package Thread::Pool;

# Set the version information
# Make sure we do everything by the book from now on

$VERSION = '0.33';
use strict;

# Make sure we only load stuff when we actually need it

use load;

# Make sure we can do monitored belts

use Thread::Conveyor::Monitored ();

# Allow for self referencing within job thread
# Flag to indicate whether the current thread should be removed
# The current jobid, when available
# Flag to indicate result should _not_ be saved (assume another thread will)

our $SELF;
our $remove_me;
our $jobid;
our $dont_set_result;

# Number of times this namespace has been CLONEd
# Set default optimization
# Set default checkpoint frequency

our $cloned = 0;
our $OPTIMIZE = 'memory';
our $FREQUENCY = Thread::Conveyor::Monitored->frequency;

# Satisfy -require-

1;

#---------------------------------------------------------------------------

# Standard Perl functionality

#---------------------------------------------------------------------------
#  IN: 1 namespace being cloned (ignored)

sub CLONE { $cloned++ } #CLONE

#---------------------------------------------------------------------------

# The following methods are only loaded on demand

__END__

#---------------------------------------------------------------------------
#  IN: 1 instantiated object

sub DESTROY {

# Return now if we're in a rogue DESTROY

    return unless UNIVERSAL::isa( $_[0],__PACKAGE__ ); #HACK

# Obtain the object
# Return now if we're not allowed to run DESTROY
# Do the shutdown if shutdown is required

    my $self = shift;
    return unless $self->{'cloned'} == $cloned;
    $self->shutdown if $self->{'autoshutdown'};
} #DESTROY

#---------------------------------------------------------------------------

# class methods

#---------------------------------------------------------------------------
#  IN: 1 class with which to create
#      2 reference to hash with parameters
#      3..N parameters to be passed to "pre" routine
# OUT: 1 instantiated object

sub new {

# Obtain the class
# Obtain the hash with parameters and bless it
# Save the clone level (so we can check later if we've been cloned)
# Die now if there is no subroutine to execute

    my $class = shift;
    my $self = bless shift,$class;
    $self->{'cloned'} = $cloned;
    die "Must have a subroutine to perform jobs" unless exists $self->{'do'};

# Save the number of workers that were specified now (is changed later)
# Set the maximum number of jobs if not set already
# Set the minimum number of jobs if not set already
# Set the default optimization if none specified
 
    my $add = $self->{'workers'};
    $self->{'maxjobs'} = 5 * ($add || 1) unless defined( $self->{'maxjobs'} );
    $self->{'minjobs'} ||= $self->{'maxjobs'} >> 1;
    $self->{'optimize'} ||= $OPTIMIZE;

# If we're supposed to monitor
#  Die now if also attempting to stream

    if (exists $self->{'monitor'}) {
        die "Cannot stream and monitor at the same time"
         if exists $self->{ 'stream'};

#  Make sure we have a real coderef for the pre and the monitoring routine
#  Create a monitored belt
#  Set the streaming routine that sends to the monitor

        $self->_makecoderef( caller().'::',qw(pre monitor post checkpoint) );
        $self->{'monitor_belt'} = Thread::Conveyor::Monitored->new(
         {
          optimize   => $self->{'optimize'},
          pre        => $self->{'pre'},
          monitor    => $self->{'monitor'},
          post       => $self->{'post'},
          exit       => $self->{'exit'},
          checkpoint => $self->{'checkpoint'},
          frequency  => $self->{'checkpoint'} ?
	   $self->{'frequency'} || $FREQUENCY : undef,
          maxboxes   => $self->{'maxjobs'},
          minboxes   => $self->{'minjobs'},
         },
         @_
        );
        $self->{'stream'} = \&_have_monitored;
    }

# Create a belt for it

    $self->{'belt'} = Thread::Conveyor->new(
     {
      optimize => $self->{'optimize'}
     }
    );

# Set the auto-shutdown flag unless it is specified already
# Set the dispatcher to be used if none specified yet
# Make sure all subroutines are code references

    $self->{'autoshutdown'} = 1 unless exists $self->{'autoshutdown'};
    $self->{'dispatcher'} ||= $self->{'stream'} ? \&_stream : \&_random;
    $self->_makecoderef( caller().'::',qw(pre do post stream dispatcher) );

# If the Thread::Tie module is loaded
#  Initialize the workers threads list as tied and save the locking semaphore
#  Make sure references exist in the object

#    if (defined( $Thread::Tie::VERSION )) {
        $self->{'lock_workers'} = (tie my @workers, 'Thread::Tie')->semaphore;
        @$self{qw(workers)} = (\@workers);

# Else (use standard shared implemenation)
#  Initialize the workers threads list as shared
#  Make sure references exist in the object

#    } else {
#        my @workers : shared;
#        @$self{qw(workers)} = (\@workers);
#    }

# Initialize the jobid counter as shared
# Initialize the streamid counter as shared
# Initialize the running flag
# Initialize the removed hash as shared
# Initialize the result hash as shared
# Make sure references exist in the object

    my $jobid : shared = 1;
    my $streamid : shared = 1;
    my $running : shared = 1;
    my %removed : shared;
    my %result : shared;
    @$self{qw(jobid streamid running removed result)} =
     (\$jobid,\$streamid,\$running,\%removed,\%result);

# Save a frozen value to the parameters for later hiring
# Add the number of workers indicated
# Return the instantiated object

    $self->{'startup'} = Thread::Serialize::freeze( @_ );
    $self->add( $add );
    $self;
} #new

#---------------------------------------------------------------------------
#  IN: 1 class (ignored) or instantiated object
#      2 new default checkpoint frequency (if called as class method only)
# OUT: 1 default frequency

sub frequency {

# Obtain the object
# If called as an object method
#  Return undef if no checkpointing active
#  Return frequency with which checkpointing is occurring

    my $self = shift;
    if (ref($self)) {
        return unless $self->{'checkpoint'};
        return $self->{'frequency'} || $FREQUENCY;
    }

# Set new default frequency if specified
# Return current default frequency

    $FREQUENCY = shift if @_;
    $FREQUENCY;
} #frequency

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new default optimization type
# OUT: 1 current default optimization type

sub optimize {

# Set new optimized value if specified
# Return current optimized value

    $OPTIMIZE = $_[1] if @_ > 1;
    $OPTIMIZE;
} #optimize

#---------------------------------------------------------------------------

# instance methods

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N parameters to be passed for this job
# OUT: 1 jobid

sub job { 

# Obtain the object
# Die now if the pool was shut down
# Obtain local copy of the job belt

    my $self = shift;
    die "Cannot submit jobs on a pool that has been shut down"
     if $self->{'shutdown'};
    my $belt = $self->{'belt'};

# If we're streaming
#  Die now if an individual jobid requested
#  Put in box with a jobid obtained on the fly

    if ($self->{'stream'}) {
        die "Cannot return individual results when streaming"
         if defined( wantarray );
        $belt->put( $self->_jobid, \@_ );

# Elseif we want a jobid
#  Obtain a jobid
#  Put in box with that jobid
#  And return with that jobid now

    } elsif (defined( wantarray )) {
        my $jobid = $self->_jobid;
        $belt->put( $jobid, \@_ );
        return $jobid;

# Else (not streaming and not interested in the result)
#  Put in box without a jobid

    } else {
        $belt->put( \@_ )
    }
} #job

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N parameters to be passed for this job
# OUT: 1..N parameters returned from the job

sub waitfor {

# Obtain the object
# Submit the job, obtain the jobid and wait for the result

    my $self = shift;
    $self->result( $self->job( @_ ) );
} #waitfor

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 number of jobs to be done still

sub todo { shift->{'belt'}->onbelt } #todo

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N tids of removed worker (default: all removed workers)
# OUT: 1 number of jobs done

sub done {

# Obtain the object
# Obtain references to the hashes with done values, keyed by tid
# Set to do all tids if none specified

    my $self = shift;
    my $removed = $self->{'removed'};
    @_ = keys %{$removed} unless @_;

# Initialize the number of jobs done
# Loop through all removed worker tids and add the number of jobs
# Return the result

    my $done = 0;
    $done += ($removed->{$_} || 0) foreach @_;
    $done;
} #done

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 jobid for which to obtain result
# OUT: 1..N parameters returned from the job

sub result {

# Obtain the object
# Obtain the jobid
# Obtain local copy of result hash reference
# Make sure we have a value outside the block

    my $self = shift;
    my $jobid = shift;
    my $result = $self->{'result'};
    my $value;

# Lock the result hash
# Wait until the result is stored
# Obtain the frozen value
# Remove it from the result hash

    {lock( $result );
     threads::shared::cond_wait( $result ) until exists $result->{$jobid};
     $value = $result->{$jobid};
     delete( $result->{$jobid} );
    } #$result

# Return the result of thawing

    Thread::Serialize::thaw( $value );
} #result

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 reference to scalar where to store jobid (optional)
# OUT: 1..N parameters returned from the job

sub result_any {

# Obtain the object
# Obtain the scalar reference
# Obtain local copy of result hash reference
# Make sure we have a value outside the block

    my $self = shift;
    my $jobidref = shift;
    my $result = $self->{'result'};
    my $value;

# Initialize the jobid
# Lock the result hash
# Wait there is a result available
# Obtain the frozen value
# Remove it from the result hash

    my $jobid;
    {lock( $result );
     threads::shared::cond_wait( $result ) until $jobid = (keys %{$result})[0];
     $value = $result->{$jobid};
     delete( $result->{$jobid} );
    } #$result

# Set the jobid if the caller wants to know
# Return the jobid and the result of thawing

    $$jobidref = $jobid if $jobidref;
    Thread::Serialize::thaw( $value );
} #result_any

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 jobid for which to obtain result
# OUT: 1..N parameters returned from the job

sub result_dontwait {

# Obtain the object
# Obtain the jobid
# Obtain local copy of stuff we need
# Make sure we have a value outside the block

    my $self = shift;
    my $jobid = shift;
    my $result = $self->{'result'};
    my $value;

# Lock the result hash
# Return now if there is no result
# Obtain the frozen value
# Remove it from the result hash

    {lock( $result );
     return unless exists $result->{$jobid};
     $value = $result->{$jobid};
     delete( $result->{$jobid} );
    } #$result

# Return the result of thawing

    Thread::Serialize::thaw( $value );
} #result_dontwait

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1..N results still waiting to be fetched

sub results {

# Obtain local copy of stuff we need
# Lock access to the result hash
# Return the keys from the hash

    my $result = shift->{'result'};
    lock( $result );
    keys %$result;
} #results

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 number of workers to have (default: no change)
# OUT: 1..N thread ids of final workforce

sub workers {

# Obtain the object
# Obtain local copies of stuff we need
# Make sure we have something valid to lock with

    my $self = shift;
    my ($workers,$lock_workers,$removed) =
     @$self{qw(workers lock_workers removed)};
    $lock_workers ||= $workers;

# If a new number of workers specified
#  Die now if we're trying to set number or workers in wrong thread

    if (@_) {
        $self->_check_originating_thread( 'workers' );

#  Make sure we're the only one adding or removing
#  Obtain current number of workers
#  If not enough workers
#   Add workers
#  Elseif too many workers
#   Remove workers

        lock( $lock_workers );
        my $new = shift;
        my $current = $self->workers;
        if ($current < $new) {
            $self->add( $new - $current );
        } elsif( $current > $new ) {
            $self->remove( $current - $new );
        }
    }

# Return now if in void context
# Loop through all workers and return only those not in removed

    return unless defined(wantarray);
    map {exists( $removed->{$_} ) ? () : ($_)} @{$workers};
} #workers

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 number of workers to add (default: 1)
# OUT: 1..N thread ids (optional)

sub add {

# Obtain the object
# Die now if shut down
# Die now if not in the correct thread

    my $self = shift;
    die "Cannot add workers to a pool that has been shut down"
     if $self->{'shutdown'};
    $self->_check_originating_thread( 'add' );

# Obtain the number of workers to add
# Die now if not a proper number of workers to add
# Obtain local copy of stuff we need
# Make sure we have something to lock with
# Initialize the list with tid's

    my $add = shift || 1;
    die "Must add at least one thread" unless $add > 0;
    my ($workers,$lock_workers,$dispatcher) =
     @$self{qw(workers lock_workers dispatcher)};
    $lock_workers ||= $workers;
    my @tid;

# Thaw the original input parameters to be sent when a thread is created
# Make sure we're the only one adding now
# For all of the workers we want to add
#  Start the thread with the startup parameters
#  Obtain the tid of the thread
#  Save the tid in the local list
#  Save the tid in the global list

    @_ = Thread::Serialize::thaw( $self->{'startup'} );
    {lock( $lock_workers );
     foreach (1..$add) {
         my $thread = threads->new( $dispatcher,$self,@_ );
         my $tid = $thread->tid;
         push( @tid,$tid );
         push( @{$workers},$tid );
     }
    } #$lock_workers

# Return the thread id(s) of the worker threads created

    return wantarray ? @tid : $tid[0];
} #add

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 number of workers to remove
# OUT: 1..N jobid (optional)

sub remove {

# Obtain the object
# Die now if shut down
# Die now if not in the correct thread

    my $self = shift;
    die "Cannot remove workers from a pool that has been shut down"
     if $self->{'shutdown'};
    $self->_check_originating_thread( 'remove' );

# Obtain the number of workers to remove
# Die now if improper number of workers to remove
# Initialize the list with jobid's

    my $remove = shift || 1;
    die "Must remove at least one thread" unless $remove > 0;
    my @jobid;

# If we want a jobid to be returned (we're interested in the <post> result)
#  For all of the workers we want to remove
#   Obtain a jobid to be used
#   Indicate we want to stop and keep the result
#   Add the jobid to the list

    if (defined( wantarray )) {
        foreach (1..$remove) {
            my $jobid = $self->_jobid;
            $self->{'belt'}->put( 0,$jobid );
            push( @jobid,$jobid );
        }

# Else (we're not interested in results)
#  Just indicate we're want to stop as many as specified (without result saving)

    } else {
        $self->{'belt'}->put( 0 ) foreach 1..$remove;
    }

# Return either the first or all of the jobids created

    return wantarray ? @jobid : $jobid[0];
} #remove

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 1..N tid values of worker threads that were removed

sub removed { keys %{$_[0]->{'removed'}} } #removed

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N thread ID's to join (default: all active threads marked removed)

sub join {

# Obtain the object
# Die now if not in the right thread
# Obtain local copies of stuff we need
# Make sure we have something to lock with

    my $self = shift;
    $self->_check_originating_thread( 'join' );
    my ($removed,$workers,$lock_workers) =
     @$self{qw(removed workers lock_workers)};
    $lock_workers ||= $workers;

# Make sure we're the only ones doing the workers list
# Obtain local copy of the worker's tids
# Set default list to join if no threads specified yet

    lock( $lock_workers );
    my @worker = @{$workers};
    @_ = map {exists( $removed->{$_} ) ? ($_) : ()} @worker unless @_;

# For all of the threads to be joined
#  If there is a thread for this tid still
#   Join that thread
#  Else
#   Die, thread seems to have vanished without saying goodbye

    foreach (@_) {
        if (my $thread = threads->object( $_ )) {
            $thread->join;
        } else {
            die "Thread #$_ seems to have gone without notification";
        }
    }

# Set the new list of worker threads

    @{$workers} = map {exists( $removed->{$_} ) ? () : ($_)} @worker;
} #join

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 new maxjobs value (default: no change)
# OUT: 1 current maxjobs value

sub maxjobs {

# Obtain the object
# If a new value is specified
#  Obtain the new maxjobs value
#  Determine new default minjobs value

    my $self = shift;
    if (@_) {
        my $maxjobs = $self->{'maxjobs'} = shift;
        my $minjobs = $self->{'minjobs'} = $maxjobs >> 1;

#  If there is a belt (should always be there)
#   Set new maximum number of boxes
#   Set new minimum number of boxes

        if (my $belt = $self->{'belt'}) {
            $belt->maxboxes( $maxjobs );
            $belt->minboxes( $minjobs );
        }

#  If there is a monitoring belt
#   Set new maximum number of boxes
#   Set new minimum number of boxes

        if (my $monitor = $self->{'monitor_belt'}) {
            $monitor->maxboxes( $maxjobs );
            $monitor->minboxes( $minjobs );
        }
    }

# Return current value

    $self->{'maxjobs'};
} #maxjobs

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 new minjobs value (default: no change)
# OUT: 1 current minjobs value

sub minjobs {

# Obtain the object
# If a new value is specified
#  Obtain the new minjobs value
#  Set minimum number of boxes on the belt
#  Set minimum number of boxes on the monitoring belt if any
# Return current value

    my $self = shift;
    if (@_) {
        my $minjobs = $self->{'minjobs'} = shift;
        $self->{'belt'}->minboxes( $minjobs );
        $self->{'monitor_belt'}->minboxes($minjobs) if $self->{'monitor_belt'};
    }
    $self->{'minjobs'};
} #minjobs

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
# Die now if not in the correct thread
# Return now if are already shut down

    my $self = shift;
    $self->_check_originating_thread( 'shutdown' );
    return if $self->{'shutdown'};

# Notify all available active workers after all jobs
# Mark the object as shut down now (in case we die in here)
# Join all workers, active or non-active (should be all now)

    $self->workers( 0 );
    $self->{'shutdown'} = 1;
    $self->join( @{$self->{'workers'}} );

# Obtain local copy of the job belt
# While there are boxes on the belt (without taking them off)
#  Outloop if there is a real job in the box
#  Remove the finishing job (amount of workers to remove was too high)

    my $belt = $self->{'belt'};
    while (my ($jobid) = $belt->peek_dontwait) {
       last if $jobid;
       $belt->take;
    }

# If we were streaming
#  Obtain local copy of stuff we need

    if (my $stream = $self->{'stream'}) {
        my ($streamid,$jobid,$result) = @$self{qw(streamid jobid result)};

#  Set the extra parameters to be passed to streamer if monitoring
#  Make sure we're the only one handling results
#  Obtain last ID to loop through

        my @extra = exists $self->{'monitor_belt'} ? ($self) : ();
        lock( $result );
        my $last = $self->_first_todo_jobid;

#  For all the results that still need to be streamd
#   Die if there is no result (_should_ be there by now)
#   Call the "stream" routine with this result
#   Delete the result from the hash
#  Set the stream ID for any further streaming later

        for (my $i = $$streamid; $i < $last; $i++) {
            die "Cannot find result for streaming job $i"
             unless exists( $result->{$i} );
            $stream->( @extra,Thread::Serialize::thaw( $result->{$i} ) );
            delete( $result->{$i} );
        }
        $$streamid = $last;
    }

# Die now if there are still any jobs to be done
# And shut the belt down

    die "Shutting down pool while there are still jobs to be done"
     if $belt->onbelt;
    $belt->shutdown;

# If there is a monitoring thread
#  Tell the monitoring to stop and wait for that thread to finish
#  Forget we had a monitoring belt

    if (my $mbelt = $self->{'monitor_belt'}) {
        $mbelt->shutdown;
	delete( $self->{'monitor_belt'} );
    }
} #shutdown

#---------------------------------------------------------------------------
#  IN: 1 instantiated object

sub abort {

# Obtain the object
# Die now if in the wrong thread

    my $self = shift;
    $self->_check_originating_thread( 'abort' );

# Reset the flag that we're running
# While there are still workers active
#  Reset to 0 workers if there are no jobs left to do (they won't see the flag)
#  Give the other threads a chance
# Set the running flag again (in case workers get added later)
# Collect the actual threads

    ${$self->{'running'}} = 0;
    while ($self->workers) {
        $self->workers( 0 ) unless $self->todo;
        threads->yield;
    }
    ${$self->{'running'}} = 1;
    $self->join;
} #abort

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 number of threads that have not done any jobs

sub notused {

# Obtain local copy of stuff we need
# Initialize counter

    my $removed = shift->{'removed'};
    my $notused = 0;

# Make sure we're the only ones doing this
# Loop for all worker threads that were removed
#  Increment counter if no jobs were done by this thread
# Return the resulting amount

    lock( $removed );
    while (my $key = each %{$removed}) {
        $notused++ unless $removed->{$key};
    }
    $notused;
} #notused

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
# OUT: 1 instantiated pool object

sub self { $SELF } #self

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
# OUT: 1 instantiated monitor object

sub monitor { Thread::Conveyor::Monitored->belt } #monitor

#---------------------------------------------------------------------------
#  IN: 1 instantiated object or class (ignored)

sub remove_me { $remove_me = 1 } #remove_me

#---------------------------------------------------------------------------
#  IN: 1 instantiated object or class (ignored)
# OUT: 1 jobid of the job currently handled by this thread

sub jobid { $jobid } #jobid

#---------------------------------------------------------------------------
#  IN: 1 instantiated object or class (ignored)

sub dont_set_result { $dont_set_result = 1 } #dont_set_result

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 jobid
#      3..N values to store

sub set_result {

# Obtain the object
# Obtain the jobid
# Return now if we're not supposed to save and it's its own job

    my $self = shift;
    my $set_jobid = shift;
    return if $dont_set_result and $set_jobid == $jobid;

# Obtain local copy of stuff we need
# Make sure we have only access to the result hash
# Store the already frozen result
# Make sure other threads get woken up

    my $result = $self->{'result'};
    lock( $result );
    $result->{$set_jobid} = Thread::Serialize::freeze( @_ );
    threads::shared::cond_broadcast( $result );
} #set_result

#---------------------------------------------------------------------------

# Basic dispatcher routines

#---------------------------------------------------------------------------
#  IN: 1 hash reference
#      2..N parameters to be passed to "pre" routine

sub _random {

# Obtain the object and save it for later self-reference
# Save the tid of the thread we're in
# Initialize the number of jobs

    my $self = $SELF = shift;
    my $tid = threads->tid;
    my $jobs = 0;

# Obtain local copies from the hash for faster access

    my ($belt,$do,$post,$result,$removed,$workers,
        $running,$pre_post_monitor_only) =
     @$self{qw(belt do post result removed workers
        running pre_post_monitor_only)};

# Perform the pre actions if there are any and we're supposed to do it
# Reset the post routine if we're not supposed to run it

    $self->{'pre'}->( @_ ) if !$pre_post_monitor_only and exists $self->{'pre'};
    undef( $post ) if $pre_post_monitor_only;

# Initialize the list of parameters returned (we need it outside later)
# While we're handling requests
#  Fetch the next job when it becomes available
#  Outloop if we're supposed to die
#  Reset the don't save flag

    my (@list,$running_now);
    while ($running_now = $$running) {
        @list = $belt->take;
	last unless $list[0];
        $dont_set_result = undef;

#  If no one is interested in the result
#   Reset the jobid
#   Execute the job without saving the result
#  Else (someone is interested, so first parameter is jobid)
#   Set the jobid
#   Execute the job and save the frozen result
#  Increment number of jobs done by this worker

        if (ref($list[0])) {
	    $jobid = undef;
            $do->( @{$list[0]} );
        } else {
	    $jobid = $list[0];
            $self->set_result( $jobid, $do->( @{$list[1]} ) );
        }
        $jobs++;

#  Reloop if we're supposed to continue with this thread
#  Reset the jobid, we don't want the result to be saved ever
#  Start shutting down this worker thread

        next unless $remove_me;
        $list[1] = '';
        last;
    }

# If we're not aborting
#  Reset the don't save flag
#  If someone is interested in the result of "remove" (so we have a jobid)
#   Execute the post-action (if there is one) and save the frozen result
#  Else (nobody's interested)
#   Execute the post-action if there is one

    if ($running_now) {
        $dont_set_result = undef;
        if ($jobid = $list[1]) {
            $self->set_result( $list[1], $post ? $post->( @_ ) : () );
        } else {
            $post->( @_ ) if $post;
        }
    }

# Mark this worker thread as removed

    { lock( $removed ); $self->{'removed'}->{$tid} = $jobs; }
} #_random

#---------------------------------------------------------------------------
#  IN: 1 hash reference
#      2..N parameters to be passed to "pre" routine

sub _stream {

# Obtain the object and save for self reference
# Save the tid of the thread we're in
# Initialize the number of jobs

    my $self = $SELF = shift;
    my $tid = threads->tid;
    my $jobs = 0;

# Obtain local copies from the hash for faster access
# Make sure we have something to lock results with

    my ($belt,$do,$post,$result,$stream,$streamid,
        $removed,$workers,$running,$pre_post_monitor_only) =
     @$self{qw(belt do post result stream streamid
        removed workers running pre_post_monitor_only)};

# Perform the pre actions if there are any and we're allowed to
# Reset the post routine if we're not supposed to run it
# Set the extra parameters to be passed to streamer if monitoring

    $self->{'pre'}->( @_ ) if !$pre_post_monitor_only and exists $self->{'pre'};
    undef( $post ) if $pre_post_monitor_only;
    my @extra = exists $self->{'monitor_belt'} ? ($self) : ();

# Initialize the stuff that we need outside later
# While we're handling requests, keeping copy of the flag on the fly
#  Fetch the next job when it becomes available
#  Outloop if we're supposed to die
#  Reset the don't save flag

    my (@list,$running_now);
    while ($running_now = $$running) {
        @list = $belt->take;
        last unless $jobid = $list[0];
        $dont_set_result = undef;

#  If we're in sync (this job is the next one to be streamed)
#   Obtain the result of the job
#   If we're supposed to save the result
#    Stream the result of the job immediately
#    Increment stream id
#   Increment number of jobs
#   And reloop

        if ($$streamid == $jobid) {
            my @param = $do->( @{$list[1]} );
            unless ($dont_set_result) {
                $stream->( @extra,@param );
                { lock($streamid); ${$streamid} = $jobid+1 }
            }
            $jobs++;
	    next;
        }

#  Execute the job and save the result
#  Increment number of jobs done by this worker

        my @param = $do->( @{$list[1]} );
        $jobs++;

#  Make sure we're the only one accessing the result hash and stream id's
#  Obtain the current stream ID (so we can use it later)
#  For all of the results from the stream ID to this thread's job ID
#   Outloop if there is no result yet
#   Call the "stream" routine with the result
#   Remove the result from the hash

        {lock( $result ); lock( $streamid );
         my $i = $$streamid;
         for (; $i < $jobid; $i++) {
             last unless exists( $result->{$i} );
             $stream->( @extra,Thread::Serialize::thaw( $result->{$i} ) );
             delete( $result->{$i} );
         } #$result,$streamid

#  If all results until this job ID have been streamed
#   If we need to save this result
#    Call the "stream" routine with the result of this job
#    Set the stream ID to handle the result after this one
#  Else (not all results where available)
#   Freeze the result of this job for later handling
#   Set the stream ID to the job ID for which there was no result yet

         if ($i == $jobid) {
             unless ($dont_set_result) {
                 $stream->( @extra,@param );
                 $$streamid = $jobid+1;
             }
         } else {
             $self->set_result( $jobid, @param );
             $$streamid = $i;
         }
        }

#  Reloop if we're supposed to continue with this thread
#  Reset the jobid, we don't want the result to be saved ever
#  Start shutting down this worker thread

        next unless $remove_me;
        $list[1] = '';
        last;
    }

# If we're not aborting
#  Reset the don't save flag
#  If someone is interested in the result of <end> (so we have a jobid)
#   Execute the post-action (if there is one) and save the frozen result
#  Else (nobody's interested)
#   Execute the post-action if there is one

    if ($running_now) {
        $dont_set_result = undef;
        if ($list[1]) {
            $self->set_result( $list[1], $post ? $post->( @_ ) : () );
        } else {
            $post->( @_ ) if $post;
        }
    }

# Mark this worker thread as removed

    { lock( $removed ); $self->{'removed'}->{$tid} = $jobs; }
} #_stream

#---------------------------------------------------------------------------

# Internal subroutines

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 namespace to be prefixed
#      3..N fields to change to code refs (if available)

sub _makecoderef {

# Obtain the object
# Obtain the namespace to add to non fully qualified names

    my $self = shift;
    my $namespace = shift;

# For all of the fields specified
#  Reloop if doesn't exist
#  Reloop if already a reference
#  Prefix namespace if not fully qualified
#  Change name to code reference

    foreach (@_) {
        next unless exists $self->{$_};
        next if ref($self->{$_});
        $self->{$_} = $namespace.$self->{$_} unless $self->{$_} =~ m#::#;
        $self->{$_} = \&{$self->{$_}};
    }
} #_makecoderef

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 name of subroutine that is not allowed to be called

sub _check_originating_thread {

# Die now if in the wrong thread

    die qq(Can only call "$_[1]" in the originating thread)
     unless $_[0]->{'cloned'} == $cloned;
} #_check_originating_thread

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 jobid

sub _jobid {

# Obtain the object
# Obtain a local copy of the jobid counter
# Lock the jobid counter
# Return the current value, incrementing it on the fly

    my $self = shift;
    my $jobid = $self->{'jobid'};
    lock( $jobid );
    ${$jobid}++;
} #_jobid

#---------------------------------------------------------------------------
#  IN: 1 instantiated Thread::Pool object
# OUT: 1 job id of first todo job

sub _first_todo_jobid {

# Obtain the object
# Obtain local copy of the belt
# Obtain the number of boxes

    my $self = shift;
    my $belt = $self->{'belt'};
    my $boxes = $belt->onbelt;

# For all the jobs in the belt
#  De-frost the values in this box
#  Return the job id if it is a job with a job id
# Return the next job id that is going to be issued

    for (my $i = 0; $i < $boxes; $i++) {
        my @param = $belt->peek_dontwait( $i );
        return $param[0] if @param == 2;
    }
    ${$self->{'jobid'}};
} #_first_todo_jobid

#---------------------------------------------------------------------------
#  IN: 1 instantiate Thread::Pool object
#      2..N any parameters returned as a result of a job

sub _have_monitored {

# Put the parameters with at least an empty string to prevent premature exit

    shift->{'monitor_belt'}->put( @_ ? @_ : ('') );
} #_have_monitored

#---------------------------------------------------------------------------

=head1 NAME

Thread::Pool - group of threads for performing similar jobs

=head1 VERSION

This documentation describes version 0.33.

=head1 SYNOPSIS

 use Thread::Pool;
 $pool = Thread::Pool->new(
  {
   optimize => 'cpu', # default: 'memory'

   pre => sub {shift; print "starting worker with @_\n",
   do => sub {shift; print "doing job for @_\n"; reverse @_},
   post => sub {shift; print "stopping worker with @_\n",

   stream => sub {shift; print "streamline with @_\n",

   monitor => sub { print "monitor with @_\n",
   pre_post_monitor_only => 0, # default: 0 = also for "do"

   checkpoint => sub { print "checkpointing\n" },
   frequency => 1000,

   autoshutdown => 1, # default: 1 = yes

   workers => 10,     # default: 1
   maxjobs => 50,     # default: 5 * workers
   minjobs => 5,      # default: maxjobs / 2
  },
  qw(a b c)           # parameters to "pre" and "post" routine
 );

 $pool->job( qw(d e f) );              # not interested in result

 $jobid = $pool->job( qw(g h i) );
 @result = $pool->result( $jobid );    # wait for result to be ready

 $jobid = $pool->job( qw(j k l) );
 @result = $pool->result_dontwait( $jobid ); # do _not_ wait for result

 @result = $pool->waitfor( qw(m n o) ); # submit and wait for result

 $pool->add;           # add worker(s)
 $pool->remove;        # remove worker(s)
 $pool->workers( 10 ); # adapt number of workers
 $pool->join;          # wait for all removed worker threads to finish

 $workers = $pool->workers; 
 $todo    = $pool->todo;
 $removed = $pool->removed;

 $pool->maxjobs( 100 );  # adapt or (de-)activate job throttling
 $pool->minjobs( 10 );

 $pool->autoshutdown( 1 ); # shutdown when object is destroyed
 $pool->shutdown;          # wait until all jobs done
 $pool->abort;             # finish current job and remove all workers

 $done    = $pool->done;   # simple thread-use statistics
 $notused = $pool->notused;

 Thread::Pool->remove_me;  # inside "do" only

=head1 DESCRIPTION

                  *** A note of CAUTION ***

 This module only functions on Perl versions 5.8.0 and later.
 And then only when threads are enabled with -Dusethreads.
 It is of no use with any version of Perl before 5.8.0 or
 without threads enabled.

                  *************************

The Thread::Pool allows you to set up a group of (worker) threads to execute
a (large) number of similar jobs that need to be executed asynchronously.  The
routine that actually performs the job (the "do" routine), must be specified
as a name or a reference to a (anonymous) subroutine.

Once a pool is created, L<job>s can be executed at will and will be assigned
to the next available worker.  If the result of the job is important, a
job ID is issued.  The job ID can then later be used to obtain the L<result>.

Initialization parameters can be passed during the creation of the
Thread::Pool object.  The initialization ("pre") routine can be specified
as a name or as a reference to a (anonymous) subroutine.  The "pre" routine
can e.g. be used to create a connection to an external source using a
non-threadsafe library.

When a worker is told to finish, the "post" routine is executed if available.

Results of jobs must be obtained seperately, unless a "stream" or a "monitor"
routine is specified.  Then the result of each job will be streamed to the
"stream" or "monitor" routine in the order in which the jobs were submitted.

Unless told otherwise, all jobs that are assigned, will be executed before
the pool is allowed to be destroyed.  If a "stream" or "monitor" routine
is specified, then all results will be handled by that routine before the
pool is allowed to be destroyed.

=head1 CLASS METHODS

The following class methods are available.

=head2 new

 $pool = Thread::Pool->new(
  {
   optimize => 'cpu',                            # default: memory

   do => sub { print "doing with @_\n" },        # must have
   pre => sub { print "starting with @_\n",      # default: none
   post => sub { print "stopping with @_\n",     # default: none

   stream => sub { print "streamline with @_\n", # default: none

   monitor => sub { print "monitor with @_\n",   # default: none
   pre_post_monitor_only => 0, # default: 0 = also for "do"
   checkpoint => \&checkpoint,
   frequency => 1000,

   autoshutdown => 1, # default: 1 = yes

   workers => 10,     # default: 1
   maxjobs => 50,     # default: 5 * workers
   minjobs => 5,      # default: maxjobs / 2
  },

  qw(a b c)           # parameters to "pre" and "post" routines

 );

The "new" method returns the Thread::Pool object.

The first input parameter is a reference to a hash that should at least
contain the "do" key with a subroutine reference.

The other input parameters are optional.  If specified, they are passed to the
the "pre" subroutine whenever a new worker is L<add>ed.

Each time a worker thread is added, the "pre" subroutine (if available) will
be called inside the thread.  Each time a worker thread is L<remove>d, the
"post" routine is called.  Its return value(s) are saved only if a job ID was
requested when removing the thread.  Then the L<result> method can be called
to obtain the results of the "post" subroutine.

The following field B<must> be specified in the hash reference:

=over 2

=item optimize

 optimize => 'cpu', # default: 'memory'

The "optimize" field specifies which implementation of the belt will be
selected.  Currently there are two choices: 'cpu' and 'memory'.  By default,
the "memory" optimization will be selected if no specific optmization is
specified.

You can call the class method L<optimize> to change the default optimization.

=item do

 do => 'do_the_job',		# assume caller's namespace

or:

 do => 'Package::do_the_job',

or:

 do => \&SomeOther::do_the_job,

or:

 do => sub {print "anonymous sub doing the job\n"},

The "do" field specifies the subroutine to be executed for each L<job>.  It
must be specified as either the name of a subroutine or as a reference to a
(anonymous) subroutine.

The specified subroutine should expect the following parameters to be passed:

 1..N  any parameters that were passed with the call to L<job>.

Any values that are returned by this subroutine after finishing each job, are
accessible with L<result> if a job ID was requested when assigning the L<job>.

=back

The following fields are B<optional> in the hash reference:

=over 2

=item pre

 pre => 'prepare_jobs',		# assume caller's namespace

or:

 pre => 'Package::prepare_jobs',

or:

 pre => \&SomeOther::prepare_jobs,

or:

 pre => sub {print "anonymous sub preparing the jobs\n"},

The "pre" field specifies the subroutine to be executed B<each> time a new
worker thread is B<started> (either when starting the pool, or when new worker
threads are added with a call to either L<add> or L<workers>) and once when a
"monitor" routine is specified.  It must be specified as either the name of a
subroutine or as a reference to a (anonymous) subroutine.

The specified subroutine should expect the following parameters to be passed:

 1..N  any additional parameters that were passed with the call to L<new>.

You can determine whether the "pre" routine is called for a new worker thread
or for a monitoring thread by checking the L<self> or L<monitor> class method
inside the "pre" routine.

=item post

 post => 'cleanup_after_worker',	# assume caller's namespace

or:

 post => 'Package::cleanup_after_worker',

or:

 post => \&SomeOther::cleanup_after_worker,

or:

 post => sub {print "anonymous sub cleaning up after the worker removed\n"},

The "post" field specifies the subroutine to be executed B<each> time a worker
thread is B<removed> (either when being specifically L<remove>d, or when the
pool is L<shutdown> specifically or implicitely when the Thread::Pool object
is destroyed.  It must be specified as either the name of a subroutine or as
a reference to a (anonymous) subroutine.

The specified subroutine should expect the following parameters to be passed:

 1..N  any additional parameters that were passed with the call to L<new>.

Any values that are returned by this subroutine after closing down the thread,
are accessible with the L<result> method, but only if the thread was
L<removed> and a job ID was requested.

You can determine whether the "post" routine is called for a new worker thread
or for a monitoring thread by checking the L<self> or L<monitor> class method
inside the "post" routine.

=item stream

 stream => 'in_order_of_submit',	# assume caller's namespace

or:

 stream => 'Package::in_order_of_submit',

or:

 stream => \&SomeOther::in_order_of_submit,

or:

 stream => sub {print "anonymous sub called in order of submit\n"},

The "stream" field specifies the subroutine to be executed for streaming the
results of the "do" routine.  If specified, the "stream" routine is called
once for the result of each "do" subroutine, but in the order in which the
L<job>s were submitted rather than in the order in which the result were
obtained (which is by the very nature of threads, indeterminate).

The specified subroutine should expect the following parameters to be passed:

 1     the Thread::Pool object to which the worker thread belongs.
 2..N  the values that were returned by the "do" subroutine

The "stream" routine is executed in B<any> of the threads that are created
for the Thread::Pool object.  The system attempts to call the "stream"
routine in the same thread from which the values are obtained, but when
things get out of sync, other threads may stream the result of a job.  If
you want B<only one> thread to stream all results, use the "monitor" routine.

=item monitor

 monitor => 'in_order_of_submit',	# assume caller's namespace

or:

 monitor => 'Package::in_order_of_submit',

or:

 monitor => \&SomeOther::in_order_of_submit,

or:

 monitor => sub {print "anonymous sub called in order of submit\n"},

The "monitor" field specifies the subroutine to be executed for monitoring the
results of the "do" routine.  If specified, the "monitor" routine is called
once for the result of each "do" subroutine, but in the order in which the
L<job>s were submitted rather than in the order in which the result were
obtained (which is by the very nature of threads, indeterminate).

The specified subroutine should expect the following parameters to be passed:

 1..N  the values that were returned by the "do" subroutine

The "monitor" routine is executed in its own thread.  This means that all
results have to be passed between threads, and therefore be frozen and thawed
with L<Storable>.  If you can handle the streaming from different threads,
it is probably wiser to use the "stream" routine feature.

=item pre_post_monitor_only

 pre_post_monitor_only => 1, # default 0

The "pre_post_monitor_only" field only makes sense if a "monitor" routine
is specified.  If specified with a true value, indicates that the "pre" and
"post" routines (if specified) should only be called for the "monitor"
routine only and B<not> for the "do" routine.  Otherwise, the same "pre" and
"post" routine will be called for both the "do" as well as the "monitor"
routine.

When the "pre" and "post" routine are called for the "do" subroutine, the
L<self> class method returns the Thread::Pool object (which it doesn't do
when called in the "monitor" routine).

=item checkpoint

 checkpoint => 'checkpointing',			# assume caller's namespace

or:

 checkpoint => 'Package::checkpointing',

or:

 checkpoint => \&SomeOther::checkpointing,

or:

 checkpoint => sub {print "anonymous sub to do checkpointing\n"},

The "checkpoint" field specifies the subroutine to be executed everytime a
checkpoint should be made by a monitoring routine (e.g. for saving or updating
status).  It must be specified as either the name of a subroutine or as a
reference to a (anonymous) subroutine.

It only makes sense to specify a checkpoint routine if there is also a
monitoring routine specified.  No checkpointing will occur by default if a
monitoring routine B<is> specified.  The frequency of checkpointing can
be specified with the "frequency" field.

The specified subroutine should not expect any parameters to be passed.  Any
values returned by the checkpointing routine, will be lost.

=item frequency

 frequency => 100,                             # default = 1000

The "frequency" field specifies the number of jobs that should have been
monitored before the "checkpoint" routine is called.  If a checkpoint routine
is specified but no frequency field is specified, then a frequency of B<1000>
will be assumed.

This field has no meaning if no checkpoint routine is specified with the
"checkpoint" field.  The default frequency can be changed with the L<frequency>
method.

=item autoshutdown

 autoshutdown => 0, # default: 1

The "autoshutdown" field specified whether the L<shutdown> method should be
called when the object is destroyed.  By default, this flag is set to 1
indicating that the shutdown method should be called when the object is
being destroyed.  Setting the flag to a false value, will cause the shutdown
method B<not> to be called, causing potential loss of data and error messages
when threads are not finished when the program exits.

The setting of the flag can be later changed by calling the L<autoshutdown>
method.

=item workers

 workers => 5, # default: 1

The "workers" field specifies the number of worker threads that should be
created when the pool is created.  If no "workers" field is specified, then
only one worker thread will be created.  The L<workers> method can be used
to change the number of workers later. 

=item maxjobs

 maxjobs => 25, # default: 5 * workers

The "maxjobs" field specifies the B<maximum> number of jobs that can be sitting
on the belt to be handled (job throttling).  If a new L<job> submission
would exceed this amount, job submission will be halted until the number of
jobs waiting to be handled has become at least as low as the amount specified
with the "minjobs" field.

If the "maxjobs" field is not specified, an amount of 5 * the number of
worker threads will be assumed.  If you do not want to have any job throttling,
you can specify the value "undef" for the field.  But beware!  If you do not
have job throttling active, you may wind up using excessive amounts of memory
used for storing all of the job submission information.

The L<maxjobs> method can be called to change the job throttling settings
during the lifetime of the object.

=item minjobs

 minjobs => 10, # default: maxjobs / 2

The "minjobs" field specified the B<minimum> number of jobs that can be
waiting on the belt to be handled before job submission is allowed again
(job throttling).

If job throttling is active and the "minjobs" field is not specified, then
half of the "maxjobs" value will be assumed.

The L<minjobs> method can be called to change the job throttling settings
during the lifetime of the object.

=back

=head2 frequency

 Thread::Pool->frequency( 100 );

 $frequency = Thread::Pool->frequency;

The "frequency" class method allows you to specify the default frequency that
will be used when a checkpoint routine is specified with the "checkpoint"
field.  The default frequency is set to B<1000> if no other value has been
previously specified.

=head2 optimize

 Thread::Pool->optimize( 'cpu' );

 $optimize = Thread::Pool->optimize;

The "optimize" class method allows you to specify the default optimization
type that will be used if no "optimize" field has been explicitely specified
with a call to L<new>.  It returns the current default type of optimization.

Currently two types of optimization can be selected:

=over 2

=item memory

Attempt to use as little memory as possible.  Currently, this is achieved by
starting a seperate thread which hosts an unshared array.  This uses the
"Thread::Conveyor::Thread" sub-class.

=item cpu

Attempt to use as little CPU as possible.  Currently, this is achieved by
using a shared array (using the "Thread::Conveyor::Array" sub-class),
encapsulated in a hash reference if throttling is activated (then also using
the "Thread::Conveyor::Throttled" sub-class).

=back

=head1 POOL METHODS

The following methods can be executed on the Thread::Pool object.

=head2 job

 $jobid = $pool->job( @parameter );	# saves result
 $pool->job( @parameter );		# does not save result

The "job" method specifies a job to be executed by any of the available
L<workers>.  Which worker will execute the job, is indeterminate.  When it
will happen, depends on the number of jobs that still have to be done when
this job was submitted.

The input parameters are passed to the "do" subroutine as is.

If a return value is requested, then the return value(s) of the "do"
subroutine will be saved.  The returned value is a job ID that should be
used as the input parameter to L<result> or L<result_dontwait>.

=head2 waitfor

 @result = $pool->waitfor( @parameter ); # submit job and wait for result

The "waitfor" method specifies a job to be executed, wait for the result to
become ready and return the result.  It is in fact a shortcut for using
L<job> and L<result>.

The input parameters are passed to the "do" subroutine as is.

The return value(s) are what was returned by the "do" routine.  The meaning
of the return value(s) is entirely up to you as the developer.

=head2 result

 @result = $pool->result( $jobid );

The "result" method waits for the specified job to be finished and returns
the result of that job.

The input parameter is the job id as returned from the L<job> assignment.

The return value(s) are what was returned by the "do" routine.  The meaning
of the return value(s) is entirely up to you as the developer.

If you want to wait for B<any> job to be finished, use the L<result_any>
method.

If you don't want to wait for the job to be finished, but just want to see
if there is a result already, use the L<result_dontwait> method.

=head2 result_any

 @result = $pool->result_any;

 @result = $pool->result_any( \$jobid );

The "result_any" method waits for B<any> job to be finished and returns
the result of that job.

The optional input parameter is the reference to a scalar variable in which
the job id will be stored.

The return value(s) are what was returned by the "do" routine.  The meaning
of the return value(s) is entirely up to you as the developer.

If you don't want to wait for a job to be finished, but just want to see
if there is a result already, use the L<result_dontwait> method.

=head2 result_dontwait

 @result = $pool->result_dontwait( $jobid );

The "result_dontwait" method returns the result of the job if it is available.
If the job is not finished yet, it will return undef in scalar context or the
empty list in list context.

The input parameter is the job id as returned from the L<job> assignment.

If the result of the job is available, then the return value(s) are what was
returned by the "do" routine.  The meaning of the return value(s) is entirely
up to you as the developer.

If you want to wait for the job to be finished, use the L<result> method.

=head2 todo

 $todo = $pool->todo;

The "todo" method returns the number of L<job>s that are still left to be
done.

=head2 results

 $results = $pool->results;
 @result = $pool->results;

The "results" method returns the jobids of which there are results available
and which have not yet been fetched with L<result>.  Returns the number of
results available in scalar context.

=head2 add

 $tid = $pool->add;		# add 1 worker thread
 @tid = $pool->add( 5 );

The "add" method adds the specified number of worker threads to the pool
and returns the thread ID's (tid) of the threads that were created.

The input parameter specifies the number of workers to be added.  If no
number of workers is specified, then 1 worker thread will be added.

In scalar context, returns the thread ID (tid) of the first worker thread
that was added.  This usually only makes sense if you're adding only one
worker thread.

In list context, returns the thread ID's (tid) of the worker threads that
were created.

Each time a worker thread is added, the "pre" routine (if available) will
be called inside the thread.

=head2 remove

 $pool->remove;			# remove 1 worker thread
 $pool->remove( 5 );		# remove 5 worker threads

 $jobid = $pool->remove;	# remove 1 worker thread, save result
 @jobid = $pool->remove( 5 );	# remove 5 worker threads, save results

The "remove" method adds the specified number of special "remove" job to the
lists of jobs to be done.  It will return the job ID's if called in a non-void
context.

The input parameter specifies the number of workers to be removed.  If no
number of workers is specified, then 1 worker thread will be removed.

In void context, the results of the execution of the "post" subroutine(s)
is discarded.

In scalar context, returns the job ID of the result of the first worker
thread that was removed.  This usually only makes sense if you're removing
only one worker thread.

In list context, returns the job ID's of the result of all the worker
threads that were removed.

Each time a worker thread is L<remove>d, the "post" routine is called.  Its
return value(s) are saved only if a job ID was requested when removing the
thread.  Then the L<result> method can be called to obtain the results of
the "post" subroutine.

=head2 workers

 $workers = $pool->workers;	# find out number of worker threads
 $pool->workers( 10 );		# set number of worker threads

The "workers" method can be used to find out how many worker threads there
are currently available, or it can be used to set the number of worker
threads.

The input value, if specified, specifies the number of worker threads that
should be available.  If there are more worker threads available than the
number specified, then superfluous worker threads will be L<remove>d.  If
there are not enough worker threads available, new worker threads will be
L<add>ed.

The return value is the current number of worker threads.

=head2 frequency

 $frequency = $pool->frequency;

The "frequency" instance method returns the frequency with which the checkpoint
routine is being called.  Returns undef if no checkpointing is being done.

=head2 maxjobs

 $pool->maxjobs( 100 );
 $maxjobs = $pool->maxjobs;

The "maxjobs" method returns the maximum number of jobs that can be on the
belt before job throttling sets in.  The input value, if specified,
specifies the new maximum number of jobs that may be on the belt.  Job
throttling will be switched off if the value B<0> is specified.

Specifying the "maxjobs" field when creating the pool object with L<new> is
equivalent to calling this method.

The L<minjobs> method can be called to specify the minimum number of jobs
that must be on the belt before job submission is allowed again after reaching
the maximum number of jobs.  By default, half of the "maxjobs" value is
assumed.

=head2 minjobs

 $pool->minjobs( 50 );
 $minjobs = $pool->minjobs;

The "minjobs" method returns the minimum number of jobs that must be on the
belt before job submission is allowed again after reaching the maximum number
of jobs.  The input value, if specified, specifies the new minimum number of
jobs that must be on the belt.

Specifying the "minjobs" field when creating the pool object with L<new> is
equivalent to calling this method.

The L<maxjobs> method can be called to set the maximum number of jobs that
may be on the belt before job submission will be halted.

=head2 join

 $pool->join;

The "join" method waits until all of the worker threads that have been
L<remove>d have finished their jobs.  It basically cleans up the threads
that are not needed anymore.

The "shutdown" method call the "join" method after removing all the active
worker threads.  You therefore seldom need to call the "join" method
seperately.

=head2 removed

 $removed = $pool->removed;

The "removed" method returns the number of worker threads that were
L<remove>d over the lifetime of the object.

=head2 autoshutdown

 $pool->autoshutdown( 1 );
 $autoshutdown = $pool->autoshutdown;

The "autoshutdown" method sets and/or returns the flag indicating whether an
automatic L<shutdown> should be performed when the object is destroyed.

=head2 shutdown

 $pool->shutdown;

The "shutdown" method waits for all L<job>s to be executed, L<remove>s
all worker threads, handles any results that still need to be streamed, before
it returns.  Call the L<abort> method if you do not want to wait until all
jobs have been executed.

It is called automatically when the object is destroyed, unless specifically
disabled by providing a false value with the "autoshutdown" field when
creating the pool with L<new>, or by calling the L<autoshutdown> method.

=head2 abort

The "abort" method waits for all worker threads to finish their B<current>
job, L<remove>s all worker threads, before it returns.  Call the L<shutdown>
method if you want to wait until all jobs have been done.

You can restart the job handling process after calling "abort" by adding
L<workers> again.

=head2 done

 $done = $pool->done;

The "done" method returns the number of L<job>s that has been performed by
the L<removed> worker threads of the pool.

The "done" method is typically called after the L<shutdown> method
has been called.

=head2 notused

 $notused = $pool->notused;

The "notused" method returns the number of removed threads that have not
performed any jobs.  It provides a heuristic to determine how many
L<workers> you actually need for a specific application: a value > 0
indicates that you have specified too many worker threads for this
application.

The "notused" method is typically called after the L<shutdown> method
has been called.

=head1 INSIDE JOB METHODS

The following methods only make sense inside the "pre", "do", "post",
"stream" and "monitor" routines.

=head2 self

 $self = Thread::Pool->self;

The class method "self" returns the object to which this thread belongs.
It is available within the "pre", "do", "post", "stream" and "monitor"
subroutines only.

=head2 monitor

 $monitor = Thread::Pool->monitor;

The class method "monitor" returns the Thread::Conveyor::Monitored object
that is associated with the pool.  It is available only if the "monitor"
field was specified in L<new>.  And then only within the "pre", "do", "post",
"stream" and "monitor" subroutines only.

=head2 remove_me

 Thread::Pool->remove_me;

The "remove_me" class method only makes sense within the "do" subroutine.
It indicates to the job dispatcher that this worker thread should be removed
from the pool.  After the "do" subroutine returns, the worker thread will
be removed.

=head2 jobid

 $jobid = Thread::Pool->jobid;

The "jobid" class method only makes sense within the "do" subroutine in
streaming mode.  It returns the job ID value of the current job.  This can
be used connection with the L<dont_set_result> and the L<set_result> methods
to have another thread set the result of the current job.

=head2 dont_set_result

 Thread::Pool->dont_set_result;

The "dont_set_result" class method only makes sense within the "do" subroutine.
It indicates to the job dispatcher that the result of this job should B<not>
be saved.  This is for cases where the result of this job will be placed in
the result hash at some time in the future by another thread using the
L<set_result> method.

=head2 set_result

 Thread::Pool->self->set_result( $jobid,@param );

The "set_result" object method only makes sense within the "do" subroutine.
It allows you to set the result of B<other> jobs than the one currently being
performed.

This method is only needed in B<very> special situations.  Normally, just
returning values from the "do" subroutine is enough to have the result saved.
This method is exposed to the outside world in those cases where a specific
thread becomes responsible for setting the result of other threads (which
used the L<dont_set_result> method to defer saving their result.

The first input parameter specifies the job ID of the job for which to set
the result.  The rest of the input parameters is considered to be the result
to be saved.  Whatever is specified in the rest of the input parameters, will
be returned with the L<result> or L<result_dontwait> methods.

=head1 REQUIRED MODULES

 Thread::Conveyor (0.15)
 Thread::Conveyor::Monitored (0.11)

=head1 OPTIMIZATIONS

This module uses L<load> to reduce memory and CPU usage. This causes
subroutines only to be compiled in a thread when they are actually needed at
the expense of more CPU when they need to be compiled.  Simple benchmarks
however revealed that the overhead of the compiling single routines is not
much more (and sometimes a lot less) than the overhead of cloning a Perl
interpreter with a lot of subroutines pre-loaded.

=head1 CAVEATS

Passing unshared values between threads is accomplished by serializing the
specified values using L<Thread::Serialize>.  Please see the CAVEATS section
there for an up-to-date status of what can be passed around between threads.

=head1 EXAMPLES

There are currently two examples.

=head2 simple asynchronous log file resolving filter

This is an example of a very simple asynchronous log file resolver filter.

Because the IP number to domain name translation is dependent on external
DNS servers, it can take quite some (wallclock) time before a response is
returned by the C<gethostbyaddr> function.  In a single threaded environment,
a single bad DNS server can severely slow down the resolving process.  In a
threaded environment, you can have one thread waiting for a slow DNS server
while other threads are able to obtain answers in the mean time.

This example uses a shared hash to keep results from DNS server responses,
so that if an IP number was attempted to be resolved once (either successfully
or unsuccessfully), it will not be attempted again: instead the value from the
hash will be assumed.

 # You should always use strict!
 # Using Thread::Pool by itself is enough, no "use threads;" needed
 # Initialize the shared hash with IP numbers and their results

 use strict;
 use Thread::Pool;
 my %resolved : shared;

 # Create the pool of threads

 my $pool = Thread::Pool->new(
  {
   workers => 10,
   do => \&do,
   monitor => \&monitor,
  }
 );

 # Submit each line as a job to the pool

 $pool->job( $_ ) while <>;

 #--------------------------------------------------------------------
 # Handle a single job
 #  IN: 1 log line to resolve
 # OUT: 1 resolved log line

 sub do {

 # Substitute the IP number at the start with the name or with the original
 # Return the adapted value

   $_[0] =~ s#^(\d+\.\d+\.\d+\.\d+)#
    $resolved{$1} ||= gethostbyaddr( pack( 'C4',split(/\./,$1)),2 ) || $1#e;
   $_[0];
 } #do

 #--------------------------------------------------------------------
 # Output the results in the order they were submitted
 #  IN: 1 resolved log line

 sub monitor { print $_[0] } #monitor

This is a very simple filter.  The main drawback is that many threads can
be looking up the same IP number at the same time.

=head2 another asynchronous log file resolving filter

This is an example of a not so very simple asynchronous log file resolver
filter.  This is in fact the base code for the L<Thread::Pool::Resolve>
module.

In this example, the L<dont_set_result> and L<set_result> methods are used
to put up all lines with the same unresolved IP number in the same thread
until the DNS server returns, either with or without a result.  Then all
the lines with that IP number are handled by that thread: the other threads
have long before that already continued attempting to handle other lines.

Because only the "do" subroutine is different from the previous example,
we're only showing that.

 #--------------------------------------------------------------------
 # Handle a single job
 #  IN: 1 log line to resolve
 # OUT: 1 resolved log line (if already resolved, else ignored)

 sub do {

 # Obtain the line to work with
 # Return it now if it is already resolved (at least not an IP number there)
 # Save the IP number for later usage, line is now without IP number

   my $line = shift;
   return $line unless $line =~ s#^(\d+\.\d+\.\d+\.\d+)##;
   my $ip = $1;

 # Make sure we're the only one to access the resolved hash now
 # If there is already information for this IP number
 #  Return what is there with the line if it was resolved already

   {lock( %resolved );
    if (exists( $resolved{$ip} )) {
      return ($resolved{$ip} || $ip).$line unless ref( $resolved{$ip} );

 #  Set the rest of the line in the todo hash, keyed to jobid
 #  Set the flag that this result should not be set in the result hash
 #  And return without anything (thread will continue with next job)

      $resolved{$ip}->{Thread::Pool->jobid} = $line;
      Thread::Pool->dont_set_result;
      return;

 # Else (first time this IP number is encountered)
 #  Create a empty shared hash
 #  Save a reference to the hash in the todo hash as info for this IP number

    } else {
      my %hash : shared;
      $resolved{$ip} = \%hash;
    }
   } #%resolved

 # Do the actual name resolving (may take quite some time) or use IP number
 # Obtain local copy of the Thread::Pool object
 # Obtain local copy of the todo hash

   my $domain = gethostbyaddr( pack( 'C4',split(/\./,$ip)),2 ) || $ip;
   my $pool = Thread::Pool->self;
   my $todo = $resolved{$ip};

 # Make sure we're the only one accessing the resolved hash (rest of this sub)
 # For all the lines with this IP number
 #  Set the results
 # Remove the todo hash and replace by domain or blank string if unresolvable
 # Return the result for this job

   lock( %resolved );
   while (my $key = each %{$todo}) {
       $pool->set_result( $key,$domain.$todo->{$key} )
   }
   $resolved{$ip} = $domain eq $ip ? undef : $domain;
   $domain.$line;
 } #do

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2002, 2003, 2010 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<threads>, L<Thread::Conveyor>, L<Thread::Conveyor::Monitored>,
L<Thread::Serialize>.

=cut
