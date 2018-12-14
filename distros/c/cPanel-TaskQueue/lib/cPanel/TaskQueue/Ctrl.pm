package cPanel::TaskQueue::Ctrl;
$cPanel::TaskQueue::Ctrl::VERSION = '0.902';
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
        code     => sub { $_[2]->pause_processing(); return; },
        synopsis => 'pause',
        help     => '    Pause the processing of waiting tasks from the TaskQueue.',
    },
    resume => {
        code     => sub { $_[2]->resume_processing(); return; },
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


=head1 NAME

cPanel::TaskQueue::Ctrl - A text-based interface for controlling a TaskQueue

=head1 SYNOPSIS

    use cPanel::TaskQueue::Ctrl;

    my $ctrl = cPanel::TaskQueue::Ctrl->new( { qdir=> $queue_dir, qname=> $qname, sname => $qname } );
    eval {
        $ctrl->run( @ARGV );
        1;
    } or do {
        print "$@\nSupported commands:\n\n";
        print join( "\n", $ctrl->synopsis() ), "\n\n";
        exit 1;
    };


=head1 DESCRIPTION

The L<cPanel::TaskQueue> system stores its queuing information in files on
disk. Manipulating these files by hand is error-prone and can potentially
corrupt the queue making further execution of tasks impossible. This module
provides the tools needed to allow safe manipulation of a queue and associated
scheduler.

As a general rule, most users will find the C<taskqueuectl> script much more
useful than using this module directly. However, the module is provided to
allow new tools to be built more easily.

=head1 INTERFACE

=head2 cPanel::TaskQueue::Ctrl->new( $args )

Constructs a C<cPanel::TaskQueue::Ctrl> object. The supplied hashref determines
the queue to manipulate.

The following parameters are supported in the hash.

=over 4

=item qdir

This required parameter specifies the directory in which to find the queue
file.

=item qname

This required parameter is the name used when creating the queue.

=item sdir

This optional parameter specifies the directory in which to find the
scheduler file. If not supplied, it defaults to the value of I<qdir>.

=item sname

This optional parameter is the name used when creating the scheduler. If not
supplied, no scheduler is controlled.

=item logger

This optional parameter specifies a logger object used by the C<TaskQueue> and
C<TaskQueue::Scheduler> whenever they need to write output to the user.

=item out

Specify an output filehandle for printing. If not supplied, use the STDOUT
handle instead.

=item serial

Specify which serializer to use. Valid values are C<storable> and C<yaml>. If
no serializer type is specified, the default (C<storable>) will be used.

=back

=head2 $ctrl->run( $cmd, @args )

Run the specified command with the given arguments.

=head2 $ctrl->synopsis

Display a short help message describing the commands supported by this object.

=head2 $ctrl->help

Display a longer help message describing the commands supported by this object.

=head2 queue_tasks( $fh, $queue, $sched, @commands )

Take a series of command strings as C<@commands>, use C<$queue> to queue each
of commands as a task. Print the Id on success or an error message on failure.

=head2 unqueue_tasks( $ctrl, $fh, $queue, $sched, @task_ids )

Given a list of Task ID strings, attempt to unqueue those tasks. Print a count
of the number of tasks that were unqueued. This count could be less that the
requested number of tasks if some of the tasks are being processed or have
been completed in the time the function is running.

Print error messages for any unqueue attempt that fails.

=head2 list_tasks( $ctrl, $fh, $queue, $sched, @options )

Print information about the tasks. The list of options modifies which tasks
are printed and in how much detail. The supported options are:

=over 4

=item verbose

Print more information about the tasks. Without this option, only minimal
information is printed.

=item active

Print the tasks that are currently being processed.

=item waiting

Print the tasks that are waiting to be processed.

=item scheduled

Print the tasks that are scheduled to be queued at a later time.

=back

If none of C<active>, C<waiting>, and C<scheduled> are supplied, all three sets
are printed.

=head2 find_task( $ctrl, $fh, $queue, $sched, $subcmd, $match )

Find one or more tasks that match the supplied parameters. Print all of the
tasks that were found.

If the C<$subcmd> has a value of C<task>, the C<$match> value is treated as a
task id. Since task ids are unique, this approach can only print at most one
task.

If the C<$subcmd> has a value of C<command>, the C<$match> value is treated as
a command name (without the arguments). This subcommand will print zero or more
tasks.

=head2 list_plugins( $ctrl, $fh, $queue, $sched, $option )

Print the names of the plugins to the screen. If the option parameter is the
string C<'verbose'> print the commands for each plugin as well as the plugin
name.

=head2 list_commands( $ctrl, $fh, $queue, $sched )

Print the names of the commands supported by the loaded plugins.

=head2 schedule_tasks( $ctrl, $fh, $queue, $sched, [ $subcmd, $value, ] @cmds )

Schedule each of the commands in the C<@cmds> list as a separate task based at
a time determined by the C<$subcmd> and C<$value>. There are two potential
values for C<$subcmd>:

=over 4

=item at {time}

Schedule the commands at the epoch time supplied as the C<$value>.

=item after {seconds}

Schedule the commands after the C<$value> number of seconds.

=back

If neither of these values applies, the commands will be scheduled right now.

=head2 unschedule_tasks( $ctrl, $fh, $queue, $sched, @ids )

Unschedule each of the tasks specified by the list C<@id>. It's possible for
a valid task to not be able to be unscheduled, if it has moved to the waiting
queue.

=head2 queue_status( $ctrl, $fh, $queue, $sched )

Display a summary of information about the C<$queue> and C<$sched>.

=head2 convert_state_files( $ctrl, $fh, $queue, $sched, $fmt )

Convert the state files for the C<$queue> and C<$sched> to the format described
by C<$fmt> and exit the program. Modify the $ctrl object to use the new
serialization method on subsequent attempts to create the queue and scheduler.

=head2 display_queue_info( $ctrl, $fh, $queue, $sched )

Write general information about the TaskQueue and Scheduler to the supplied
filehandle. The information includes the serialization type, and the full names
of the state files for C<$queue> and C<$sched> objects.

=head2 process_one_step( $ctrl, $fh, $queue, $sched, @args )

Perform I<One step's worth> of processing on the queue, the scheduler, or both.
How much processing is performed depends on the supplied arguments. The
supported arguments are:

=over 4

=item verbose

If this argument is supplied, the subroutine writes more output to the supplied
file handle to tell the user what is happening.

=item scheduled

If this argument is supplied, any scheduled items that have reached their
activation time will be queued.

=item waiting

If this argument is supplied, one waiting task is started if we have space in
the active queue.

=back

If neither C<scheduled> or C<waiting> are supplied, the routine acts as if both
were supplied.

=head2 flush_scheduled_tasks( $ctrl, $fh, $queue, $sched )

Flushes all scheduled tasks to the waiting queue regardless of whether the scheduled
times have been reached. Prints a message reporting the number of flushed tasks to
the C<$fh> file handle.

=head2 delete_unprocessed_tasks( $ctrl, $fh, $queue, $sched, @args )

Deletes tasks which are not yet being processed. Tasks that are currently being
processed are not deleted. The tasks to be deleted are determined by the supplied
arguments. Supported arguments are:

=over 4

=item waiting

If this argument is supplied, waiting and/or deferred tasks are deleted.

=item scheduled

If this argument is supplied, scheduled tasks are deleted.

=back

If neither C<waiting> or C<scheduled> are supplied, all non-processed tasks are
deleted.

=head1 DIAGNOSTICS

=over

=item C<< Argument to new is not a hashref. >>

=item C<< Missing required '%s' argument. >>

=item C<< Value of '%s' parameter (%s) is not valid. >>

=item C<< No command suppled to run. >>

=item C<< Unrecognized command '%s' to run. >>

=item C<< No command to queue. >>

=item C<< No task ids to unqueue. >>

=back


=head1 CONFIGURATION AND ENVIRONMENT

cPanel::TaskQueue::Ctrl requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<cPanel::TaskQueue> and L<Text::Wrap>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

G. Wade Johnson  C<< wade@cpanel.net >>

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
