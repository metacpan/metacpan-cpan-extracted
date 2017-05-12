package XAS::Lib::Spawn::Unix;

our $VERSION = '0.01';

use POSIX qw(:errno_h :sys_wait_h);

use XAS::Class
  version => $VERSION,
  base    => 'XAS::Base',
  utils   => ':env dotid compress trim exitcode',
  mixins  => 'run stop status pause resume wait _parse_command',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub run {
    my $self = shift;

    my $pid;
    my $umask     = oct($self->umask);
    my $env       = $self->environment;
    my @args      = $self->_parse_command;
    my $priority  = $self->priority;
    my $uid       = ($self->user eq 'root')  ? 0 : getpwnam($self->user);
    my $gid       = ($self->group eq 'root') ? 0 : getgrnam($self->group);
    my $directory = $self->directory->path;
    my $oldenv    = env_store();
    my $newenv    = $self->merger->merge($oldenv, $env);

    my $spawn = sub {

        # become a session leader

        setsid();

	    # redirect the standard file handles to dev null

	    open(STDIN,  '<', '/dev/null');
	    open(STDOUT, '>', '/dev/null');
	    open(STDERR, '>', '/dev/null');

        eval {               # set priority, fail silently
            my $p = getpriority(0, $$);
            setpriority(0, $$, $p + $priority);
        };

        $( = $) = $gid;      # set new group id
        $< = $> = $uid;      # set new user id

        env_create($newenv); # create the new environment

        chdir($directory);   # change directory
        umask($umask);       # set protection mask
        exec(@args);         # become a new process

        exit 0;

    };

    unless ($pid = fork) {

        # child

        $spawn->();

    }

	# parent

    unless(defined($pid)) {

        $self->throw_msg(
            dotid($self->class) . '.detach.creation',
            'unexpected',
            'unable to spawn a new process',
        );

    }

	return $pid;

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
    my $alias = $self->alias;

    if ($self->pid) {

        my $pid = ($self->pid * -1);
        my $code = $self->status();

        if (($code == 3) || ($code == 2)) {   # process is running or ready

            if (kill('STOP', $pid)) {

				$stat = 1;

            }

        }

    }

	return $stat;

}

sub resume {
    my $self = shift;

	my $stat = 0;

    if ($self->pid) {

        my $pid = ($self->pid * -1);
        my $code = $self->status();

        if ($code == 6) {   # process is suspended ready

            if (kill('CONT', $pid)) {

				$stat = 1;

            }

        }

    }

	return $stat;

}

sub stop {
    my $self = shift;

	my $stat = 0;

    if ($self->pid) {

        my $pid = ($self->pid * -1);

        if (kill('TERM', $pid)) {

			$stat = 1;

        }

    }

	return $stat;

}

sub kill {
    my $self = shift;

    my $stat = 0;

    if ($self->pid) {

        my $pid = ($self->pid * -1);

        if (kill('KILL', $pid)) {

			$stat = 1;

        }

    }

	return $stat;

}

sub wait {
	my $self = shift;

	my $stat = 0;

	if (my $pid = $self->pid) {

		sleep(1);    # emulate the 1000ms wait in the Win32 mixin

		# Try to wait on the process.

		my $result = waitpid($pid, WNOHANG);

		if ($result == $pid) {

			# Process finished.  Grab the exit value.

			my ($rc, $sig) = exitcode();

			$self->{'errorlevel'} = $rc;
			$self->{'pid'} = 0;

		} elsif ($result == -1 and $! == ECHILD) {

			# Process already reaped.  We don't know the exist status.

			$self->{'errorlevel'} = -1;
			$self->{'pid'} = 0;
	
		} else {

			# Process still running

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
    my @path = split(':', $ENV{PATH});
    my @extensions = ('');
 
    # Stolen from Proc::Background
    #
    # If there is only one element in the @args array, then it may be a
    # command to be passed to the shell and should not be checked, in
    # case the command sets environmental variables in the beginning,
    # i.e. 'VAR=arg ls -l'.  If there is more than one element in the
    # array, then check that the first element is a valid executable
    # that can be found through the PATH and find the absolute path to
    # the executable.  If the executable is found, then replace the
    # first element it with the absolute path.

    if (scalar(@args) > 1) {

        $args[0] = $self->_resolve_path($args[0], \@extensions, \@path) or return;

    }

    return @args;

}

1;

__END__

=head1 NAME

XAS::Lib::Spawn::Unix - A mixin class for spawing processes within the XAS environment

=head1 DESCRIPTION

This module is a mixin class to handle the spawing as process under a
Unix like system.

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
