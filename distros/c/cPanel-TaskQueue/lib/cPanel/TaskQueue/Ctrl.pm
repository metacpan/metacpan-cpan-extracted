package cPanel::TaskQueue::Ctrl;
$cPanel::TaskQueue::Ctrl::VERSION = '0.900';
use warnings;
use strict;

use cPanel::TaskQueue                ();
use cPanel::TaskQueue::Scheduler     ();
use cPanel::TaskQueue::PluginManager ();
use Text::Wrap                       ();

my %format = (
    storable => 'cPanel::TQSerializer::Storable',
    yaml     => 'cPanel::TQSerializer::YAML',
);

my @required = qw(qdir qname);
my %validate = (
    'qdir'   => sub { return -d $_[0]; },
    'qname'  => sub { return defined $_[0] && length $_[0]; },
    'sdir'   => sub { return -d $_[0]; },
    'sname'  => sub { return defined $_[0] && length $_[0]; },
    'logger' => sub { return 1; },
    'out'    => sub { return 1; },
    'serial' => sub { return !defined $_[0] || exists $format{ lc $_[0] }; },
);

my %commands = (
    queue => {
        code     => \&queue_tasks,
        synopsis => 'queue "cmd string" ...',
        help     => '    Adds the specified commands to the TaskQueue. Prints the task id on
    success or an error on failure. Multiple command strings may be supplied,
    and each will be queued in turn.',
    },
    pause => {
        code => sub { $_[2]->pause_processing(); return; },
        synopsis => 'pause',
        help     => '    Pause the processing of waiting tasks from the TaskQueue.',
    },
    resume => {
        code => sub { $_[2]->resume_processing(); return; },
        synopsis => 'resume',
        help     => '    Resume the processing of waiting tasks from the TaskQueue.',
    },
    unqueue => {
        code     => \&unqueue_tasks,
        synopsis => 'unqueue {taskid} ...',
        help     => '    Removes the tasks identified by taskids from the TaskQueue.',
    },
    schedule => {
        code     => \&schedule_tasks,
        synopsis => 'schedule [at {time}] "cmd string" ... | schedule after {seconds} "cmd string" ...',
        help     => '    Schedule the specified commands for later execution. If the "at"
    subcommand is used, the next arguemnt is expected to be a UNIX epoch time for the
    command to be queued. The "after" subcommand specified a delay in seconds after
    which the command is queued.',
    },
    unschedule => {
        code     => \&unschedule_tasks,
        synopsis => 'unschedule {taskid} ...',
        help     => '    Removes the tasks identified by taskids from the TaskQueue Scheduler.',
    },
    list => {
        code     => \&list_tasks,
        synopsis => 'list [verbose] [active|deferred|waiting|scheduled]',
        help     => '    List current outstanding tasks. With the verbose flag, list more
    information on each task. Specify the specific subset of tasks to limit output.',
    },
    find => {
        code     => \&find_task,
        synopsis => 'find task {taskid} | find command {text}',
        help     => '    Find a task in the queue by either task ID or a portion of the command
    string.',
    },
    plugins => {
        code     => \&list_plugins,
        synopsis => 'plugins [verbose]',
        help     => '    List the names of the plugins that have been loaded.',
    },
    commands => {
        code     => \&list_commands,
        synopsis => 'commands [modulename]',
        help     => '    List the commands that are currently supported by the loaded plugins.
    If a module name is supplied, only the commands from that plugin are displayed.',
    },
    status => {
        code     => \&queue_status,
        synopsis => 'status',
        help     => '    Print the status of the Task Queue and Scheduler.',
    },
    convert => {
        code     => \&convert_state_files,
        synopsis => 'convert {newformat}',
        help     => '    Convert the TaskQueue and Scheduler state files from the current format
    to the newly specified format. Valid strings for the format are "storable" or
    "yaml".'
    },
    info => {
        code     => \&display_queue_info,
        synopsis => 'info',
        help     => '    Display current information about the TaskQueue, Scheduler, and the Ctrl
    object.',
    },
    process => {
        code     => \&process_one_step,
        synopsis => 'process [verbose] [scheduled|waiting]',
        help     => '    Process the requested queue items. If called with the "waiting" argument,
    one waiting task is started if we have space in the active queue. If called with the
    "scheduled" argument, any scheduled items that have reached their activation time will be
    queued. Otherwise, both actions will be performed. Use the "verbose" flag for more output.'
    },
    flush_scheduled_tasks => {
        code     => \&flush_scheduled_tasks,
        synopsis => 'flush_scheduled_tasks',
        help     => '    Flush scheduled tasks to the waiting queue where they can be processed.
    The scheduled tasks are flushed regardless of whether the scheduled time has arrived or not.'
    },
    delete_unprocessed_tasks => {
        code     => \&delete_unprocessed_tasks,
        synopsis => 'delete_unprocessed_tasks [scheduled|waiting]',
        help     => '    Delete tasks which are not yet being processed. If called with the
    "waiting" argument, only waiting/deferred tasks are deleted. If called with the "scheduled"
    argument, only scheduled tasks are deleted. Otherwise all non-processed tasks are deleted.'
    }
);

