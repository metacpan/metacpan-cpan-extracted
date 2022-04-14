package cPanel::TaskQueue::Scheduler;
$cPanel::TaskQueue::Scheduler::VERSION = '0.903';
# This module handles queuing of tasks for execution. The queue is persistent
# handles consolidating of duplicate tasks.

use strict;

#use warnings;
use cPanel::TaskQueue ();
use cPanel::TaskQueue::Task();
use cPanel::StateFile ();

# -----------------------------------------------------------------------------
# Policy code: The following allows is a little weird because its intent is to
# change the policy by which some code is executed, without adding a gratuitous
# object and polymorphism into the mix.
#
# I had originally redefined the methods, but that seems a little too magical
# when indirecting through goto works as well (if a little slower).

# These methods are intended to help document the importance of the message and
#   to supply 'seam' that could be used to modify the logging behavior of the
#   StateFile.
my $are_policies_set = 0;
my $the_serializer;
my $pkg = __PACKAGE__;

#
# This method allows changing the policies for logging and locking.
sub import {
    my $class = shift;
    die "Not an even number of arguments to the $pkg module\n" if @_ % 2;
    die "Policies already set elsewhere\n"                     if $are_policies_set;
    return 1 unless @_;    # Don't set the policies flag.

    while (@_) {
        my ( $policy, $module ) = splice( @_, 0, 2 );
        my @methods = ();
        if ( '-logger' eq $policy ) {
            cPanel::StateFile->import( '-logger' => $module );
        }
        elsif ( '-serializer' eq $policy ) {
            _load_serializer_module($module);
            $the_serializer = $module;
        }
        else {
            die "Unrecognized policy '$policy'\n";
        }
    }
    $are_policies_set = 1;
    return 1;
}

sub _load_serializer_module {
    my ($module) = @_;
    die "Supplied serializer must be a module name.\n" if ref $module;
    die "'$module' does not look like a serializer" unless $module =~ m{^\w+(?:::\w+)*$};
    eval "use $module;";    ## no critic (ProhibitStringyEval)
    die $@ if $@;
    die 'Supplied serializer object does not support the correct interface.'
      unless _valid_serializer($module);
    return;
}

sub _valid_serializer {
    my ($serializer) = @_;
    foreach my $method (qw/load save filename/) {
        return unless eval { $serializer->can($method) };
    }
    return 1;
}

sub _get_serializer {
    unless ( defined $the_serializer ) {
        eval 'use cPanel::TQSerializer::Storable;';    ## no crititc (ProhibitStringyEval)
        cPanel::StateFile->_throw(@_) if $@;
        $the_serializer = 'cPanel::TQSerializer::Storable';
    }
    return $the_serializer;
}

# Replacement for List::Util::first, so I don't need to bring in the whole module.
sub _first (&@) {    ## no critic(ProhibitSubroutinePrototypes)
    my $pred = shift;
    local $_;
    foreach (@_) {
        return $_ if $pred->();
    }
    return;
}

sub TO_JSON {
    return { %{ $_[0] } };
}

# Namespace value used when creating unique task ids.
my $tasksched_uuid = 'TaskQueue-Scheduler';

