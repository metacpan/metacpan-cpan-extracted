package XAS::Lib::Process::Win32;

our $VERSION = '0.02';

use POE;
use Win32::Console;
use Win32::Process;
use Win32::Socketpair 'winsocketpair';

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Base',
  mixin      => 'XAS::Lib::Mixins::Process',
  utils      => ':env dotid compress',
  filesystem => 'Dir Cwd',
  mixins     => 'start_process stop_process pause_process resume_process
                 stat_process kill_process init_process _poll_child
                 _parse_command destroy',
  constants  => ':process',
  constant => {
    wbemFlagReturnImmediately => 0x10,
    wbemFlagForwardOnly => 0x20,
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub start_process {
    my $self = shift;

    my $alias = $self->alias;
    my @args  = $self->_parse_command();
    my $dir   = $self->directory->path;

    my $process;
    my $parent;
    my $child;
    my $stdin;
    my $stderr;
    my $stdout;
    my $inherit;
    my $env = $self->environment;
    my $flags = 0;

    $self->log->debug("$alias: entering start_process");
    $self->log->debug("$alias: app: $args[0], args: @args");

    # create the new environment, this is inherited by the new process

    my $oldenv = env_store();
    my $newenv = $self->merger->merge($oldenv, $env);

    env_crate($newenv);

    # dup stdin, stdout and stderr

    open($stdin,  '<&', \*STDIN);
    open($stdout, '>&', \*STDOUT);
    open($stderr, '>&', \*STDERR);

    if ($self->redirect) {

        # get a socket pair - this needs the standard stdin, stdout
        # and stderr otherwise it errors out

        unless (($parent, $child) = winsocketpair()) {

            $self->throw_msg(
                dotid($self->class) . '.start_process.socketpair',
                'unexpected',
                "unable to create a socketpair, reason: $!"
            );

        }

        # redirect stdin, stdout and stderr to the child socket
        # with stderr combined with stdout

        open(STDIN,  '<&', $child);
        open(STDOUT, '>&', $child);
        open(STDERR, '>&', $child);

        # spawn the process, this will inherit stdin, stdout and stderr

        $inherit = 1;   # tell Create() to inherit open file handles
                        # note: doesn't seem to work as documented
                        # note: it does work for console handles which
                        #       are needed to redirect stdin, stdout, stderr

        unless (Win32::Process::Create($process, $args[0], "@args", $inherit, $flags, $dir)) {

            $self->throw_msg(
                dotid($self->class) . '.start_process.creation',
                'unexpected',
                _get_error()
            );

        }

        # close the child socket

        close($child);

        # listen on the parent socket

        $self->input_handle($parent);
        $self->output_handle($parent);

        # setup POE's I/O handling

        $self->_process_output();
        $self->_process_input();

    } else {

        # no redirected stdin, stdout or stderr

        $inherit = 0;   # tell Create() to not inherit open file handles
                        # note: doesn't seem to work as documented

        # close stdin, stdout and stderr - this really stops the inheritance

        close(STDIN);
        close(STDOUT);
        close(STDERR);

        # spawn the process

        unless (Win32::Process::Create($process, $args[0], "@args", $inherit, $flags, $dir)) {

            $self->throw_msg(
                dotid($self->class) . '.start_process.creation',
                'unexpected',
                _get_error()
            );

        }

    }

    # recover the original stdin, stdout and stderr

    open(STDIN,  '<&', $stdin);
    open(STDOUT, '>&', $stdout);
    open(STDERR, '>&', $stderr);

    # recover the old environment

    env_restore($oldenv);

    # retrieve the process id and the process object

    $self->status(PROC_STARTED);

    $self->{'pid'} = $process->GetProcessID();
    $self->{'process'} = $process;

    $self->log->info_msg('process_started', $alias, $self->pid);

    # start the background child poller

    $poe_kernel->delay('poll_child', 5);

    $self->log->debug("$alias: leaving start_process");

}

sub stat_process {
    my $self = shift;

    my $stat = 0;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering stat_process");

    if (my $pid = $self->pid) {

        $stat = $self->proc_status($pid, $alias);

    }

    $self->log->debug("$alias: leaving stat_process");

    return $stat;

}

sub pause_process {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering pause_process");

    if (my $pid = $self->pid) {

        my $code = $self->stat_process();

        if (($code == 3) || ($code == 2)) {   # process is running or ready

            $self->status(PROC_PAUSED);
            $self->process->Suspend();
            $self->log->warn_msg('process_paused', $alias, $self->pid);

        }

    }

    $self->log->debug("$alias: leaving pause_process");

}

sub resume_process {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering resume_process");

    if (my $pid = $self->pid) {

        my $code = $self->stat_process();

        if ($code == 6) {   # process is suspended ready

            $self->status(PROC_RUNNING);
            $self->process->Resume();
            $self->log->warn_msg('process_started', $alias, $self->pid);

        }

    }

    $self->log->debug("$alias: leavin resume_process");

}

sub stop_process {
    my $self = shift;

    my $exitcode = 0;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering stop_process");

    if (my $pid = $self->pid) {

        $self->status(PROC_STOPPED) unless ($self->status == PROC_SHUTDOWN);
        $self->retries(0);

        Win32::Process::KillProcess($pid, $exitcode);
        $self->log->warn_msg('process_stopped', $alias, $self->pid);

    }

    $self->log->debug("$alias: leaving stop_process");

}

sub kill_process {
    my $self = shift;

    my $exitcode = 0;
    my $alias = $self->alias;

    $self->log->warn_msg('process_killed', $alias, $self->pid);

    if (my $pid = $self->pid) {

        $self->status(PROC_KILLED);
        $self->retries(0);

        Win32::Process::KillProcess($pid, $exitcode);
        $self->log->warn_msg('killed_process', $alias, $self->pid);

    }

    $self->log->debug("$alias: leaving kill_process");

}

sub destory {
    my $self = shift;

    if (my $console = $self->{'console'}) {

        $console->Flush();
        $console->Free();

    }

}

sub init_process {
    my $self = shift;

    my $alias = $self->alias;

    $self->{'process'} = undef;
    $self->{'console'} = undef;

    if ($self->pty) {

        # A Windows service must allocate a console to redirect stdin,
        # stdout and stderr, even when using sockets to communicate.
        # Doing so at Create() time dosen't seem to work correctly.

        unless (defined($self->{'console'} = Win32::Console->Alloc())) {

            $self->throw_msg(
                dotid($self->class) . '.init_process.nopty',
                'process_nopty',
                $alias, _get_error()
            );

        }

    }

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _poll_child {
    my ($self) = $_[OBJECT];

    my $exitcode;
    my $pid = $self->pid;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering poll_child");

    unless ($self->process->Wait(1000)) {

        $poe_kernel->delay('poll_child', 5);

        return;

    }

    unless (($self->status == PROC_KILLED) || ($self->status == PROC_SHUTDOWN)) {

        $self->status(PROC_STOPPED);

    }

    $self->process->GetExitCode($exitcode);
    $exitcode = ($exitcode * 256); # convert to perl semantics

    # turn off various POE 'selects' and 'delays', 
    # otherwise the session 'hangs'

    $poe_kernel->delay('poll_child');
    $poe_kernel->select_read($self->input_handle)   if (defined($self->input_handle));
    $poe_kernel->select_write($self->output_handle) if (defined($self->output_handle));

    # notify 'child_exit' that we are done

    $poe_kernel->post($alias, 'child_exit', 'CHLD', $pid, $exitcode);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _parse_command {
    my $self = shift;

    my @args       = split(' ', $self->command);
    my @extensions = ('.exe', '.bat', '.cmd', '.pl');
    my @path       = split(';', $ENV{PATH});

    # Stolen from Proc::Background
    #
    # If there is only one element in the @args array, then just split the
    # argument by whitespace.  If there is more than one element in @args,
    # then assume that each argument should be properly protected from
    # the shell so that whitespace and special characters are passed
    # properly to the program, just as it would be in a Unix
    # environment.  This will ensure that a single argument with
    # whitespace will not be split into multiple arguments by the time
    # the program is run.  Make sure that any arguments that are already
    # protected stay protected.  Then convert unquoted "'s into \"'s.
    # Finally, check for whitespace and protect it.
 
    for (my $i = 1; $i < @args; ++$i) {

        my $arg = $args[$i];
        $arg =~ s#\\\\#\200#g;
        $arg =~ s#\\"#\201#g;
        $arg =~ s#"#\\"#g;
        $arg =~ s#\200#\\\\#g;
        $arg =~ s#\201#\\"#g;

        if (length($arg) == 0 or $arg =~ /\s/) {

            $arg = "\"$arg\"";

        }

        $args[$i] = $arg;

    }

    # Find the absolute path to the program.  If it cannot be found,
    # then return.  To work around a problem where
    # Win32::Process::Create cannot start a process when the full
    # pathname has a space in it, convert the full pathname to the
    # Windows short 8.3 format which contains no spaces.

    $args[0] = $self->_resolve_path($args[0], \@extensions, \@path) or return;
    $args[0] = Win32::GetShortPathName($args[0]); 

    return @args;

}

sub _get_error {

    return(compress(Win32::FormatMessage(Win32::GetLastError())));

}

1;

__END__

=head1 NAME

XAS::Lib::Process::Win32 - A mixin class for process management within the XAS environment

=head1 DESCRIPTION

This module is a mixin class to handle the needs for process management
under a Windows system.

=head1 METHODS

=head2 init_process

This method initializes the module so that it can function properly.

=head2 start_process

This method does the necessary things to spawn a new process. 

=head2 stat_process

This method returns the status of the process. These are the possible
values.

=over 4

=item B<6>

This status indicates that the process is in a "suspended ready" state.

=item B<5>

This status indicates that the process is in a "suspended blocked" state.

=item B<4>

This status indicates that the process is in a "blocked" state.

=item B<3>

This status indicates that the process is in a "running" state.

=item B<2>

This indicates that the process is in a "ready" state.

=item B<1>

This indicates that the process is in a "other" state.

=item B<0>

This indicates that the process is in an unknown state.

=back

=head2 stop_process

This method will use Win32::Process:KillProcess to stop the process.

=head2 pause_process

This method will use the Pause() method to pause the process.

=head2 resume_process

This method will Resume() method to resume the process.

=head2 kill_process

This method calls stop_process().

=head1 SEE ALSO

=over 4

=item L<Win32::Process|https://metacpan.org/pod/Win32::Process>

=item L<XAS::Lib::Process|XAS::Lib::Process>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