sub new {
    my ( $class, $args ) = @_;

    $args = {} unless defined $args;
    die "Argument to new is not a hashref.\n" unless 'HASH' eq ref $args;
    foreach my $arg (@required) {
        die "Missing required '$arg' argument.\n" unless defined $args->{$arg} and length $args->{$arg};
    }
    my $self = {};
    foreach my $arg ( keys %{$args} ) {
        next unless exists $validate{$arg};
        die "Value of '$arg' parameter ($args->{$arg}) is not valid.\n"
          unless $validate{$arg}->( $args->{$arg} );
        $self->{$arg} = $args->{$arg};
    }
    $self->{sdir} ||= $self->{qdir} if $self->{sname};
    $self->{out} ||= \*STDOUT;

    return bless $self, $class;
}

sub run {
    my ( $self, $cmd, @args ) = @_;
    die "No command supplied to run.\n" unless $cmd;
    die "Unrecognized command '$cmd' to run.\n" unless exists $commands{$cmd};

    $commands{$cmd}->{code}->( $self, $self->{out}, $self->_get_queue(), $self->_get_scheduler(), @args );
    return;
}

sub synopsis {
    my ( $self, $cmd ) = @_;

    if ( $cmd && exists $commands{$cmd} ) {
        return $commands{$cmd}->{'synopsis'}, '';
    }
    return map { $commands{$_}->{'synopsis'}, '' } sort keys %commands;
}

sub help {
    my ( $self, $cmd ) = @_;
    if ( $cmd && exists $commands{$cmd} ) {
        return @{ $commands{$cmd} }{ 'synopsis', 'help' }, '';
    }
    return map { @{ $commands{$_} }{ 'synopsis', 'help' }, '' } sort keys %commands;
}

sub _get_queue {
    my ($self) = @_;
    return cPanel::TaskQueue->new(
        {
            name      => $self->{qname},
            state_dir => $self->{qdir},
            ( exists $self->{logger} ? ( logger => $self->{logger} ) : () ),
            ( defined $self->{serial} ? ( serial => $format{ lc $self->{serial} } ) : () ),
        }
    );
}

sub _get_scheduler {
    my ($self) = @_;

    # Explicitly returning undef because should only be called in scalar context.
    # I want it to either return a scheduler or undef, returning an empty list
    # never makes sense in this situation.
    return undef unless exists $self->{sdir};    ## no critic (ProhibitExplicitReturnUndef)
    return cPanel::TaskQueue::Scheduler->new(
        {
            name      => $self->{sname},
            state_dir => $self->{sdir},
            ( exists $self->{logger} ? ( logger => $self->{logger} ) : () ),
            ( defined $self->{serial} ? ( serial => $format{ lc $self->{serial} } ) : () ),
        }
    );
}

sub queue_tasks {
    my ( $ctrl, $fh, $queue, $sched, @cmds ) = @_;
    die "No command to queue.\n" unless @cmds;

    foreach my $cmdstring (@cmds) {
        eval {
            print $fh "Id: ", $queue->queue_task($cmdstring), "\n";
            1;
        } or do {
            print $fh "ERROR: $@\n";
        };
    }
    return;
}

