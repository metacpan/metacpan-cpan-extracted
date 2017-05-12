package XAS::Supervisor::Controller;

our $VERSION = '0.01';

use POE;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::RPC::JSON::Server',
  utils     => 'stat2text :validation',
  constants => ':process :jsonrpc HASHREF',
  vars => {
    PARAMS => {
      -processes => 1,
      -retires   => { optional => 1, default => 5 },
    }
  }
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize() - supervisor");

    # define our events.

    $poe_kernel->state('kill_process',   $self, '_kill_process');
    $poe_kernel->state('stop_process',   $self, '_stop_process');
    $poe_kernel->state('stat_process',   $self, '_stat_process');
    $poe_kernel->state('start_process',  $self, '_start_process');
    $poe_kernel->state('pause_process',  $self, '_pause_process');
    $poe_kernel->state('resume_process', $self, '_resume_process');
    $poe_kernel->state('check_status',   $self, '_check_status');
    $poe_kernel->state('list_processes', $self, '_list_processes');

    # define the RPC methods, these are linked to the above events

    $self->methods->insert('kill_process');
    $self->methods->insert('start_process');
    $self->methods->insert('stop_process');
    $self->methods->insert('stat_process');
    $self->methods->insert('pause_process');
    $self->methods->insert('resume_process');
    $self->methods->insert('list_processes');

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_initialize() - supervisor");

}

