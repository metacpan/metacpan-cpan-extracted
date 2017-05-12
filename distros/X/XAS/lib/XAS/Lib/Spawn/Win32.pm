package XAS::Lib::Spawn::Win32;

our $VERSION = '0.01';

use Win32::Process;

use XAS::Class
  version => $VERSION,
  base    => 'XAS::Base',
  utils   => ':env dotid compress',
  mixins  => 'run stop status pause resume wait _parse_command',
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub run {
    my $self = shift;

    my @args  = $self->_parse_command();
    my $dir   = $self->directory->path;

    my $child;
    my $stdin;
    my $parent;
    my $stderr;
    my $stdout;
    my $inherit;
    my $process;
    my $flags = DETACHED_PROCESS;
    my $env = $self->environment;

    # create the new environment, this is inherited by the new process

    my $oldenv = env_store();
    my $newenv = $self->merger->merge($oldenv, $env);

    env_create($newenv);

    # dup stdin, stdout and stderr

    open($stdin,  '<&', \*STDIN);
    open($stdout, '>&', \*STDOUT);
    open($stderr, '>&', \*STDERR);

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

    # recover the original stdin, stdout and stderr

    open(STDIN,  '<&', $stdin);
    open(STDOUT, '>&', $stdout);
    open(STDERR, '>&', $stderr);

    # recover the old environment

    env_restore($oldenv);

    return $process->GetProcessID();

}

sub status {
    my $self = shift;

    my $stat = 0;

    if ($self->pid) {

        my $pid = $self->pid;

        $stat = $self->proc_status($pid);

    }

    return $stat;

}

sub pause {
    my $self = shift;

    my $stat = 0;

    if ($self->pid) {

        my $code = $self->status();

        if (($code == 3) || ($code == 2)) {   # process is running or ready

            $self->process->Suspend();
            $stat = 1;

        }

    }

    return $stat;

}

sub resume {
    my $self = shift;
    
    my $stat = 0;

    if ($self->pid) {

        my $code = $self->status();

        if ($code == 6) {

            $self->process->Resume();
            $stat = 1;

        }

    }

    return $stat;

}

sub stop {
    my $self = shift;

    my $stat = 0;

    if ($self->pid) {

        my $exitcode;
        my $pid = $self->pid;

        Win32::Process::KillProcess($pid, $exitcode);

    }

    return $stat;

}

sub kill {
    my $self = shift;

    return $self->stop();

}

sub wait {
    my $self = shift;

    my $stat = 0;

    if (my $pid = $self->pid) {

        # Try to wait on the process.

        my $result = $self->process->Wait(1000);

        if ($result == 1) {

            # Process finished.  Grab the exit value.

            my $exitcode;
            $self->process->GetExitCode($exitcode);

            $self->{'errorlevel'} = ($exitcode * 256) >> 8;
            $self->{'pid'} = 0;

        } elsif ($result == 0) {

            # Process still running.

            $stat = 1;

        }

    }

    return $stat;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _parse_command {
    my $self = shift;

    my @args = split(' ', $self->command);
    my @path = split(';', $ENV{PATH});
    my @extensions =  ('.bat', '.cmd', '.exe', '.pl');

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

XAS::Lib::Spawn::Win32 - A mixin class for process management within the XAS environment

=head1 DESCRIPTION

This module is a mixin class to handle the spawning a process under a
Windows system.

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::Spawn|XAS::Lib::Spawn>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
