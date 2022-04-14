package cPanel::TaskQueue;
$cPanel::TaskQueue::VERSION = '0.903';
# This module handles queuing of tasks for execution. The queue is persistent
# handles consolidating of duplicate tasks.

# ABSTRACT: Manage a FIFO queue of tasks to perform.

use strict;

#use warnings;
use cPanel::TaskQueue::Task();
use cPanel::TaskQueue::Processor();
use cPanel::StateFile ();

my $WNOHANG;
if ( !exists $INC{'POSIX.pm'} ) {

    # If POSIX is not already loaded, try for CPanel's tiny module.
    ## no critic (ProhibitStringyEval)
    eval 'local $SIG{__DIE__} = "DEFAULT";
          use cPanel::POSIX::Tiny 0.8;  #issafe
          $WNOHANG = &cPanel::POSIX::Tiny::WNOHANG;';
}
if ( !$WNOHANG ) {
    ## no critic (ProhibitStringyEval)
    eval 'use POSIX ();
          $WNOHANG = &POSIX::WNOHANG;';
}

# -----------------------------------------------------------------------------
# Policy code: The following allows is a little weird because its intent is to
# change the policy by which some code is executed, without adding a gratuitous
# object and polymorphism into the mix.

my $are_policies_set = 0;
my $the_serializer;

