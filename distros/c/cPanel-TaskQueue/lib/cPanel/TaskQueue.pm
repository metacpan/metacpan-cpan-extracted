package cPanel::TaskQueue;
$cPanel::TaskQueue::VERSION = '0.800';
# cpanel - cPanel/TaskQueue.pm                    Copyright(c) 2014 cPanel, Inc.
#                                                           All rights Reserved.
# copyright@cpanel.net                                         http://cpanel.net
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the owner nor the names of its contributors may
#       be used to endorse or promote products derived from this software
#       without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL  BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
    die "Policies already set elsewhere\n" if $are_policies_set;
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
sub _first (&@) {                                      ## no critic(ProhibitSubroutinePrototypes)
    my $pred = shift;
    local $_;
    foreach (@_) {
        return $_ if $pred->();
    }
    return;
}

# Namespace string used when creating task ids.
my $taskqueue_uuid = 'TaskQueue';

{

    # Class-wide definition of the valid processors
    my %valid_processors;
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
        $self->{paused} = ( exists $meta->{paused} && $meta->{paused} ) ? 1 : 0;
        $self->{defer_obj} = exists $meta->{defer_obj} ? $meta->{defer_obj} : undef;

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
        };
        return $self->_serializer()->save( $fh, $FILETYPE, $CACHE_VERSION, $meta );
    }

    sub queue_task {
        my ( $self, $command ) = @_;

        $self->throw('Cannot queue an empty command.') unless defined $command;

        if ( eval { $command->isa('cPanel::TaskQueue::Task') } ) {
            if ( 0 == $command->retries_remaining() ) {
                $self->info('Task with 0 retries not queued.');
                return;
            }
            my $task = $command->mutate( { timeout => $self->{default_child_timeout} } );
            return $self->_queue_the_task($task);
        }

        # must have non-space characters to be a command.
        $self->throw('Cannot queue an empty command.') unless $command =~ /\S/;

        my $task = cPanel::TaskQueue::Task->new(
            {
                cmd     => $command,
                nsid    => $taskqueue_uuid,
                id      => $self->{next_id}++,
                timeout => $self->{default_child_timeout},
            }
        );
        return $self->_queue_the_task($task);
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

        # Finished making changes, save to disk.
        $guard->update_file();

        # I don't want to stay locked while processing.
        my $pid;
        my $ex;
        $guard->call_unlocked(
            sub {
                my $orig_alarm;
                eval {
                    local $SIG{'ALRM'} = sub { die "time out reached\n"; };
                    $orig_alarm = alarm( $self->_timeout($processor) );
                    $pid = $processor->process_task( $task->clone(), $self->{disk_state}->get_logger() );
                    alarm $orig_alarm;
                    1;
                } or do {
                    $ex = $@;    # save exception for later
                    alarm $orig_alarm;
                };
            }
        );

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

    # Perform all of the steps needed to put a task in the queue.
    # Only queues legal commands, that are not duplicates.
    # If successful, returns the new queue id.
    sub _queue_the_task {
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

        # Lock the queue here, because we begin looking what's currently in the queue
        #  and don't want it to change under us.
        my $guard = $self->{disk_state}->synch();

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

        # Changes to the queue are complete, save to disk.
        $guard->update_file();

        return $task->uuid();
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
        my @proc;
        foreach my $task ( @{ $self->{deferral_queue} } ) {
            if ( _get_task_processor($task)->is_task_deferred( $task, $self->{defer_obj} ) ) {
                push @defer, $task;
            }
            else {

                # move 'no longer deferred' tasks in reverse order to processing list
                unshift @proc, $task;
            }
        }

        # update queues
        $self->{queue_waiting} = [ @proc, @{ $self->{queue_waiting} } ] if @proc;
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

Copyright (c) 2014, cPanel, Inc. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