sub unqueue_tasks {
    my ( $ctrl, $fh, $queue, $sched, @tids ) = @_;
    die "No task ids to unqueue.\n" unless @tids;

    my $count = 0;
    foreach my $id (@tids) {
        eval {
            ++$count if $queue->unqueue_task($id);
            1;
        } or do {
            print $fh "ERROR: $@\n";
        };
    }
    print $fh "$count tasks unqueued\n";
    return;
}

sub schedule_tasks {
    my ( $ctrl, $fh, $queue, $sched, $subcmd, @cmds ) = @_;
    die "No command to schedule.\n" unless defined $subcmd;

    my $args = {};
    if ( $subcmd eq 'at' ) {
        $args->{'at_time'} = shift @cmds;
    }
    elsif ( $subcmd eq 'after' ) {
        $args->{'delay_seconds'} = shift @cmds;
    }
    else {
        unshift @cmds, $subcmd;
    }

    die "No command to schedule.\n" unless @cmds;
    foreach my $cmdstring (@cmds) {
        eval {
            print $fh "Id: ", $sched->schedule_task( $cmdstring, $args ), "\n";
            1;
        } or do { print $fh "ERROR: $@\n"; };
    }
    return;
}

sub unschedule_tasks {
    my ( $ctrl, $fh, $queue, $sched, @tids ) = @_;
    die "No task ids to unschedule.\n" unless @tids;

    my $count = 0;
    foreach my $id (@tids) {
        eval {
            ++$count if $sched->unschedule_task($id);
            1;
        } or do {
            print $fh "ERROR: $@\n";
        };
    }
    print $fh "$count tasks unscheduled\n";
    return;
}

sub _any_is {
    my $match = shift;
    return unless defined $match;
    foreach (@_) {
        return 1 if $match eq $_;
    }
    return;
}

sub find_task {
    my ( $ctrl, $fh, $queue, $sched, $subcmd, $match ) = @_;

    if ( !defined $match ) {
        print $fh "No matching criterion.\n";
        return;
    }

    my @t;
    if ( $subcmd eq 'task' ) {
        @t = $queue->find_task($match);
    }
    elsif ( $subcmd eq 'command' ) {
        @t = $queue->find_commands($match);
    }
    else {
        print $fh "'$subcmd' is not a valid find type.\n";
        return;
    }
    if (@t) {
        foreach (@t) {
            _verbosely_print_task( $fh, $_ );
            print $fh "\n";
        }
    }
    else {
        print $fh "No matching task found.\n";
    }
    return;
}

sub list_tasks {
    my ( $ctrl, $fh, $queue, $sched, @subcmds ) = @_;
    my $print = \&_print_task;
    if ( _any_is( 'verbose', @subcmds ) ) {
        $print = \&_verbosely_print_task;
        @subcmds = grep { $_ ne 'verbose' } @subcmds;
    }

    @subcmds = qw/active deferred waiting scheduled/ unless @subcmds;
    my $lists = $queue->snapshot_task_lists;

    if ( _any_is( 'active', @subcmds ) ) {
        print $fh "Active Tasks\n-------------\n";
        if ( @{ $lists->{'processing'} } ) {
            foreach my $t ( @{ $lists->{'processing'} } ) {
                $print->( $fh, $t );
            }
        }
    }

    if ( _any_is( 'deferred', @subcmds ) ) {
        print $fh "Deferred Tasks\n-------------\n";
        if ( @{ $lists->{'deferred'} } ) {
            foreach my $t ( @{ $lists->{'deferred'} } ) {
                $print->( $fh, $t );
                print $fh "\n";
            }
        }
    }

    if ( _any_is( 'waiting', @subcmds ) ) {
        print $fh "Waiting Tasks\n-------------\n";
        if ( @{ $lists->{'waiting'} } ) {
            foreach my $t ( @{ $lists->{'waiting'} } ) {
                $print->( $fh, $t );
                print $fh "\n";
            }
        }
    }

    return unless $sched;
    if ( _any_is( 'scheduled', @subcmds ) ) {
        my $sched_tasks = $sched->snapshot_task_schedule();
        print $fh "Scheduled Tasks\n---------------\n";
        if ( @{$sched_tasks} ) {
            foreach my $st ( @{$sched_tasks} ) {
                $print->( $fh, $st->{task} );
                print $fh "\tScheduled for: ", scalar( localtime $st->{time} ), "\n";
                print $fh "\n";
            }
        }
    }
    return;
}