#
# This method allows changing the policies for logging and locking.
sub import {
    my $class = shift;
    die 'Not an even number of arguments to the ' . __PACKAGE__ . " module\n" if @_ % 2;
    die "Policies already set elsewhere\n"                                    if $are_policies_set;
    return 1 unless @_;    # Don't set the policies flag.

    while (@_) {
        my ( $policy, $module ) = splice( @_, 0, 2 );
        my @methods = ();
        my @sf_policies;
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
    die "Supplied serializer module '$module' does not support the correct interface."
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
        eval 'use cPanel::TQSerializer::Storable;';    ## no critic(ProhibitStringyEval)
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

# Namespace string used when creating task ids.
my $taskqueue_uuid = 'TaskQueue';

# Class-wide definition of the valid processors
my %valid_processors;
END { undef %valid_processors }    # case CPANEL-10871 to avoid a SEGV during global destruction

{
    my $FILETYPE      = 'TaskQueue';    # Identifier at the beginning of the state file
    my $CACHE_VERSION = 3;              # Cache file version number.

    # State File
    #
    sub get_name                  { return $_[0]->{queue_name}; }
    sub get_default_timeout       { return $_[0]->{default_task_timeout}; }
    sub get_max_timeout           { return $_[0]->{max_task_timeout}; }
    sub get_max_running           { return $_[0]->{max_in_process}; }
    sub get_default_child_timeout { return $_[0]->{default_child_timeout}; }

    # Processing pausing
    sub pause_processing {
        my ($self) = @_;
        my $guard = $self->{disk_state}->synch();
        $self->{paused} = 1;
        $guard->update_file();
        return;
    }

    sub resume_processing {
        my ($self) = @_;
        my $guard = $self->{disk_state}->synch();
        $self->{paused} = 0;
        $guard->update_file();
        return;
    }
    sub _is_paused { return $_[0]->{paused} || 0; }

    sub is_paused {
        my ($self) = @_;
        $self->{disk_state}->synch();
        return $self->_is_paused();
    }

    # --------------------------------------
    # Class methods

    sub register_task_processor {
        my ( $class, $command, $processor ) = @_;

        unless ( defined $command and length $command ) {
            cPanel::StateFile->_throw("Missing command in register_task_processor.\n");
        }
        unless ( defined $processor ) {
            cPanel::StateFile->_throw("Missing task processor in register_task_processor.\n");
        }
        if ( exists $valid_processors{$command} ) {
            cPanel::StateFile->_throw("Command '$command' already has a TaskQueue::Processor registered.\n");
        }
        if ( 'CODE' eq ref $processor ) {
            $valid_processors{$command} = cPanel::TaskQueue::Processor::CodeRef->new( { code => $processor } );
            return 1;
        }
        elsif ( eval { $processor->isa('cPanel::TaskQueue::Processor') } ) {
            $valid_processors{$command} = $processor;
            return 1;
        }

        cPanel::StateFile->_throw("Unrecognized task processor object.\n");
    }

    sub unregister_task_processor {
        my ( $class, $command ) = @_;

        unless ( defined $command and length $command ) {
            cPanel::StateFile->_throw("Missing command in unregister_task_processor.\n");
        }
        unless ( exists $valid_processors{$command} ) {
            cPanel::StateFile->_throw("Command '$command' not registered, ignoring.\n");
            return;
        }

        delete $valid_processors{$command};
        return 1;
    }

    # Initialize parameters.
    sub new {
        my ( $class, $args_ref ) = @_;
        cPanel::StateFile->_throw("Args parameter must be a hash reference\n") unless 'HASH' eq ref $args_ref;

        # Deprecate the cache_dir argument, replace with state_dir
        $args_ref->{state_dir} ||= $args_ref->{cache_dir} if exists $args_ref->{cache_dir};
        cPanel::StateFile->_throw("No state directory supplied.\n") unless exists $args_ref->{state_dir};
        cPanel::StateFile->_throw("No queue name supplied.\n")      unless exists $args_ref->{name};

        my $serializer;
        if ( defined $args_ref->{serial} ) {
            _load_serializer_module( $args_ref->{serial} );
            $serializer = $args_ref->{serial};
        }
        $serializer ||= _get_serializer();

        # TODO: Do I want to sanity check the arguments?
        my $self = bless {
            queue_name            => $args_ref->{name},
            default_task_timeout  => 60,
            max_task_timeout      => 300,
            max_in_process        => 2,
            default_child_timeout => 3600,
            disk_state_file       => $serializer->filename("$args_ref->{state_dir}/$args_ref->{name}_queue"),
            next_id               => 1,
            queue_waiting         => [],
            processing_list       => [],
            deferral_queue        => [],
            disk_state            => undef,
            defer_obj             => undef,
            paused                => 0,
            serializer            => $serializer,
        }, $class;

        # Make a disk file to track the object.
        my $state_args = {
            state_file => $self->{disk_state_file}, data_obj => $self,
            exists $args_ref->{state_timeout} ? ( timeout => $args_ref->{state_timeout} ) : (),
            exists $args_ref->{logger}        ? ( logger  => $args_ref->{logger} )        : (),
        };
        eval {
            $self->{disk_state} = cPanel::StateFile->new($state_args);
            1;
        } or do {
            my $ex = $@ || 'Unrecognized exception.';

            # If not a loading error, rethrow.
            if ( $ex !~ /Not a recognized|Invalid version|ParseError/ ) {
                cPanel::StateFile->_throw($ex);
            }
            cPanel::StateFile->_warn($ex);
            cPanel::StateFile->_warn("Moving bad state file and retry.\n");
            cPanel::StateFile->_notify(
                'Unable to load TaskQueue metadata',
                "Loading of [$self->{disk_state_file}] failed: $ex\n" . "Moving bad file to [$self->{disk_state_file}.broken] and retrying.\n"
            );
            unlink "$self->{disk_state_file}.broken";
            rename $self->{disk_state_file}, "$self->{disk_state_file}.broken";

            $self->{disk_state} = cPanel::StateFile->new($state_args);
        };

        # Use incoming parameters to override what's in the file.
        if ( grep { exists $args_ref->{$_} } qw/default_timeout max_timeout max_running default_child_timeout/ ) {
            my $guard = $self->{disk_state}->synch();
            my $altered;
            for my $settings (
                [qw(default_task_timeout  default_timeout)],
                [qw(max_task_timeout      max_timeout)],
                [qw(max_in_process        max_running)],
                [qw(default_child_timeout default_child_timeout)],
            ) {
                my ( $internal_name, $arg_name ) = @$settings;
                if ( exists $args_ref->{$arg_name} && $self->{$internal_name} ne $args_ref->{$arg_name} ) {
                    $self->{$internal_name} = $args_ref->{$arg_name};
                    ++$altered;
                }
            }
            $guard->update_file() if $altered;
        }

        return $self;
    }

    sub throw {
        my $self = shift;
        return $self->{disk_state} ? $self->{disk_state}->throw(@_) : cPanel::StateFile->_throw(@_);
    }

    sub warn {
        my $self = shift;
        return $self->{disk_state} ? $self->{disk_state}->warn(@_) : warn @_;
    }

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

        $self->throw('Not a recognized TaskQueue state file.')   unless defined $magic   and $magic eq $FILETYPE;
        $self->throw('Invalid version of TaskQueue state file.') unless defined $version and $version eq $CACHE_VERSION;

        # Next id should continue increasing.
        #   (We might want to deal with wrap-around at some point.)
        $self->{next_id} = $meta->{nextid} if $meta->{nextid} > $self->{next_id};

        # TODO: Add more sanity checks here.
        $self->{default_task_timeout}  = $meta->{def_task_to}  if $meta->{def_task_to} > 0;
        $self->{max_task_timeout}      = $meta->{max_task_to}  if $meta->{max_task_to} > 0;
        $self->{max_in_process}        = $meta->{max_running}  if $meta->{max_running} > 0;
        $self->{default_child_timeout} = $meta->{def_child_to} if $meta->{def_child_to} > 0;
        $self->{_bump_size}            = $meta->{_bump_size} // '';

        $self->{paused}    = ( exists $meta->{paused} && $meta->{paused} ) ? 1                  : 0;
        $self->{defer_obj} = exists $meta->{defer_obj}                     ? $meta->{defer_obj} : undef;

        # Clean queues that have been read from disk.
        $self->{queue_waiting}   = _clean_task_list( $meta->{waiting_queue} );
        $self->{processing_list} = _clean_task_list( $meta->{processing_queue} );
        $self->{deferral_queue}  = _clean_task_list( $meta->{deferral_queue} );

        return 1;
    }

    sub _clean_task_list {
        my ($task_list) = @_;
        return [] unless defined $task_list;
        return [
            grep {
                defined $_
                  and eval { $_->isa('cPanel::TaskQueue::Task') }
            } map {
                eval { cPanel::TaskQueue::Task->reconstitute($_) }
            } @{$task_list}
        ];
    }

    sub save_to_cache {
        my ( $self, $fh ) = @_;

        my $meta = {
            nextid           => $self->{next_id},
            def_task_to      => $self->{default_task_timeout},
            max_task_to      => $self->{max_task_timeout},
            max_running      => $self->{max_in_process},
            def_child_to     => $self->{default_child_timeout},
            waiting_queue    => $self->{queue_waiting},
            processing_queue => $self->{processing_list},
            deferral_queue   => $self->{deferral_queue},
            paused           => ( $self->{paused} ? 1 : 0 ),
            defer_obj        => $self->{defer_obj},
            _bump_size       => $self->{_bump_size} // '',
        };

        $meta->{_bump_size} .= "x";
        $meta->{_bump_size} = 'x' if length $meta->{_bump_size} > 1_024;

        return $self->_serializer()->save( $fh, $FILETYPE, $CACHE_VERSION, $meta );
    }

    sub queue_tasks {
        my ( $self, @commands ) = @_;

        # Let's throw right away before
        # we have a lock in case something is wrong
        foreach my $command (@commands) {
            $self->throw('Cannot queue an empty command.') unless defined $command;
            if ( !eval { $command->isa('cPanel::TaskQueue::Task') } ) {

                # must have non-space characters to be a command.
                $self->throw('Cannot queue an empty command.') unless $command =~ /\S/;
            }
        }

        # Lock the queue here, because we begin looking what's currently in the queue
        #  and don't want it to change under us.
        my $guard = $self->{disk_state}->synch();

        my ( @uuids, @invalid_tasks );
        foreach my $command (@commands) {
            my $task;

            if ( eval { $command->isa('cPanel::TaskQueue::Task') } ) {
                if ( 0 == $command->retries_remaining() ) {
                    $self->info('Task with 0 retries not queued.');
                    next;
                }
                $task = $command->mutate( { timeout => $self->{default_child_timeout} } );
            }
            else {
                $task = cPanel::TaskQueue::Task->new(
                    {
                        cmd     => $command,
                        nsid    => $taskqueue_uuid,
                        id      => $self->{next_id}++,
                        timeout => $self->{default_child_timeout},
                    }
                );
            }

            my $proc = _get_task_processor($task);
            if ( !$proc || !$proc->is_valid_args($task) ) {
                push @invalid_tasks, $task;
                next;
            }

            if ( $self->_add_task_to_waiting_queue($task) ) {
                push @uuids, $task->uuid();
            }
            else {
                push @uuids, undef;    # failed task
            }
        }

        # Changes to the queue are complete, save to disk.
        $guard->update_file();

        foreach my $task (@invalid_tasks) {
            $self->_get_task_processor_for_task_or_throw($task);
        }

        return @uuids;
    }

    sub queue_task {
        my ( $self, $command ) = @_;

        my @uuids = $self->queue_tasks($command);

        return @uuids ? $uuids[0] : ();
    }

    sub unqueue_task {
        my ( $self, $uuid ) = @_;

        unless ( _is_valid_uuid($uuid) ) {
            $self->throw('No Task uuid argument passed to unqueue_cmd.');
        }

        # Lock the queue before we begin accessing it.
        my $guard     = $self->{disk_state}->synch();
        my $old_count = @{ $self->{queue_waiting} };

        $self->{queue_waiting} = [ grep { $_->uuid() ne $uuid } @{ $self->{queue_waiting} } ];

        # All changes complete, save to disk.
        $guard->update_file();
        return $old_count > @{ $self->{queue_waiting} };
    }

    sub _is_task_in_list {
        my ( $self, $uuid, $list, $subname ) = @_;

        unless ( _is_valid_uuid($uuid) ) {
            $self->throw("No Task uuid argument passed to $subname.");
        }

        # Update from disk, but don't worry about lock. Information only.
        $self->{disk_state}->synch();
        return defined _first { $_->uuid() eq $uuid } @{ $self->{$list} };
    }

    sub is_task_queued     { return $_[0]->_is_task_in_list( $_[1], 'queue_waiting',   'is_task_queued' ); }
    sub is_task_processing { return $_[0]->_is_task_in_list( $_[1], 'processing_list', 'is_task_processing' ); }
    sub is_task_deferred   { return $_[0]->_is_task_in_list( $_[1], 'deferral_queue',  'is_task_deferred' ); }

    sub _list_of_all_tasks {
        my ($self) = @_;
        return @{ $self->{queue_waiting} }, @{ $self->{deferral_queue} }, @{ $self->{processing_list} };
    }

    sub find_task {
        my ( $self, $uuid ) = @_;

        # Update from disk, but don't worry about lock. Information only.
        $self->{disk_state}->synch();
        my $task = _first { $_->uuid() eq $uuid } $self->_list_of_all_tasks();

        return unless defined $task;
        return $task->clone();
    }

    sub find_command {
        my ( $self, $command ) = @_;

        # Update from disk, but don't worry about lock. Information only.
        $self->{disk_state}->synch();
        my $task = _first { $_->command() eq $command } $self->_list_of_all_tasks();

        return unless defined $task;
        return $task->clone();
    }

    sub find_commands {
        my ( $self, $command ) = @_;

        # Update from disk, but don't worry about lock. Information only.
        $self->{disk_state}->synch();
        my @tasks = grep { $_->command() eq $command } $self->_list_of_all_tasks();

        return unless @tasks;
        return map { $_->clone() } @tasks;
    }

    sub _how_many {
        my ( $self, $listname ) = @_;

        # Update from disk, but don't worry about lock. Information only.
        $self->{disk_state}->synch();
        return scalar @{ $self->{$listname} };
    }

    sub how_many_queued     { return $_[0]->_how_many('queue_waiting'); }
    sub how_many_deferred   { return $_[0]->_how_many('deferral_queue'); }
    sub how_many_in_process { return $_[0]->_how_many('processing_list'); }

    sub has_work_to_do {
        my ($self) = @_;

        # Update from disk, but don't worry about lock. Possibly information only.
        $self->{disk_state}->synch();
        $self->_clean_completed_tasks();

        # If we are paused, there is no work to do.
        return if $self->_is_paused;

        return scalar( @{ $self->{processing_list} } ) < $self->{max_in_process} && 0 != @{ $self->{queue_waiting} };
    }

    sub peek_next_task {
        my ($self) = @_;

        # Update from disk, but don't worry about lock. Information only.
        $self->{disk_state}->synch();
        return unless @{ $self->{queue_waiting} };

        return $self->{queue_waiting}->[0]->clone();
    }

    sub process_next_task {
        my ($self) = @_;

        # Lock the queue before doing any manipulations.
        my $guard = $self->{disk_state}->synch();

        $self->_handle_already_running_tasks($guard);

        if ( _first { !defined $_ } @{ $self->{queue_waiting} } ) {

            # Somehow some undefined tasks got into the queue, log and
            # delete them.
            $self->warn('Undefined tasks found in the queue, removing...');
            $self->{queue_waiting} = [ grep { defined $_ } @{ $self->{queue_waiting} } ];

            # Since we've changed the wait queue, we need to update disk file,
            # otherwise changes could be lost if we return early, below.
            $guard->update_file();
        }

        # If we are paused, there is no work to do.
        return 1 if $self->_is_paused;

        my ( $task, $processor );
        while ( !$task ) {

            # We can now schedule new tasks
            return 1 unless @{ $self->{queue_waiting} };
            $task = shift @{ $self->{queue_waiting} };

            # can fail if the processor for this command was removed.
            $processor = _get_task_processor($task);
            unless ($processor) {

                # TODO: log missing processor.
                $self->warn( q{No processor found for '} . $task->full_command() . q{'.} );
                $guard->update_file();
                return 1;
            }

            # Check for deferrals.
            if ( $processor->is_task_deferred( $task, $self->{defer_obj} ) ) {
                unshift @{ $self->{deferral_queue} }, $task;
                $task = undef;
            }
        }

        $task->begin();
        push @{ $self->{processing_list} }, $task;
        $self->_add_task_to_deferral_object( $task, $processor );

        my $pid;
        my $ex;

        if ( $processor->isa('cPanel::TaskQueue::ChildProcessor') ) {

            #
            # Will fork() so there is no concern about the parent
            # keeping the lock since it should return right away and
            # will not be blocking other processes from getting a lock
            # as soon as we return from this sub.
            #
            # This avoids going though a whole cycle of update_file, unlock,
            # relock, and re-read from disk
            #
            # No need to set an alarm as we are going to fork() and
            # ChildProcessor already handles timeouts
            #
            eval { $pid = $processor->process_task( $task->clone(), $self->{disk_state}->get_logger(), $guard ) } or do {
                $ex = $@;
            };
        }
        else {
            # We are going to have to unlock and relock
            # Finished making changes, save to disk.
            $guard->update_file();

            # I don't want to stay locked while processing.
            $guard->call_unlocked(
                sub {
                    my $orig_alarm;
                    eval {
                        local $SIG{'ALRM'} = sub { die "time out reached\n"; };
                        $orig_alarm = alarm( $self->_timeout($processor) );
                        $pid        = $processor->process_task( $task->clone(), $self->{disk_state}->get_logger() );
                        alarm $orig_alarm;
                        1;
                    } or do {
                        $ex = $@;    # save exception for later
                        alarm $orig_alarm;
                    };
                }
            );
        }

        # Deal with a child process or remove from processing.
        if ($pid) {
            $task->set_pid($pid);
        }
        else {
            my $uuid = $task->uuid();

            # remove finished item from the list.
            $self->{processing_list} = [ grep { $_->uuid() ne $uuid } @{ $self->{processing_list} } ];
            $self->_remove_task_from_deferral_object($task);
        }

        # Don't lose any exceptions.
        if ($ex) {
            if ( $ex eq "time out reached\n" ) {

                # TODO: log timeout condition.
                $self->warn( q{Task '} . $task->full_command() . q{' timed out during processing.} );
            }
            else {
                $self->throw($ex);
            }
        }

        # Finished making changes, save to disk.
        $guard->update_file();
        return $pid == 0;
    }

    sub finish_all_processing {
        my ($self) = @_;

        # Lock the queue for manipulation and to reduce new task items.
        my $guard = $self->{disk_state}->synch();
        while ( @{ $self->{processing_list} } ) {

            # we still need to remove some
            my $pid;

            # TODO: Might want to deal with timeouts or something to keep this
            #   from waiting forever.
            $guard->call_unlocked( sub { $pid = waitpid( -1, 0 ) } );

            next unless $pid;
            $self->{processing_list} = [
                grep { 0 == waitpid( $_->pid(), $WNOHANG ) }
                grep { $_->pid() && $_->pid() != $pid } @{ $self->{processing_list} }
            ];
            $self->_process_deferrals();
            $guard->update_file();
        }
        return;
    }

    sub snapshot_task_lists {
        my ($self) = @_;

        # Update from disk, but don't worry about lock. Information only.
        $self->{disk_state}->synch();

        return {
            waiting    => [ map { $_->clone() } @{ $self->{queue_waiting} } ],
            processing => [ map { $_->clone() } @{ $self->{processing_list} } ],
            deferred   => [ map { $_->clone() } @{ $self->{deferral_queue} } ],
        };
    }

    sub delete_all_unprocessed_tasks {
        my ($self) = @_;
        my $guard = $self->{disk_state}->synch();

        # Empty the deferral and waiting queues. Can't change processing list,
        # those tasks are actually in progress.
        my $count = @{ $self->{deferral_queue} };
        $self->{deferral_queue} = [];
        $count += @{ $self->{queue_waiting} };
        $self->{queue_waiting} = [];
        $guard->update_file();

        return $count;
    }

    # ---------------------------------------------------------------
    #  Private Methods.

    sub _get_task_processor {
        my ($task) = @_;
        return $valid_processors{ $task->command() };
    }

    # Test whether the supplied task descriptor duplicates any in the queue.
    sub _is_duplicate_command {
        my ( $self, $task ) = @_;
        my $proc = _get_task_processor($task);

        return defined _first { $proc->is_dupe( $task, $_ ) } reverse @{ $self->{queue_waiting} };
    }

    sub _process_overrides {
        my ( $self, $task ) = @_;
        my $proc = _get_task_processor($task);

        $self->{queue_waiting} = [ grep { !$proc->overrides( $task, $_ ) } @{ $self->{queue_waiting} } ];

        return;
    }

    sub _get_task_processor_for_task_or_throw {
        my ( $self, $task ) = @_;

        # Validate the incoming task.
        # It must be a command we recognize, have valid parameters, and not be a duplicate.
        my $proc = _get_task_processor($task);
        unless ($proc) {
            $self->throw( q{No known processor for '} . $task->command() . q{'.} );
        }
        unless ( $proc->is_valid_args($task) ) {
            $self->throw( q{Requested command [} . $task->full_command() . q{] has invalid arguments.} );
        }
        return $proc;
    }

    # Perform all of the steps needed to put a task in the queue.
    # Only queues legal commands, that are not duplicates.
    # If successful, returns the new queue id.
    sub _queue_the_task {
        my ( $self, $task ) = @_;

        $self->_get_task_processor_for_task_or_throw($task);

        # Lock the queue here, because we begin looking what's currently in the queue
        #  and don't want it to change under us.
        my $guard = $self->{disk_state}->synch();

        $self->_add_task_to_waiting_queue($task) or return;

        # Changes to the queue are complete, save to disk.
        $guard->update_file();

        return $task->uuid();
    }

    sub _add_task_to_waiting_queue {
        my ( $self, $task ) = @_;

        # Check overrides first and then duplicate. This seems backward, but
        # actually is not. See the tests labelled 'override, not dupe' in
        # t/07.task_queue_dupes_and_overrides.t for the case that makes sense.
        #
        # By making the task override its duplicates as well, we can get the
        # behavior you expect when you think this is wrong. If we swap the order of
        # the tests there's no way to force the right behavior.
        $self->_process_overrides($task);
        return if $self->_is_duplicate_command($task);

        push @{ $self->{queue_waiting} }, $task;

        return 1;
    }

    # Use either the timeout in the processor or the default timeout,
    #  unless that is greater than the max, the use the max.
    sub _timeout {
        my ( $self, $processor ) = @_;

        my $timeout = $processor->get_timeout() || $self->{default_task_timeout};

        return $timeout > $self->{max_task_timeout} ? $self->{max_task_timeout} : $timeout;
    }

    # Clean the processing list of any child tasks that completed since the
    # last time we looked. The $guard object is an optional parameter. If
    # a guard does not exist, we will create one if necessary for any locking.
    sub _clean_completed_tasks {
        my ( $self, $guard ) = @_;

        my $num_processing = @{ $self->{processing_list} };
        my $num_deferred   = @{ $self->{deferral_queue} };

        # If the processing_list is empty, and we have no deferred tasks we
        # are finished processing
        return if !$num_processing && !$num_deferred;

        # Remove tasks that have already completed from the in-memory list.
        $self->_remove_completed_tasks_from_list();

        # No changes, we can leave
        return
          if @{ $self->{processing_list} } == $num_processing
          && @{ $self->{deferral_queue} } == $num_deferred;

        # Was not locked, so we need to lock and remove completed tasks again.
        if ( !$guard ) {
            $guard = $self->{disk_state}->synch();
            $self->_remove_completed_tasks_from_list();
        }
        $guard->update_file();
        return;
    }

    # Remove child tasks that have completed executing from the processing
    # list in memory.
    sub _remove_completed_tasks_from_list {
        my ($self) = @_;
        $self->{processing_list} = [ grep { $_->pid() && 0 == waitpid( $_->pid(), $WNOHANG ) } @{ $self->{processing_list} } ];
        $self->_process_deferrals();
        return;
    }

    sub _add_task_to_deferral_object {
        my ( $self, $task, $processor ) = @_;
        return unless $task;

        $processor ||= _get_task_processor($task);
        $self->{defer_obj}->{$_} = 1 foreach $processor->deferral_tags($task);
        return;
    }

    sub _remove_task_from_deferral_object {
        my ( $self, $task, $processor ) = @_;
        return unless $task;

        $processor ||= _get_task_processor($task);
        delete $self->{defer_obj}->{$_} foreach $processor->deferral_tags($task);
        return;
    }

    # Clean up the object that tracks deferral information.
    # Check all tasks in the deferral queue and add them back to the waiting
    # list if they are no longer deferred.
    sub _process_deferrals {
        my ($self) = @_;

        # clean up the current deferral object for the tasks being processed.
        $self->{defer_obj} = {};
        foreach my $task ( @{ $self->{processing_list} } ) {
            $self->{defer_obj}->{$_} = 1 foreach _get_task_processor($task)->deferral_tags($task);
        }

        # Separate deferred tasks from non-deferred tasks.
        my @defer;
        foreach my $task ( @{ $self->{deferral_queue} } ) {
            if ( _get_task_processor($task)->is_task_deferred( $task, $self->{defer_obj} ) ) {
                push @defer, $task;
            }
            else {

                $self->_process_overrides($task);
                next if $self->_is_duplicate_command($task);

                # move 'no longer deferred' tasks in reverse order to processing list
                unshift @{ $self->{queue_waiting} }, $task;
            }
        }

        # update queues
        $self->{deferral_queue} = \@defer;
        return;
    }

    # Handle the case of too many tasks being processed
    # Are there too many in processing?
    #    check to see if any processes are complete, and remove them.
    # Are there still too many in processing?
    #    waitpid - blocks.
    #    remove process that completed
    #    remove any other completed processes
    sub _handle_already_running_tasks {
        my ( $self, $guard ) = @_;

        $self->_clean_completed_tasks($guard);

        while ( $self->{max_in_process} <= scalar @{ $self->{processing_list} } ) {

            # we still need to remove some
            my $pid;

            # TODO: Might want to deal with timeouts or something to keep this
            #   from waiting forever.
            $guard->call_unlocked( sub { $pid = waitpid( -1, 0 ) } );

            next if $pid < 1;
            $self->{processing_list} = [ grep { $_->pid() != $pid } @{ $self->{processing_list} } ];
            $self->_process_deferrals();
            $guard->update_file();
        }
        $self->_clean_completed_tasks($guard);
        return;
    }

    sub _is_valid_uuid {
        return cPanel::TaskQueue::Task::is_valid_taskid(shift);
    }
}

# One guaranteed processor, the no-operation case.
__PACKAGE__->register_task_processor( 'noop', sub { } );

1;

__END__


=head1  NAME

cPanel::TaskQueue - FIFO queue of tasks to perform

=head1 SYNOPSIS

    use cPanel::TaskQueue ();

    my $queue = cPanel::TaskQueue->new( { name => 'tasks', state_dir => "/home/$user/.cpanel/queue" } );

    $queue->queue_task( "init_quota" );
    $queue->queue_task( "edit_quota fred 0" );
    $queue->queue_tasks( "init_quota", "edit_quota fred 0" );

    # Processing loop
    while (1) {
        # if work, process, else sleep
        if ( $queue->has_work_to_do() ) {
            eval { $queue->process_next_task() };
            if ( $@ ) {
                Carp::carp( $@ );
            }
        }
        else {
            # wait for work.
            sleep 300;
        }
    }

=head1  DESCRIPTION

This module provides an abstraction for a FIFO queue of tasks that may be
executed asynchronously. Each command determines whether it runs in the
current process or forks a child to do the work in the background.

The TaskQueue has support for limiting the number of background tasks running
at one time and for preventing duplicate tasks from being scheduled.

=head1 PUBLIC METHODS

=over 4

=item cPanel::TaskQueue->new( $hashref )

Creates a new TaskQueue object based on the parameters from the supplied hashref.

=over 4

=item I<state_dir>

This required parameter specifies a directory where the state file should be
written.  This directory is created if it does not exist.

=item I<cache_dir>

I<Deprecated> parameter that has been replaced with I<state_dir>. If no value is
supplied by I<state_dir>, I<cache_dir>'s value will be used.

=item I<name>

This required parameter specifies the name of the queue. This name is used to
construct the name of the state file used to store the queue information.

=item I<state_timeout>

This optional parameter specifies the timeout to use for flocking the state file.
The value is in seconds and defaults to the cPanel::StateFile default value.

=item I<default_timeout>

This optional parameter specifies the default amount of time (in seconds) to wait
for an in-process task to run. The default value is 60 seconds.

This timeout may be overridden for a particular command by the
C<cPanel::TaskQueue::Processor> object.

=item I<max_timeout>

This optional parameter specifies the maximum amount of time (in seconds) to wait
for an in-process task to run. The default value is 300 seconds (5 minutes).

This value prevents a given C<cPanel::TaskQueue::Processor> object from setting the timeout
too high.

=item I<max_running>

This optional parameter specifies the maximum number of child processes that the
queue will allow to be running at one time. If this number is reached, all queue
processing blocks until one or more child processes exit. The default value is 2.

=item I<default_child_timeout>

This optional parameter specifies the default amount of time (in seconds) to wait
for a child task to run. The default value is 3600 seconds (1 hour).

This timeout may be overridden for a particular command by the
C<cPanel::TaskQueue::Processor> object.

=back

If these parameters are not specified, but a C<TaskQueue> with this I<name> and
I<state_dir> has already been created, the new C<TaskQueue> will use the parameters
that were stored in the file.  This causes all instances of this C<TaskQueue>
to act the same. Providing these parameters also updates all other instances of
this C<TaskQueue> the next time they need to C<synch>.

=item $q->queue_task( $command )

Create a new task from the command and put it at the end of the queue if it meets
certain minimum criteria.

=over 4

=item Command must be legal.

The command type must have been registered with the TaskQueue module.

=item Command must not duplicate a command already in the queue.

Each command type can have its own definition of duplicate. It can depend on
one or more of the arguments or not.

=back

If the task is successfully queued, a non-empty I<uuid> is returned. This id can
be used to remove the task from the queue at a later time.

If the task was not queued, a false value is returned.

The C<queue_task> method can also be called with a C<cPanel::TaskQueue::Task>
object which will be tested and inserted as usual.

=item $q->queue_tasks( $command, $command, ... )

Create new tasks from the commands and put them at the end of the queue if they meet
certain minimum criteria.  This method will only lock the StateFile once.

=over 4

=item Commands must be legal.

The command type must have been registered with the TaskQueue module.

=item Commands must not duplicate a command already in the queue.

Each command type can have its own definition of duplicate. It can depend on
one or more of the arguments or not.

=back

This returns a list of I<uuid>s: one for each successfully queued task,
in the order in which the tasks were given.

If a task is not queued for whatever reason, the I<uuid> is undef.

The C<queue_tasks> method can also be called with C<cPanel::TaskQueue::Task>
objects which will be tested and inserted as usual.

=item $q->unqueue_task( $uuid )

Remove the task associated with the supplied I<uuid> from the queue, if it
has not been processed yet. Returns true on success.

=back

=head2 QUEUE PROCESSING

=over 4

=item $q->has_work_to_do()

Returns a true value if there are any tasks in the queue and we can process them.
This method does not block on child processes that are currently running if we
cannot launch a new task.

=item $q->process_next_task()

This method is called to process another task from the wait queue.

If there are any tasks remaining and we have not reached the limit of tasks we
can process at once, the next is removed from the queue. The task is checked to
make certain we know how to process it, if not it is discarded.  Then it is added
to the processing list and the C<cPanel::TaskQueue::Processor> object for that
command is asked to process it. If we have reached our processing limit, block
until a task can be executed.

If the command is completed by the C<cPanel::TaskQueue::Processor>, the task is
removed from the processing list. If the C<cPanel::TaskQueue::Processor> launched
a child process, the task is left in the processing list.

The method returns true if the task was completed or otherwise removed from the
system. If the task was launched as a child process, the method returns false. The
method will also return true if there is nothing to process.

=item $q->finish_all_processing()

This method does not return until all tasks currently being processed in the
background are completed. It is most useful to call as part of shutdown of the
program that processes the queue. While waiting for processing to complete,
this method does not start any new tasks out of the queue.

=item $q->delete_all_unprocessed_tasks()

This method deletes all tasks in the deferred or waiting state from the
C<cPanel::TaskQueue>. It does nothing with the Tasks that are currently being
processed.

I<Warning>: This is probably not a very good idea. However, there may be a
circumstance where we need to throw away everything that is in the queue and
this method provides that ability.

=back

=head2 QUEUE INFORMATION

=over 4

=item $q->get_default_child_timeout

Returns the default timeout value for a child process.

=item $q->get_default_timeout

Returns the default timeout value for a task.

=item $q->get_max_running

Returns the maximum number of child processes that can be running at once.

=item $q->get_max_timeout

Returns the maximum timeout value for a task.

=item $q->get_name

Returns the TaskQueue's name.

=item $q->peek_next_task()

Get a copy of the first task descriptor in the queue or C<undef> if the queue is
empty.

Because of the nature of a task queue, there is no guarantee that this task will
remain unscheduled after the method call. That is one reason that a copy is
returned.

=item $q->is_task_queued( $uuid )

Does the specified I<uuid> reference a task in the queue?

Because of the nature of a task queue, the particular I<uuid> tested may be scheduled
for processing immediately after the test. Therefore, a true answer is not as useful as
it might seem. A false answer does tell us that the item is no longer waiting.

=item $q->find_task( $uuid )

Returns a copy of the task in the queue with the supplied I<uuid>. Returns
C<undef> if no task with that I<uuid> is found. Because of the nature of the
task queue, the task that is returned may not be in the queue shortly after
return from this method. Another process may have handled it and removed it from
the queue.

However, the returned copy is a faithful representation of the task at the point
in time that it was found.

=item $q->find_command( $command )

Returns a copy of the first command with the supplied I<command> (sans
arguments).  Returns C<undef> if no task with that command name is found.
Because of the nature of the task queue, the task that is returned may not be
in the queue shortly after return from this method. Another process may have
handled it and removed it from the queue.

Remember that C<$command> is just the name of the command, not the whole
command string with arguments.

=item $q->find_commands( $command )

Returns a list of copies of commands with the supplied I<command> (sans
arguments).  Because of the nature of the task queue, the tasks that are
returned may not be in the queue shortly after return from this method. Another
process may have handled one or more tasks and removed then from the queue.

Remember that C<$command> is just the name of the command, not the whole
command string with arguments.

=item $q->how_many_queued()

Gives a count at this particular point in time of the number of items currently
in the queue. Since an item may be removed and processed any time the
C<process_next_task()> method is called, this count may not be correct immediately
after the method returns.

Most useful for the general case of telling if the queue is really full, or mostly
empty.

=item $q->is_task_processing( $uuid )

Does the specified I<uuid> reference a task currently being processed?

Because of the nature of a task queue, the particular I<uuid> tested may be scheduled
for processing or finish processing immediately after the test. I'm not sure if this
test is actually useful for anything.

=item $q->is_task_deferred( $uuid )

Does the specified I<uuid> reference a task that is currently deferred?

Because of the nature of a task queue, the particular I<uuid> tested may be scheduled
for processing or finish processing immediately after the test. I'm not sure if this
test is actually useful for anything.

=item $q->how_many_deferred()

Returns a count of the number of tasks currently that are currently in the
deferred state. Since a task can complete at any time, the exact value returned
by this method is not guaranteed for any length of time after the method
returns.

=item $q->how_many_in_process()

Returns a count of the number of items currently being processed. Since a task
can complete at any time, the exact value returned by this method is not
guaranteed for any length of time after the method returns. May be useful to get
a statistical measure of how busy the C<cPanel::TaskQueue> system is.

=item $q->snapshot_task_lists()

Returns a reference to a hash containing copies of the current queues. The value
of I<waiting> is an array reference containing copies of all of the C<Task>s
waiting to execute. The value of I<processing> is an array reference containing
copies of all of the C<Tasks> currently being processed.

Since a task can complete at any time and whatever process handles the queue can
start processing a task at any time, the output of this method may be out of
date as soon as it returns. This method is only really useful for a general idea
of the state of the queue.

=item $q->pause_processing()

Prevent any more tasks from moving from the waiting state into the processing
state. This does not stop any tasks from processing once they begin processing.
If the queue is paused, no more tasks will move from the waiting state to the
processing state.

=item $q->resume_processing()

Allow the queue to resume processing tasks.

=item $q->is_paused()

Returns true if the queue processing has been paused, false otherwise.

=back

=head2 CACHE SUPPORT

These methods should not be used directly, they exist to support the C<cPanel::StateFile>
interface that persists the queue information to disk.

=over 4

=item $q->load_from_cache( $fh )

This method loads the queue information from the disk state file. It is called
by the C<cPanel::StateFile> object owned by this object.

The user of this class should never need to call this method.

=item $q->save_to_cache( $fh )

This method saves the queue information to the disk state file. It is called by
the C<cPanel::StateFile> object owned by this object.

The user of this class should never need to call this method.

=item $q->throw( $msg )

Log the supplied message and C<die>.

=item $q->warn( $msg )

Log the supplied message as a warning.

=item $q->info( $msg )

Log the supplied message as an informational message.

=back

=head1 CLASS METHODS

The class also supports a few methods that apply to the Task Queuing system as a whole.
These methods manage the registering of task processing objects.

=over 4

=item cPanel::TaskQueue->register_task_processor( $cmdname, $processor )

Add a task processing object for the command name given as the first argument.
The second argument must either be a C<cPanel::TaskQueue::Processor>-derived object
or a code reference that will be wrapped in a C<cPanel::TaskQueue::Processor::CodeRef>
object.

=item cPanel::TaskQueue->unregister_task_processor( $cmdname )

Removes the task processing object for the command given as the only argument.

After a call to this method, that particular command can not be queued any more
and any already queued objects will be discarded when the C<cPanel::TaskQueue>
tries to process them.

=back

=head1 LOGGER OBJECT

By default, the C<TaskQueue> uses C<die> and C<warn> for all messages during
runtime. However, it supports a mechanism that allows you to insert a
logging/reporting system in place by providing an object to do the logging for
us.

To provide a different method of logging/reporting, supply an object to do the
logging as follows when C<use>ing the module.

   use cPanel::TaskQueue ( '-logger' => $logger );

The supplied object should supply (at least) 4 methods: C<throw>, C<warn>,
C<info>, and C<notify>. When needed these methods will be called with the
messages to be logged.

This only works once for a given program, so you can't reset the policy in
multiple modules and expect it to work.

In addition to setting a global logger, a new logger object can be supplied
when creating a specific C<TaskQueue> object.

See L<cPanel::TaskQueue::Cookbook> for examples.

=head1 DIAGNOSTICS

The following messages can be reported by this module:

=over 4

=item C<< Missing command in register_task_processor. >>

No command name was given when calling the C<register_task_processor> class
method to register a processing object to handle a command.

=item C<< Missing task processor in register_task_processor. >>

No command processor object was supplied when calling the C<register_task_processor>
class method to register an action to attach to a command.

=item C<< Command '%s' already has a TaskQueue::Processor registered. >>

The supplied command name already has a registered processing object. If you want
to change it, you must first remove the other processor using
C<unregister_task_processor>.

=item C<< Unrecognized task processor object. >>

The second parameter to C<register_task_processor> was not recognized as a
C<TaskQueue::Processor>-derived object or as a C<coderef>.

=item C<< Missing command in unregister_task_processor. >>

No command name string was supplied when calling this method.

=item C<< Command '%s' not registered, ignoring. >>

The supplied argument to C<unregister_task_processor> was not a registered
command name.

=item C<< No caching directory supplied. >>

The required I<state_dir> parameter was missing when constructing the C<TaskQueue>
object. The object was not created.

=item C<< No queue name supplied. >>

The required I<name> parameter was missing when constructing the C<TaskQueue>
object. The object was not created.

=item C<< Not a recognized TaskQueue state file. >>

=item C<< Invalid version of TaskQueue state file. >>

Either the state file is invalid or it is not a TaskQueue state file.

=item C<< Cannot queue an empty command. >>

The command string supplied to C<queue_task> was either C<undef> or empty.

=item C<< Task with 0 retries not queued. >>

The C<Task> supplied to C<queue_task> has a remaining retry count of 0. The task
has been discarded. This is a warning message only.

=item C<< No known processor for '%s'. >>

The specified command has no defined processor. The command has been discarded.

=item C<< Requested command [%s] has invalid arguments. >>

The supplied full command has arguments that are not valid as defined by the
command processor.

=item C<< No Task uuid argument passed to %s. >>

The specified method requires a I<uuid> to specify which task to operate
on. None was supplied.

=item C<< No processor found for '%s'. >>

Either the program inserting tasks into the queue has a different list of commands
than the program processing the queue, or a TaskQueue::Processor was unregistered
after this command was queued.

=item C<< Task '%s' timed out during processing. >>

The supplied command timed out while being executed in-process.

=item C<< Undefined tasks found in the queue, removing... >>

Somehow a task item of C<undef> has appeared in the queue. This should never
happen, so if it does, we remove them.

=back

=head1 DEPENDENCIES

YAML::Syck, POSIX

cPanel::TaskQueue::Processor, cPanel::TaskQueue::Task, cPanel::StateFile

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

In spite of the locking that's used to prevent multiple concurrent writes
or reads being combined with writes, it is sometimes possible for a state
file to become corrupt or improperly emptied if many processes are attempting
to update it at the same time. There is most likely still a race condition
that's exposed under heavy load.

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