{
    my $FILETYPE      = 'TaskScheduler';    # Identifier at the beginning of the state file
    my $CACHE_VERSION = 2;                  # Cache file version number.

    # Disk Cache & state file.
    #
    sub get_name { $_[0]->{scheduler_name}; }

    # --------------------------------------
    # Class methods

    # Initialize parameters.
    sub new {
        my ( $class, $args_ref ) = @_;
        my $self = bless {
            next_id    => 1,
            time_queue => [],
            disk_state => undef,
        }, $class;

        if ( defined $args_ref->{serial} ) {
            _load_serializer_module( $args_ref->{serial} );
            $self->{serializer} = $args_ref->{serial};
        }
        $self->{serializer} ||= _get_serializer();
        if ( exists $args_ref->{token} ) {
            my ( $version, $name, $file ) = split( ':\|:', $args_ref->{token} );

            # have all parts
            cPanel::StateFile->_throw('Invalid token.')
              unless defined $version
              and defined $name
              and defined $file;

            # all parts make sense.
            my $name_match = _get_serializer()->filename("${name}_sched");
            cPanel::StateFile->_throw('Invalid token.')
              unless 'tqsched1' eq $version and $file =~ m{/\Q$name_match\E$};

            $self->{scheduler_name}  = $name;
            $self->{disk_state_file} = $file;
        }
        else {
            $args_ref->{state_dir} ||= $args_ref->{cache_dir} if exists $args_ref->{cache_dir};
            cPanel::StateFile->_throw('No caching directory supplied.') unless exists $args_ref->{state_dir};
            cPanel::StateFile->_throw('No scheduler name supplied.')    unless exists $args_ref->{name};

            $self->{disk_state_file} = $self->_serializer()->filename("$args_ref->{state_dir}/$args_ref->{name}_sched");
            $self->{scheduler_name}  = $args_ref->{name};
        }

        # Make a disk file to track the object.
        my $state_args = {
            state_file => $self->{disk_state_file}, data_obj => $self,

            # Deprecated version
            exists $args_ref->{cache_timeout} ? ( timeout => $args_ref->{cache_timeout} ) : (),
            exists $args_ref->{state_timeout} ? ( timeout => $args_ref->{state_timeout} ) : (),
            exists $args_ref->{logger}        ? ( logger  => $args_ref->{logger} )        : (),
        };
        eval {
            $self->{disk_state} = cPanel::StateFile->new($state_args);
            1;
        } or do {
            my $ex = $@;

            # If not a loading error, rethrow.
            cPanel::StateFile->_throw($ex) unless $ex =~ /Not a recognized|Invalid version/;
            cPanel::StateFile->_warn($ex);
            cPanel::StateFile->_warn("Moving bad state file and retry.\n");
            cPanel::StateFile->_notify(
                'Unable to load TaskQueue::Scheduler metadata',
                "Loading of [$self->{disk_state_file}] failed: $ex\n" . "Moving bad file to [$self->{disk_state_file}.broken] and retrying.\n"
            );
            unlink "$self->{disk_state_file}.broken";
            rename $self->{disk_state_file}, "$self->{disk_state_file}.broken";

            $self->{disk_state} = cPanel::StateFile->new($state_args);
        };
        return $self;
    }

    sub throw {
        my $self = shift;
        return $self->{disk_state} ? $self->{disk_state}->throw(@_) : cPanel::StateFile->_throw(@_);
    }

    # Not using warn, so don't define it.
    sub info {
        my $self = shift;
        return $self->{disk_state} ? $self->{disk_state}->info(@_) : undef;
    }

    # -------------------------------------------------------
    # Pseudo-private methods. Should not be called except under unusual circumstances.
    sub _serializer {
        my ($self) = @_;
        return $self->{serializer};
    }

    sub _state_file {
        my ($self) = @_;
        return $self->{disk_state_file};
    }

    # -------------------------------------------------------
    # Public methods
    sub load_from_cache {
        my ( $self, $fh ) = @_;

        local $/;
        my ( $magic, $version, $meta ) = $self->_serializer()->load($fh);

        $self->throw("Not a recognized TaskQueue Scheduler state file.\n")   unless defined $magic   and $magic eq $FILETYPE;
        $self->throw("Invalid version of TaskQueue Scheduler state file.\n") unless defined $version and $version eq $CACHE_VERSION;

        # Next id should continue increasing.
        #   (We might want to deal with wrap-around at some point.)
        $self->{next_id} = $meta->{nextid} if $meta->{nextid} > $self->{next_id};

        # Clean queues that have been read from disk.
        $self->{time_queue} = [ grep { _is_item_sane($_) } @{ $meta->{waiting_queue} } ];

        return 1;
    }

    sub save_to_cache {
        my ( $self, $fh ) = @_;

        my $meta = {
            nextid        => $self->{next_id},
            waiting_queue => $self->{time_queue},
        };
        return $self->_serializer()->save( $fh, $FILETYPE, $CACHE_VERSION, $meta );
    }

    sub schedule_task {
        my ( $self, $command, $args ) = @_;

        $self->throw('Cannot queue an empty command.') unless defined $command;
        $self->throw('Args is not a hash ref.')        unless defined $args and 'HASH' eq ref $args;

        my $time = time;
        $time += $args->{delay_seconds} if exists $args->{delay_seconds};
        $time = $args->{at_time}        if exists $args->{at_time};

        if ( eval { $command->isa('cPanel::TaskQueue::Task') } ) {
            if ( 0 == $command->retries_remaining() ) {
                $self->info('Task with 0 retries not scheduled.');
                return;
            }
            return $self->_schedule_the_task( $time, $command );
        }

        # must have non-space characters to be a command.
        $self->throw('Cannot queue an empty command.') unless $command =~ /\S/;

        my @retry_attrs = ();
        if ( exists $args->{attempts} ) {
            return unless $args->{attempts} > 0;
            @retry_attrs = (
                retries  => $args->{attempts},
                userdata => { sched => $self->get_token() }
            );
        }
        my $task = cPanel::TaskQueue::Task->new(
            {
                cmd => $command, nsid => $tasksched_uuid, id => $self->{next_id}++,
                @retry_attrs
            }
        );
        return $self->_schedule_the_task( $time, $task );
    }

    sub unschedule_task {
        my ( $self, $uuid ) = @_;

        unless ( _is_valid_uuid($uuid) ) {
            $self->throw('No Task uuid argument passed to unschedule_task.');
        }

        # Lock the queue before we begin accessing it.
        my $guard     = $self->{disk_state}->synch();
        my $old_count = @{ $self->{time_queue} };

        $self->{time_queue} = [ grep { $_->{task}->uuid() ne $uuid } @{ $self->{time_queue} } ];

        # All changes complete, save to disk.
        $guard->update_file();
        return $old_count > @{ $self->{time_queue} };
    }

    sub is_task_scheduled {
        my ( $self, $uuid ) = @_;

        unless ( _is_valid_uuid($uuid) ) {
            $self->throw('No Task uuid argument passed to is_task_scheduled.');
        }

        # Update from disk, but don't worry about lock. Information only.
        $self->{disk_state}->synch();

        return _first { $_->{task}->uuid() eq $uuid } @{ $self->{time_queue} };
    }

    sub when_is_task_scheduled {
        my ( $self, $uuid ) = @_;

        unless ( _is_valid_uuid($uuid) ) {
            $self->throw('No Task uuid argument passed to when_is_task_scheduled.');
        }

        # Update from disk, but don't worry about lock. Information only.
        $self->{disk_state}->synch();

        my $task = _first { $_->{task}->uuid() eq $uuid } @{ $self->{time_queue} };
        return unless defined $task;
        return $task->{time};
    }

    sub how_many_scheduled {
        my ($self) = @_;

        # Update from disk, but don't worry about lock. Information only.
        $self->{disk_state}->synch();
        return scalar @{ $self->{time_queue} };
    }

    sub peek_next_task {
        my ($self) = @_;

        # Update from disk, but don't worry about lock. Information only.
        $self->{disk_state}->synch();
        return unless @{ $self->{time_queue} };

        return $self->{time_queue}->[0]->{task}->clone();
    }

    sub seconds_until_next_task {
        my ($self) = @_;

        # Update from disk, but don't worry about lock. Information only.
        $self->{disk_state}->synch();
        return unless @{ $self->{time_queue} };

        return $self->{time_queue}->[0]->{time} - time;
    }

    sub process_ready_tasks {
        my ( $self, $queue ) = @_;

        unless ( defined $queue and eval { $queue->can('queue_task') } ) {
            $self->throw('No valid queue supplied.');
        }

        # Don't generate lock yet, we may not need one.
        $self->{disk_state}->synch();
        my $count = 0;
        my $guard;
        eval {
            while ( @{ $self->{time_queue} } ) {
                my $item = $self->{time_queue}->[0];

                last if time < $item->{time};
                if ( !$guard ) {

                    # Now we know we'll be changing the schedule, so we need to
                    # lock it.
                    $guard ||= $self->{disk_state}->synch();
                    next;
                }

                # Should be safe from deadlock unless queue calls back to me.
                $queue->queue_task( $item->{task} );
                ++$count;

                # Only remove from the schedule when the queue has processed it.
                shift @{ $self->{time_queue} };
            }
        };
        my $ex = $@;
        $guard->update_file() if $count && $guard;
        $self->throw($ex)     if $ex;

        return $count;
    }

    sub flush_all_tasks {
        my ( $self, $queue ) = @_;

        unless ( defined $queue and eval { $queue->can('queue_task') } ) {
            $self->throw('No valid queue supplied.');
        }

        my @ids;
        my $guard = $self->{disk_state}->synch();
        eval {
            while ( @{ $self->{time_queue} } ) {
                my $item = $self->{time_queue}->[0];

                # Should be safe from deadlock unless queue calls back to me.
                my $id = $queue->queue_task( $item->{task} );
                push @ids, $id if $id;

                # Only remove from the schedule when the queue has processed it.
                shift @{ $self->{time_queue} };
            }
        };
        my $ex = $@;
        $guard->update_file() if @ids;
        $self->throw($ex)     if $ex;

        return @ids;
    }

    sub delete_all_tasks {
        my ($self) = @_;
        my $guard  = $self->{disk_state}->synch();
        my $count  = @{ $self->{time_queue} };
        $self->{time_queue} = [];
        $guard->update_file() if $count;

        return $count;
    }

    sub get_token {
        my ( $self, $command, $time ) = @_;

        return join( ':|:', 'tqsched1', $self->{scheduler_name}, $self->{disk_state_file} );
    }

    sub snapshot_task_schedule {
        my ($self) = @_;

        $self->{disk_state}->synch();

        return [ map { { time => $_->{time}, task => $_->{task}->clone() } } @{ $self->{time_queue} } ];
    }

    # ---------------------------------------------------------------
    #  Private Methods.
    sub _schedule_the_task {
        my ( $self, $time, $task ) = @_;

        my $guard = $self->{disk_state}->synch();
        my $item  = { time => $time, task => $task };

        # if the list is empty, or time after all in list.
        if ( !@{ $self->{time_queue} } or $time >= $self->{time_queue}->[-1]->{time} ) {
            push @{ $self->{time_queue} }, $item;
        }
        elsif ( $time < $self->{time_queue}->[0]->{time} ) {

            # schedule before anything in the list
            unshift @{ $self->{time_queue} }, $item;
        }
        else {

            # find the correct spot in the list.
            foreach my $i ( 1 .. $#{ $self->{time_queue} } ) {
                next unless $self->{time_queue}->[$i]->{time} > $time;
                splice( @{ $self->{time_queue} }, $i, 0, $item );
                last;
            }
        }

        $guard->update_file();
        return $task->uuid();
    }

    sub _is_item_sane {
        my ($item) = @_;
        return unless 'HASH' eq ref $item;
        return unless exists $item->{task} and exists $item->{time};
        $item->{task} = cPanel::TaskQueue::Task->reconstitute( $item->{task} );
        return unless eval { $item->{task}->isa('cPanel::TaskQueue::Task') };
        return $item->{time} =~ /^\d+$/;
    }

    sub _is_valid_uuid {
        return cPanel::TaskQueue::Task::is_valid_taskid(shift);
    }
}