sub check_status {
    my $self = shift;
    my ($params, $ctx, $status) = validate_params(\@_, [
        { type => HASHREF },
        { type => HASHREF },
        1
    ]);

    my $count = 0;
    my $alias = $self->alias;

    $poe_kernel->delay_add('check_status', 5, $params, $ctx, $status, $count);

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _stop_process {
    my ($self, $params, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my $name  = $params->{'name'};

    if (my $process = $self->processes->{$name}) {

        my $session = $process->alias;

        $poe_kernel->call($session, 'stop_process');
        $self->check_status($params, $ctx, PROC_STOPPED);
        $self->log->info_msg('supervisor_action', $alias, 'stop_process', $name);

    } else {

        my $error = {
            code    => RPC_ERR_APP,
            message => $self->message('supervisor_unable', 'stop_process', $name)
        };

        $self->process_errors($error, $ctx);

    }

}

sub _kill_process {
    my ($self, $params, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my $name  = $params->{'name'};

    if (my $process = $self->processes->{$name}) {

        my $session = $process->alias;

        $poe_kernel->call($session, 'kill_process');
        $self->check_status($params, $ctx, PROC_KILLED);
        $self->log->info_msg('supervisor_action', $alias, 'kill_process', $name);

    } else {

        my $error = {
            code    => RPC_ERR_APP,
            message => $self->message('supervisor_unable', 'kill_process', $name)
        };

        $self->process_errors($error, $ctx);

    }

}

sub _stat_process {
    my ($self, $params, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my $name  = $params->{'name'};

    if (my $process = $self->processes->{$name}) {

        my $stat   = $process->stat_process();
        my $status = stat2text($stat);

        $self->process_response($status, $ctx);
        $self->log->info_msg('supervisor_action', $alias, 'stat_process', $name);

    } else {

        my $error = {
            code    => RPC_ERR_APP,
            message => $self->message('supervisor_unable', 'stat_process', $name)
        };

        $self->process_errors($error, $ctx);

    }

}

sub _start_process {
    my ($self, $params, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my $name  = $params->{'name'};

    if (my $process = $self->processes->{$name}) {

        my $session = $process->alias;

        $poe_kernel->call($session, 'start_process');
        $self->check_status($params, $ctx, PROC_RUNNING);
        $self->log->info_msg('supervisor_action', $alias, 'start_process', $name);

    } else {

        my $error = {
            code    => RPC_ERR_APP,
            message => $self->message('supervisor_unable', 'start_process', $name)
        };

        $self->process_errors($error, $ctx);

    }

}

sub _pause_process {
    my ($self, $params, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my $name  = $params->{'name'};

    if (my $process = $self->processes->{$name}) {

        my $session = $process->alias;

        $poe_kernel->call($session, 'pause_process');
        $self->check_status($params, $ctx, PROC_PAUSED);
        $self->log->info_msg('supervisor_action', $alias, 'pause_process', $name);

    } else {

        my $error = {
            code    => RPC_ERR_APP,
            message => $self->message('supervisor_unable', 'pause_process', $name)
        };

        $self->process_errors($error, $ctx);

    }

}

sub _resume_process {
    my ($self, $params, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my $name  = $params->{'name'};

    if (my $process = $self->processes->{$name}) {

        my $session = $process->alias;

        $poe_kernel->call($session, 'resume_process');
        $self->check_status($params, $ctx, PROC_RUNNING);
        $self->log->info_msg('supervisor_action', $alias, 'resume_process', $name);

    } else {

        my $error = {
            code    => RPC_ERR_APP,
            message => $self->message('supervisor_unable', 'resume_process', $name)
        };

        $self->process_errors($error, $ctx);

    }

}

sub _check_status {
    my ($self, $params, $ctx, $status, $count) = @_[OBJECT,ARG0...ARG3];

    my $alias = $self->alias;
    my $name  = $params->{'name'};

    if (my $process = $self->processes->{$name}) {

        my $stat = $process->status();

        if ($stat == $status) {

            my $response = 'stopped';

            $response = 'running' if ($stat == PROC_RUNNING);
            $response = 'paused'  if ($stat == PROC_PAUSED);
            $response = 'killed'  if ($stat == PROC_KILLED);

            $self->process_response($response, $ctx);

        } else {

            $count += 1;

            if ($count < $self->retires) {

                $poe_kernel->delay_add('check_status', 5, $params, $ctx, $status, $count);

            } else {

                my $error = {
                    code    => RPC_ERR_APP,
                    message => $self->message('supervisor_nostatus', $name)
                };

                $self->process_errors($error, $ctx);

            }

        }

    } else {

        my $error = {
            code    => RPC_ERR_APP,
            message => $self->message('supervisor_unable', 'check_status', $name)
        };

        $self->process_errors($error, $ctx);

    }

}

sub _list_processes {
    my ($self, $params, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my @response = sort(keys($self->processes));

    $self->process_response(\@response, $ctx);
    $self->log->info_msg('supervisor_action', $alias, 'list_processes', '');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Supervisor::Controller - manage multiple processes

=head1 SYNOPSIS

 use XAS::Supervisor::Controller;

 my $controller = XAS::Supervisor::Controller->new(
    -alias     => 'controller',
    -port      => '9506',
    -address   => '127.0.0.1,
    -processes => $processes
 );

 $controller->run;

=head1 DESCRIPTION

This module provides a RPC interface to the supervisor. This interface allows
external access to stop, start, pause, resume and kill processes. It also
provides a means to to retrieve the status of a process and to list all the
known processes.

=head1 METHODS

=head2 new

This module inherits from L<XAS::Lib::RPC::JSON::Server|XAS::Lib::RPC::JSON::Server>
and takes all of the same parameters.

=head2 session_initialize

This method sets up the process for the rpc calls.

=head2 check_status

This method starts a background task to check the status of RPC calls. 

=head1 RPC CALLS

The following rpc calls are supported. L<XAS::Supervisor::Client|XAS::Supervisor::Client>
has this interface already defined and should be used when writting new code.

=head2 start_process

This will start a process. The rpc parameters should use 'name' with the 
processes name. If the start was successful, "running" will be returned.

=head2 stop_process

This will stop a process. The rpc parameters should use 'name' with the 
processes name. If the stop was successful, "stopped" will 
be returned.

=head2 pause_process

This will pause a process. The rpc parameters should use 'name' with the 
processes name. If the pause was successful, "paused" will 
be returned.

=head2 resume_process

This will resume a process. The rpc parameters should use 'name' with the 
processes name. If the resume was successful, "running" will 
be returned.

=head2 kill_process

This will kill a process. The rpc parameters should use 'name' with the 
processes name. If the kill was successful, "killed" will 
be returned.

=head2 stat_process

This will perform an OS level stat on the process. The rpc parameters should 
use 'name' with the processes name. It will return one of the
following.

 'suspended ready'
 'suspended blocked'
 'blocked'
 'running'
 'ready'
 'other'
 'unknown'

=head2 list_process

This will return a list of all the processes that the supervisor knows of.

=head1 SEE ALSO

=over 4

=item L<XAS::Supervisor::Client|XAS::Supervisor::Client>

=item L<XAS::Supervisor::Monitor|XAS::Supervisor::Monitor>

=item L<XAS::Supervisor|XAS::Supervisor>

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