sub list_plugins {
    my ( $ctrl, $fh, $queue, $sched, $verbosity ) = @_;

    if ( defined $verbosity && $verbosity eq 'verbose' ) {
        my $plugins = cPanel::TaskQueue::PluginManager::get_plugins_hash();
        foreach my $plug ( sort keys %{$plugins} ) {
            print $fh "* $plug\n\t", join( "\n\t", map { "- $_" } sort @{ $plugins->{$plug} } ), "\n\n";
        }
    }
    else {
        print $fh join( "\n", map { "* $_" } cPanel::TaskQueue::PluginManager::list_loaded_plugins() ), "\n\n";
    }
    return;
}

sub list_commands {
    my ( $ctrl, $fh, $queue, $sched, $module ) = @_;

    my $plugins = cPanel::TaskQueue::PluginManager::get_plugins_hash();
    if ( !defined $module ) {
        my @commands = sort map { @{$_} } values %{$plugins};
        print $fh join( "\n", ( map { "* $_" } @commands ) ), "\n\n";
    }
    elsif ( exists $plugins->{$module} ) {
        my @commands = sort @{ $plugins->{$module} };
        print $fh join( "\n", ( map { "* $_" } @commands ) ), "\n\n";
    }
    else {
        print $fh "No module named $module was loaded.\n";
    }
    return;
}

sub queue_status {
    my ( $ctrl, $fh, $queue, $sched ) = @_;

    print $fh "Queue:\n";
    print $fh "\tQueue Name:\t",    $queue->get_name,                  "\n";
    print $fh "\tDef. Timeout:\t",  $queue->get_default_timeout,       "\n";
    print $fh "\tMax Timeout:\t",   $queue->get_max_timeout,           "\n";
    print $fh "\tMax # Running:\t", $queue->get_max_running,           "\n";
    print $fh "\tChild Timeout:\t", $queue->get_default_child_timeout, "\n";
    print $fh "\tProcessing:\t",    $queue->how_many_in_process,       "\n";
    print $fh "\tQueued:\t\t",      $queue->how_many_queued,           "\n";
    print $fh "\tDeferred:\t",      $queue->how_many_deferred,         "\n";
    print $fh "\tPaused:\t\t", ( $queue->is_paused() ? 'yes' : 'no' ), "\n";

    if ( defined $sched ) {
        print $fh "Scheduler:\n";
        print $fh "\tSchedule Name:\t", $sched->get_name,           "\n";
        print $fh "\tScheduled:\t",     $sched->how_many_scheduled, "\n";
        my $seconds = $sched->seconds_until_next_task;
        print $fh "\tTime to next:\t$seconds\n" if defined $seconds;
    }
    print $fh "\n";
    return;
}

sub convert_state_files {
    my ( $ctrl, $fh, $queue, $sched, $fmt ) = @_;

    $fmt = lc $fmt;
    unless ( exists $format{$fmt} ) {
        print $fh "'$fmt' is not a valid format.\n";
        return;
    }
    my $new_serial = $format{$fmt};
    eval "use $new_serial;";    ## no critic(ProhibitStringyEval)
    die "Unable to load serializer module '$new_serial': $@" if $@;
    _convert_a_state_file( $queue, $new_serial );
    _convert_a_state_file( $sched, $new_serial );
    print $fh "Since the format of the state files have changed, don't forget to change the serialization format in other programs.\n";
    $ctrl->{serial} = $fmt;
    return;
}