1;

__END__


=head1  NAME

cPanel::TaskQueue::Scheduler - Priority queue of Tasks to Queue at some time in the future.

=head1 SYNOPSIS

    use cPanel::TaskQueue;
    use cPanel::TaskQueue::Scheduler;

    my $queue = cPanel::TaskQueue->new( { name => 'tasks', state_dir => '/home/$user/.cpanel/state' } );
    my $sched = cPanel::TaskQueue::Scheduler->new( { name => 'tasks', state_dir => '/home/$user/.cpanel/state' } );

    $sched->schedule_task( 'init_quota', {delay_seconds=>10} );
    $sched->schedule_task( 'edit_quota fred 0', {delay_seconds=>60} );

    # ... some time later ...
    # This processing loop is a bit more complicated than the one for just
    # the TaskQueue.
    while (1) {
        eval {
            $sched->process_ready_tasks( $queue );
            if ( $queue->has_work_to_do() ) {
                $queue->process_next_task();
            }
            else {
                my $wait = $sched->seconds_until_next_task();
                next if defined $wait and 0 == $wait;

                $wait = $default_wait if !$wait || $wait > $default_wait;
                sleep $wait;
            }
        };
        Carp::carp "Exception detected: $@" if $@;
    }

=head1  DESCRIPTION

