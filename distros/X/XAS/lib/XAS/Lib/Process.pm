package XAS::Lib::Process;

our $VERSION = '0.02';

my $mixin;

BEGIN {
    $mixin = 'XAS::Lib::Process::Unix';
    $mixin = 'XAS::Lib::Process::Win32' if ($^O eq 'MSWin32');    
}

use Set::Light;
use Hash::Merge;
use Badger::Filesystem 'Cwd Dir File';
use XAS::Constants ':process CODEREF';
use POE qw(Wheel Driver::SysRW Filter::Line);

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::POE::Service',
  mixin     => "XAS::Lib::Mixins::Process $mixin",
  utils     => ':validation dotid trim',
  mutators  => 'input_handle output_handle status retries',
  accessors => 'pid exit_code exit_signal process ID merger',
  vars => {
    PARAMS => {
      -command        => 1,
      -auto_start     => { optional => 1, default => 1 },
      -auto_restart   => { optional => 1, default => 1 },
      -environment    => { optional => 1, default => {} },
      -exit_codes     => { optional => 1, default => '0,1' },
      -exit_retries   => { optional => 1, default => 5 },
      -group          => { optional => 1, default => 'nobody' },
      -priority       => { optional => 1, default => 0 },
      -pty            => { optional => 1, default => 0 },
      -umask          => { optional => 1, default => '0022' },
      -user           => { optional => 1, default => 'nobody' },
      -redirect       => { optional => 1, default => 0 },
      -retry_delay    => { optional => 1, default => 0 },
      -input_driver   => { optional => 1, default => POE::Driver::SysRW->new() },
      -output_driver  => { optional => 1, default => POE::Driver::SysRW->new() },
      -input_filter   => { optional => 1, default => POE::Filter::Line->new(Literal => "\n") },
      -output_filter  => { optional => 1, default => POE::Filter::Line->new(Literal => "\n") },
      -directory      => { optional => 1, default => Cwd, isa => 'Badger::Filesystem::Directory' },
      -output_handler => { optional => 1, type => CODEREF, default => sub {
              my $output = shift;
              printf("%s\n", trim($output));
          }
      },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    $poe_kernel->state('get_event',    $self, '_get_event');
    $poe_kernel->state('flush_event',  $self, '_flush_event');
    $poe_kernel->state('error_event',  $self, '_error_event');
    $poe_kernel->state('close_event',  $self, '_close_event');
    $poe_kernel->state('check_status', $self, '_check_status');
    $poe_kernel->state('poll_child',   $self, '_poll_child');
    $poe_kernel->state('child_exit',   $self, '_child_exit');

    $poe_kernel->state('start_process',  $self, '_start_process');
    $poe_kernel->state('stop_process',   $self, '_stop_process');
    $poe_kernel->state('pause_process',  $self, '_pause_process');
    $poe_kernel->state('resume_process', $self, '_resume_process');
    $poe_kernel->state('kill_process',   $self, '_kill_process');


    # walk the chain

    $self->SUPER::session_initialize();

    $poe_kernel->post($alias, 'session_startup');

    $self->log->debug("$alias: leaving session_initialize()");

}

sub session_startup {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_startup()");

    if ($self->auto_start) {

        $poe_kernel->call($alias, 'start_process');
        
    }

    # walk the chain

    $self->SUPER::session_startup();

    $self->log->debug("$alias: leaving session_startup()");

}

sub session_pause {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_pause()");

    $poe_kernel->call($alias, 'pause_process');
    
    # walk the chain

    $self->SUPER::session_pause();

    $self->log->debug("$alias: leaving session_pause()");

}

sub session_resume {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_resume()");

    $poe_kernel->call($alias, 'resume_process');

    # walk the chain

    $self->SUPER::session_resume();

    $self->log->debug("$alias: leaving session_resume()");

}

sub session_stop {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_stop()");

    $self->kill_process();
    $poe_kernel->sig_handled();

    # walk the chain

    $self->SUPER::session_stop();

    $self->log->debug("$alias: leaving session_stop()");

}

sub session_shutdown {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_shutdown()");

    $self->status(PROC_SHUTDOWN);

    $poe_kernel->call($alias, 'stop_process');
    $poe_kernel->sig_handled();
  
    # walk the chain

    $self->SUPER::session_shutdown();

    $self->log->debug("$alias: leaving session_shutdown()");

}

sub put {
    my $self = shift;
    my ($chunk) = validate_params(\@_, [1]);

    my @chunks;
    my $driver = $self->input_driver;
    my $filter = $self->input_filter;

    # Avoid big bada boom if someone put()s on a dead wheel.

    unless ($self->input_handle) {

        $self->throw_msg(
            dotid($self->class) . '.put_input.writerr',
            'process_writerr',
            'called put() on a wheel without an open INPUT handle' 
        );

    }
 
    push(@chunks, $chunk);

    if ($self->{'buffer'} = $driver->put($filter->put(\@chunks))) {

        $poe_kernel->select_resume_write($self->input_handle);

    }

    return 0;

}

sub DESTROY {
    my $self = shift;

    if ($self->input_handle) {

        $poe_kernel->select_write($self->input_handle);
        $self->input_handle(undef);

    }

    if ($self->output_handle) {

        $poe_kernel->select_read($self->output_handle);
        $self->output_handle(undef);

    }

    $self->destroy();

    POE::Wheel::free_wheel_id($self->ID);

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _start_process {
    my $self = $_[OBJECT];

    my $count = 1;
    my $alias = $self->alias;

    if ($self->status == PROC_STOPPED) {

        $self->start_process();
        $poe_kernel->post($alias, 'check_status', $count);

    }

}

sub _resume_process {
    my $self = $_[OBJECT];

    my $count = 1;
    my $alias = $self->alias;

    $self->resume_process();
    $poe_kernel->post($alias, 'check_status', $count);

}

sub _pause_process {
    my $self = $_[OBJECT];

    my $count = 1;
    my $alias = $self->alias;

    $self->pause_process();
    $poe_kernel->post($alias, 'check_status', $count);

}

sub _stop_process {
    my $self = $_[OBJECT];

    my $count = 1;
    my $alias = $self->alias;

    $self->stop_process();
    $poe_kernel->post($alias, 'check_status', $count);

}

sub _kill_process {
    my $self = $_[OBJECT];

    my $count = 1;
    my $alias = $self->alias;

    $self->kill_process();
    $poe_kernel->post($alias, 'check_status', $count);

}

sub _get_event {
    my ($self, $output, $wheel) = @_[OBJECT,ARG0,ARG1];

    $self->output_handler->($output);

}

sub _check_status {
    my ($self, $count) = @_[OBJECT, ARG0];

    my $alias = $self->alias;
    my $stat = $self->stat_process();

    $self->log->debug(sprintf('%s: check_status: process: %s, status: %s, count %s', $alias, $stat, $self->status, $count));

    $count++;

    if ($self->status == PROC_STARTED) {

        if (($stat == 3) || ($stat == 2)) {

            $self->status(PROC_RUNNING);
            $self->log->info_msg('process_started', $alias, $self->pid);

        } else {

            $poe_kernel->delay('check_status', 5, $count);

        }

    } elsif ($self->status == PROC_RUNNING) {

        if (($stat != 3) || ($stat != 2)) {

            $self->resume_process();
            $poe_kernel->delay('check_status', 5, $count);

        }

    } elsif ($self->status == PROC_PAUSED) {

        if ($stat != 6) {

            $self->pause_process();
            $poe_kernel->delay('check_status', 5, $count);

        }

    } elsif ($self->status == PROC_STOPPED) {

        if ($stat != 0) {

            $self->stop_process();
            $poe_kernel->delay('check_status', 5, $count);

        }

    } elsif($self->status == PROC_KILLED) {

        if ($stat != 0) {

            $self->kill_process();
            $poe_kernel->delay('check_status', 5, $count);

        }

    }

}

sub _flush_event {
    my ($self, $wheel) = @_[OBJECT,ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: flush_event");

}

sub _error_event {
    my ($self, $operation, $errno, $errstr, $wheel, $type) = @_[OBJECT,ARG0..ARG4];

    my $alias = $self->alias;

    $self->log->debug( 
        sprintf('%s: error_event - ops: %s, errno: %s, errstr: %s',
                $alias, $operation, $errno, $errstr)
    );

}

sub _close_event {
    my ($self, $wheel) = @_[OBJECT,ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: close_event");

    $poe_kernel->select_write($self->input_handle);
    $self->input_handle(undef);

    $poe_kernel->select_read($self->output_handle);
    $self->output_handle(undef);

}

sub _child_exit {
    my ($self, $signal, $pid, $exitcode) = @_[OBJECT,ARG0...ARG2];

    my $alias   = $self->alias;
    my $status  = $self->status;
    my $retries = $self->retries;

    $self->{'pid'}         = undef;
    $self->{'exit_code'}   = $exitcode >> 8;
    $self->{'exit_signal'} = $exitcode & 127;

    $self->log->warn_msg('process_exited', $alias, $pid, $self->exit_code, $self->exit_signal);

    if ($status == PROC_STOPPED) {

        if ($self->auto_restart) {

            if (($retries < $self->exit_retries) || ($self->exit_retries < 0)) {

                $retries += 1;
                $self->retries($retries);

                if ($self->exit_codes->has($self->exit_code)) {

                    if ($self->retry_delay) {

                        $poe_kernel->delay('start_process', $self->retry_delay);

                    } else {

                        $poe_kernel->call($alias, 'start_process');

                    }

                } else {

                    $self->log->warn_msg(
                        'process_unknown_exitcode', 
                        $alias,
                        $self->exit_code || '',
                        $self->exit_signal || '',
                    );

                }

            } else {

                $self->log->warn_msg('process_nomore_retries', $alias, $retries);

            }

        } else {

            $self->log->warn_msg('process_no_autorestart', $alias);

        }

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

# stolen from POE::Wheel::Run - more or less

sub _process_output {
    my $self = shift;

    my $id     = $self->ID;
    my $driver = $self->output_driver;
    my $filter = $self->output_filter;
    my $output = $self->output_handle;
    my $state  = ref($self) . "($id) -> select output";

    if ($filter->can('get_one') and $filter->can('get_one_start')) {

        $poe_kernel->state(
            $state,
            sub {
                my ($k, $me, $handle) = @_[KERNEL, SESSION, ARG0];
                if (defined(my $raw = $driver->get($handle))) {
                    $filter->get_one_start($raw);
                    while (1) {
                        my $next_rec = $filter->get_one();
                        last unless @$next_rec;
                        foreach my $cooked (@$next_rec) {
                            $k->call($me, 'get_event', $cooked, $id);
                        }
                    }
                } else {
                    $k->call($me, 'error_event', 'read', ($!+0), $!, $id, 'OUTPUT');
                    $k->call($me, 'close_event', $id);
                    $k->select_read($handle);
                }
            }
        );

    } else {

        $poe_kernel->state(
            $state,
            sub {
                my ($k, $me, $handle) = @_[KERNEL, SESSION, ARG0];
                if (defined(my $raw = $driver->get($handle))) {
                    foreach my $cooked (@{$filter->get($raw)}) {
                        $k->call($me, 'get_event', $cooked, $id);
                    }
                } else {
                    $k->call($me, 'error_event', 'read', ($!+0), $!, $id, 'OUTPUT');
                    $k->call($me, 'close_event', $id);
                    $k->select_read($handle);
                }
            }
        );

    }

    $poe_kernel->select_read($output, $state);

}

sub _process_input {
    my $self = shift;

    my $id     = $self->ID;
    my $driver = $self->input_driver;
    my $filter = $self->input_filter;
    my $input  = $self->input_handle;
    my $buffer = \$self->{'buffer'};
    my $state  = ref($self) . "($id) -> select input";

    $poe_kernel->state(
        $state,
        sub {
            my ($k, $me, $handle) = @_[KERNEL,SESSION,ARG0]; 
            $$buffer = $driver->flush($handle); 
            # When you can't write, nothing else matters.
            if ($!) {
                $k->call($me, 'error_event', 'write', ($!+0), $!, $id, 'INPUT');
                $k->select_write($handle);
            } else {
                # Could write, or perhaps couldn't but only because the
                # filehandle's buffer is choked. 
                # All chunks written; fire off a "flushed" event.
                unless ($$buffer) {
                    $k->select_pause_write($handle);
                    $k->call($me, 'flush_event', $id);
                }
            }
        }
    );

    $poe_kernel->select_write($input, $state);

    # Pause the write select immediately, unless output is pending.

    $poe_kernel->select_pause_write($input) unless ($buffer);

}

# Stolen from Proc::Background - more or less

sub _resolve_path {
    my $self       = shift;
    my $command    = shift;
    my $extensions = shift;
    my $xpaths     = shift;

    # Make the path to the progam absolute if it isn't already.  If the
    # path is not absolute and if the path contains a directory element
    # separator, then only prepend the current working to it.  If the
    # path is not absolute, then look through the PATH environment to
    # find the executable.

    my $alias = $self->alias;
    my $path = File($command);

    if ($path->is_absolute) {

        if ($path->exists) {

            return $path->absolute;

        }

    } elsif ($path->is_relative) {

        if ($path->name eq $path) {

            foreach my $xpath (@$xpaths) {

                next if ($xpath eq '');

                if ($path->extension) {

                    my $p = File($xpath, $path->name);

                    if ($p->exists) {

                        return $p->absolute;

                    }

                } else {

                    foreach my $ext (@$extensions) {

                        my $p = File($xpath, $path->basename . $ext);

                        if ($p->exists) {

                            return $p->absolute;

                        }

                    }

                }

            }

        } else {

            my $p = File($path->absoulte);

            if ($p->exists) {

                return $p->absolute;

            }

        }

    }

    $self->throw_msg(
        dotid($self->class) . '.resolve_path.path',
        'location',
        $alias, $command
    );


}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    my @exit_codes = split(',', $self->exit_codes);

    $self->{'exit_codes'} = Set::Light->new(@exit_codes);
    $self->{'ID'}         = POE::Wheel::allocate_wheel_id();
    $self->{'merger'}     = Hash::Merge->new('RIGHT_PRECEDENT');

    $self->retries(1);
    $self->init_process();
    $self->status(PROC_STOPPED);

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Process - A class for managing processes within the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::Process;

 my $process = XAS::Lib::Process->new(
    -command => 'perl test.pl'
 );
 
 $process->run();

=head1 DESCRIPTION

This class manages a sub process in a platform independent way. Mixins
are loaded to handle the differences between Unix/Linux and Windows.
This module inherits from L<XAS::Lib::POE::Service|XAS::Lib::POE::Service>. 
Please refer to that module for additional help. 

=head1 METHODS

=head2 new

This method initialized the module and takes the following parameters:

=over 4

=item B<-auto_start>

This indicates wither to auto start the process. The default is true.

=item B<-auto_restart>

This indicates wither to auto restart the process if it exits. The default
is true.

=item B<-command>

The command to run.

=item B<-directory>

The optional directory to start the process in. Defaults to the current
directory of the parent process.

=item B<-environment>

Optional, additional environment variables to provide to the process.
The default is none.

=item B<-exit_codes>

Optional exit codes to check for the process. They default to '0,1'.
If the exit code matches, then the process is auto restarted. This should
be a comma delimited list of values.

=item B<-exit_retries>

The optional number of retries for restarting the process. The default
is 5.

=item B<-group>

The group to run the process under. Defaults to 'nobody'. This group
may not be defined on your system. This option is not implemented on Windows.

=item B<-priority>

The optional priority to run the process at. Defaults to 0. This option
is not implemented on Windows.

=item B<-umask>

The optional protection mask for the process. Defaults to '0022'. This
option is not implemented on Windows.

=item B<-user>

The optional user to run the process under. Defaults to 'nobody'. This user
may not be defined on your system. This option is not implemented on Windows.

=item B<-redirect>

This option is used to indicate wither to redirect stdout and stderr
from the child process to the parent and stdin from the parent to the
child process. The redirection combines stderr with stdout. Redirection
is implemented using sockets. This may cause buffering problems with the
child process.

The default is no.

=item B<-retry_delay>

The optional number of seconds to delay a retry on an auto restart process.
The default is 0, or no delay in restarting the process.

=item B<-input_driver>

The optional input driver to use. Defaults to POE::Driver::SysRW.

=item B<-output_driver>

The optional output driver to use. Defaults to POE::Driver::SysRW.

=item B<-input_filter>

The optional filter to use for input. Defaults to POE::Filter::Line.

=item B<-output_filter>

The optional output filter to use. Defaults to POE::Filter::Line.

=item B<-output_handler>

This is an optional coderef to handle output from the process. The coderef
takes one parameter, the output from the process.

=back

=head1 METHODS

=head2 put($data)

This method will write a buffer to stdin.

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::Process::Unix|XAS::Lib::Process::Unix>

=item L<XAS::Lib::Process::Win32|XAS::Lib::Process::Win32>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