sub _convert_a_state_file {
    my ( $q, $new_serial ) = @_;

    my $curr_serial = $q->_serializer();
    if ( $new_serial ne $curr_serial ) {
        my $curr_state_file = $q->_state_file();
        my $new_state_file = $new_serial->filename( substr( $curr_state_file, 0, rindex( $curr_state_file, '.' ) ) );
        open my $ifh, '<', $curr_state_file or die "Unable to read '$curr_state_file': $!\n";
        open my $ofh, '>', $new_state_file  or die "Unable to write '$new_state_file': $!\n";
        $new_serial->save( $ofh, $curr_serial->load($ifh) );
        close $ofh;
        close $ifh;
        unlink "$curr_state_file.orig";
        rename $curr_state_file, "$curr_state_file.orig";
    }
    return;
}

sub display_queue_info {
    my ( $ctrl, $fh, $queue, $sched, @args ) = @_;
    print $fh "Current TaskQueue Information\n";
    my $description =
      $ctrl->{serial}
      ? "$ctrl->{serial} (" . $format{ lc $ctrl->{serial} } . ")"
      : 'default';
    print $fh "Serializer:     $description\n";
    print $fh "TaskQueue file: ", $queue->_state_file(), "\n";
    print $fh "Scheduler file: ", $sched->_state_file(), "\n";
    return;
}

sub process_one_step {
    my ( $ctrl, $fh, $queue, $sched, @args ) = @_;
    my $argcnt = @args;
    @args = grep { 'verbose' ne $_ } @args;
    my $verbose = $argcnt > @args;
    @args = qw/scheduled waiting/ unless grep { 'scheduled' eq $_ or 'waiting' eq $_ } @args;
    eval {
        if ( _any_is( 'scheduled', @args ) ) {
            my $cnt = $sched->process_ready_tasks($queue);
            if ($cnt) {
                print $fh "$cnt scheduled tasks moved to queue.\n" if $verbose;
            }
            else {
                print $fh "No scheduled tasks ready to queue.\n" if $verbose;
            }
        }
        if ( _any_is( 'waiting', @args ) ) {
            if ( $queue->has_work_to_do() ) {
                $queue->process_next_task();
                print "Activated a queued task.\n" if $verbose;
            }
            else {
                print "No work to do at this time.\n" if $verbose;
            }
        }
        1;
    } or do {
        print $fh "Exception detected: $@";
    };
    return;
}

sub flush_scheduled_tasks {
    my ( $ctrl, $fh, $queue, $sched, @args ) = @_;
    my @ids = $sched->flush_all_tasks();
    if (@ids) {
        print $fh scalar(@ids), " tasks flushed\n";
    }
    else {
        print $fh "No tasks flushed\n";
    }
    return;
}

sub delete_unprocessed_tasks {
    my ( $ctrl, $fh, $queue, $sched, @args ) = @_;
    @args = qw/waiting scheduled/ unless @args;
    my $count = 0;
    if ( _any_is( 'scheduled', @args ) ) {
        $count += $sched->delete_all_tasks();
    }
    if ( _any_is( 'waiting', @args ) ) {
        $count += $queue->delete_all_unprocessed_tasks();
    }
    if ($count) {
        print $fh "$count tasks deleted\n";
    }
    else {
        print $fh "No tasks to delete\n";
    }
    return;
}

sub _print_task {
    my ( $fh, $task ) = @_;
    print $fh '[', $task->uuid, ']: ', $task->full_command, "\n";
    print $fh "\tQueued:  ", scalar( localtime $task->timestamp ), "\n";
    print $fh "\tStarted: ", scalar( localtime $task->started ), "\n" if defined $task->started;
    return;
}

sub _verbosely_print_task {
    my ( $fh, $task ) = @_;
    print $fh '[', $task->uuid, ']: ', $task->full_command, "\n";
    print $fh "\tQueued:  ", scalar( localtime $task->timestamp ), "\n";
    print $fh "\tStarted: ", ( defined $task->started ? scalar( localtime $task->started ) : 'N/A' ), "\n";
    print $fh "\tChild Timeout: ", $task->child_timeout, " secs\n";
    print $fh "\tPID: ", ( $task->pid || 'None' ), "\n";
    print $fh "\tRemaining Retries: ", $task->retries_remaining, "\n";
    return;
}

1;

__END__

Copyright (c) 2014, cPanel, Inc. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