This module provides the ability to schedule tasks for later insertion into a
C<cPanel::TaskQueue>.

=head1 PUBLIC METHODS

=over 4

=item cPanel::TaskQueue::Scheduler->new( $hashref )

Creates a new TaskQueue::Scheduler object based on the parameters from the
supplied hashref.

=over 4

=item I<state_dir>

This required parameter specifies a directory where the state should be written.
This directory is created if it does not exist.

=item I<name>

This required parameter specifies the name of the scheduler. This name is used
to construct the name of the state file used to store the scheduler information.

=item I<state_timeout>

This optional parameter specifies the timeout to use for flocking the state file.
The value is in seconds and defaults to the cPanel::StateFile default value.

=item I<cache_timeout>

I<Deprecated>. Replaced by the I<state_timeout>.

=item I<token>

If a valid token parameter is supplied, recreate the C<Scheduler> described by
the token. This allows recreating access to a Scheduler that was instantiated
in another process.  It also helps support serializing information about a
C<Scheduler> as part of a defined task.

If a token is supplied, the I<name> and I<state_dir> parameters are ignored
because the token encodes that information.

=back

=item $s->get_name()

Returns the name of the C<Scheduler> object.

=item $s->schedule_task( $command, $hashref )

Schedule the supplied I<command> to be queued as described by the parameters in the supplied I<hashref>.
The I<hashref> has three optional parameters that specify the scheduling time:

=over 4

=item I<at_time>

This parameter specifies a specific time in epoch seconds after which the command will be queued.

=item I<delay_seconds>

This parameter specifies a number of seconds to wait before scheduling the supplied command. If both
I<at_time> and I<delay_seconds> are specified, I<at_time> is used.

=item I<attempts>

Specifies retry count for the task to be rescheduled if the task times out.

=back

=item $s->unschedule_task( $uuid )

Remove the task associated with the supplied I<uuid> from the schedule, if
it has not been processed yet. Returns true on success.

=item $s->get_token()

Returns an opaque string containing the information needed to construct a new
copy of this scheduler. Normally used when requesting a new scheduling at a later
point in time.

=item $s->throw( $msg )

Log the supplied message and C<die>.

=item $s->warn( $msg )

Log the supplied message as a warning.

=item $s->info( $msg )

Log the supplied message as an informational message.

=back

=head2 QUEUE INFORMATION

=over 4

=item $s->peek_next_task()

Get a copy of the next Task to be scheduled or C<undef> if the scheduler is
empty.

Because of the nature of a task scheduler, there is no guarantee that this task
will remain unscheduled after the method call. That is one reason that a copy
is returned.

=item $s->is_task_scheduled( $uuid )

Does the specified I<uuid> reference a task to be scheduled?

Because of the nature of a task scheduler, the particular I<uuid> tested may
be scheduled for processing immediately after the test. Therefore, a true answer
is not as useful as it might seem. A false answer does tell us that the item is
no longer waiting.

=item $s->when_is_task_scheduled( $uuid )

Returns the time (in epoch seconds) when the Task referenced by I<uuid> is
scheduled to be run or C<undef> if I<uuid> does not reference a valid task.

Because of the nature of a task scheduler, the particular I<uuid> tested may
be scheduled for processing immediately after the test.

=item $s->how_many_scheduled()

Gives a count at this particular point in time of the number of items currently
in the scheduler. Since an item may be removed and processed any time the
C<process_ready_tasks()> method is called, this count may not be correct immediately
after the method returns.

Most useful for the general case of telling if the queue is really full, or
mostly empty.

=item $s->seconds_until_next_task()

Returns the number of seconds until the next task is ready to be processed, or
C<undef> if there are no tasks to process.

=item $s->snapshot_task_schedule()

Returns an array reference containing a series of hashes containing the I<time>
a task is scheduled to run and a copy of the I<task> to run at that time. The
first item in the array is guaranteed to be the next task to run. The order of
the rest of the list is not guaranteed.

This lack of guarantee allows the internal code to be implemented as either a sorted
array or a heap without requiring this method to fix up the array.

=back

=head2 SCHEDULING

=over 4

=item $s->process_ready_tasks( $queue )

This method takes all of the Tasks that have reached (or passed) their schedule
time and passes them to the C<queue_task> method of the supplied I<queue> object.
No object is removed from the scheduler unless C<queue_task> runs without an
exception.

In addition, the process of moving a Task from the scheduler to the queue replaces
it's I<uuid>, so don't expect the C<uuid> from the scheduler to have any relation
to the C<uuid> of the same task in the C<TaskQueue>.

Returns the number of tasks processed, C<0> if there were no tasks to process.

=item $s->flush_all_tasks( $queue )

This method takes all Tasks, whether or not they have reached their schedule
time and passes the to the C<queue_task> method of the supplied I<queue>
object. No object is removed from the scheduler unless C<queue_task> runs
without an exception.

Returns a list of the C<uuid>s of all tasks that are scheduled.

I<Warning>: This is almost certainly a bad idea. But, there are a few cases where
the scheduling may need to be overridden.

