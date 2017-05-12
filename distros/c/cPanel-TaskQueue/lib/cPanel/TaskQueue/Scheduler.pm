package cPanel::TaskQueue::Scheduler;
$cPanel::TaskQueue::Scheduler::VERSION = '0.800';
# cpanel - cPanel/TaskQueue/Scheduler.pm          Copyright(c) 2014 cPanel, Inc.
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
    die "Policies already set elsewhere\n" if $are_policies_set;
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
sub _first (&@) {                                      ## no critic(ProhibitSubroutinePrototypes)
    my $pred = shift;
    local $_;
    foreach (@_) {
        return $_ if $pred->();
    }
    return;
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

        $self->throw("Not a recognized TaskQueue Scheduler state file.\n")   unless defined $magic   and $magic   eq $FILETYPE;
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
        $self->throw('Args is not a hash ref.') unless defined $args and 'HASH' eq ref $args;

        my $time = time;
        $time += $args->{delay_seconds} if exists $args->{delay_seconds};
        $time = $args->{at_time} if exists $args->{at_time};

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
        $self->throw( $ex ) if $ex;

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
        $self->throw( $ex ) if $ex;

        return @ids;
    }

    sub delete_all_tasks {
        my ($self) = @_;
        my $guard = $self->{disk_state}->synch();
        my $count = @{ $self->{time_queue} };
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

        return [
            map {
                { time => $_->{time}, task => $_->{task}->clone() }
            } @{ $self->{time_queue} }
        ];
    }

    # ---------------------------------------------------------------
    #  Private Methods.
    sub _schedule_the_task {
        my ( $self, $time, $task ) = @_;

        my $guard = $self->{disk_state}->synch();
        my $item = { time => $time, task => $task };

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

Copyright (c) 2010, cPanel, Inc. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