=item $s->delete_all_tasks( $queue )

This method removes all Tasks from the scheduler without any processing.

Returns a count of the number of tasks that were removed.

I<Warning>: This is almost certainly a bad idea. But, there are a few cases where
the scheduled tasks may need to be discarded.

=back

=head2 CACHE SUPPORT

These methods should not be used directly, they exist to support the
C<cPanel::StateFile> interface that persists the scheduler information to disk.

=over 4

=item $q->load_from_cache( $fh )

This method loads the scheduler information from the disk state. It is called
by the C<cPanel::StateFile> object owned by this object.

The user of this class should never need to call this method.

=item $q->save_to_cache( $fh )

This method saves the scheduler information to the disk state. It is called by
the C<cPanel::StateFile> object owned by this object.

The user of this class should never need to call this method.

=back

=head1 LOGGER OBJECT

By default, the C<Scheduler> uses C<die> and C<warn> for all messages during
runtime. However, it supports a mechanism that allows you to insert a
logging/reporting system in place by providing an object to do the logging for
us.

To provide a different method of logging/reporting, supply an object to do the
logging as follows when C<use>ing the module.

   use cPanel::TaskQueue::Scheduler ( '-logger' => $logger );

The supplied object should supply (at least) 3 methods: C<throw>, C<warn>, and
C<info>. When needed these methods will be called with the messages to be logged.

The C<throw> method is expected to use C<die> to exit the method. The others
are expected to continue. For example, an appropriate class for C<Log::Log4perl>
might do something like the following:

    package Policy::Log4perl;
    use strict;
    use warnings;
    use Log::Log4perl;

    sub new {
        my ($class) = shift;
        my $self = {
            logger => Log::Log4perl->get_logger( @_ )
        };
        return bless, $class;
    }

    sub throw {
        my $self = shift;
        $self->{logger}->error( @_ );
        die @_;
    }

    sub warn {
        my $self = shift;
        $self->{logger}->warn( @_ );
    }

    sub info {
        my $self = shift;
        $self->{logger}->info( @_ );
    }

This would call the C<Log4perl> code as errors or other messages result in
messages.

This only works once for a given program, so you can't reset the policy in
multiple modules and expect it to work.

In addition to setting a global logger, a new logger object can be supplied
when creating a specific C<Scheduler> object.

=head1 DIAGNOSTICS

The following messages can be reported by this module:

=over 4

=item C<< Invalid token. >>

The I<token> parameter supplied to I<new> is not of the correct form to be a C<cPanel::TaskQueue::Scheduler> token.

=item C<< No caching directory supplied. >>

The required I<state_dir> parameter was missing when constructing the
C<TaskQueue::Scheduler> object. The object was not created.

=item C<< No queue name supplied. >>

The required I<name> parameter was missing when constructing the C<TaskQueue::Scheduler>
object. The object was not created.

=item C<< Not a recognized TaskQueue Scheduler state file. >>

=item C<< Invalid version of TaskQueue Scheduler state file. >>

Either the state file is invalid or it is not a C<cPanel::TaskQueue::Scheduler>
state file.

=item C<< Cannot queue an empty command. >>

The command string supplied to C<schedule_task_*> was either C<undef> or empty.

=item C<< Task with 0 retries not scheduled. >>

The C<Task> supplied to one of the C<schedule_task*> methods has a remaining retry count of 0. The task
has been discarded. This is an informational message only.

=item C<< No Task uuid argument passed to %s. >>

The specified method requires a I<uuid> to specify which task to operate on.
None was supplied.

=item C<< No valid queue supplied. >>

The C<process_ready_tasks> methods requires a C<TaskQueue> as a parameter. (Or, at least, an object with a C<queue_task> method.)

=item C<< Not an even number of arguments to the cPanel::TaskQueue::Scheduler module >>

The parameters passed to the C<import> method should be name/value pairs.

=item C<< Policies already set elsewhere >>

Some other file has already set the policies.

=item C<< Unrecognized policy '%s' >>

The only policy supported by C<cPanel::TaskQueue::Scheduler> is I<-logger>.

=back

=head1 DEPENDENCIES

YAML::Syck

cPanel::TaskQueue, cPanel::TaskQueue::Task, cPanel::StateFile

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

none reported.

=head1 SEE ALSO

cPanel::TaskQueue::Processor, cPanel::TaskQueue::Task, and cPanel::StateFile

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, cPanel, Inc. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
