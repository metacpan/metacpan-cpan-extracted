package XAS::Lib::Service::Unix;

our $VERSION = '0.01';

use POE;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  utils   => ':validation',
  constant => {
    SERVICE_START_PENDING    => 1,
    SERVICE_STOP_PENDING     => 2,
    SERVICE_PAUSE_PENDING    => 3,
    SERVICE_CONTINUE_PENDING => 4,
    SERVICE_CONTROL_SHUTDOWN => 5,
    SERVICE_RUNNING          => 6,
    SERVICE_STOPPED          => 7,
    SERVICE_PAUSED           => 8,
  },
  mixins  => 'init_service _current_state session_interrupt poll
              SERVICE_START_PENDING SERVICE_STOP_PENDING
              SERVICE_PAUSE_PENDING SERVICE_CONTINUE_PENDING
              SERVICE_CONTROL_SHUTDOWN SERVICE_RUNNING
              SERVICE_STOPPED SERVICE_PAUSED',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub init_service {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering init_service() - unix");

    $poe_kernel->sig('CONT', 'session_interrupt');
    $poe_kernel->sig('TSTP', 'session_interrupt');

    $self->log->debug("$alias: leaving int_service() - unix");

}

sub session_interrupt {
    my $self   = shift;
    my $signal = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: session_interrupt()");
    $self->log->warn_msg('service_signaled', $alias, $signal);

    if ($signal eq 'HUP') {

        $self->session_reload();

    } elsif ($signal eq 'CONT') {

        $poe_kernel->sig_handled();
        $self->_current_state(SERVICE_CONTINUE_PENDING);

    } elsif ($signal eq 'TSTP') {

        $poe_kernel->sig_handled();
        $self->_current_state(SERVICE_PAUSE_PENDING);

    } else { # INT, TERM, QUIT

        $poe_kernel->sig_handled();
        $self->_current_state(SERVICE_CONTROL_SHUTDOWN);

    }

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub poll {
    my ($self) = $_[OBJECT];

    my $stat;
    my $alias = $self->alias;
    my $delay = $self->poll_interval;
    my $state = $self->_current_state();

    $self->log->debug("$alias: entering _poll()");

    if ($state == SERVICE_START_PENDING) {

        $self->log->debug("$alias: state = SERVICE_START_PENDING");

        # Initialization code

        $self->last_state(SERVICE_START_PENDING);
        $self->_current_state(SERVICE_START_PENDING, 6000);

        # Initialization code
        # ...do whatever you need to do to start...

        $self->_service_startup();
        $self->last_state(SERVICE_RUNNING);

    } elsif ($state == SERVICE_STOP_PENDING) {

        $self->log->debug("$alias: state = SERVICE_STOP_PENDING");

        # Stopping...

        $self->last_state(SERVICE_STOPPED);

    } elsif ($state == SERVICE_PAUSE_PENDING) {

        $self->log->debug("$alias: state = SERVICE_PAUSE_PENDING");

        # Pausing...

        $self->_service_paused();
        $self->last_state(SERVICE_PAUSED);

    } elsif ($state == SERVICE_CONTINUE_PENDING) {

        $self->log->debug("alias: state = SERVICE_CONTINUE_PENDING");

        # Resuming...

        if ($self->last_state == SERVICE_PAUSED) {

            $self->_service_resumed();
            $self->last_state(SERVICE_RUNNING);

        } else {

            $self->log->info_msg('service_unpaused');

        }

    } elsif ($state == SERVICE_RUNNING) {

        $self->log->debug("$alias: state = SERVICE_RUNNING");

        # Running...
        #
        # Note that here you want to check that the state
        # is indeed SERVICE_RUNNING. Even though the Running
        # callback is called it could have done so before
        # calling the "Start" callback.
        #

        if ($self->last_state == SERVICE_RUNNING) {

            $self->_service_idle();
            $self->last_state(SERVICE_RUNNING);

        }

    } elsif ($state == SERVICE_STOPPED) {

        $self->log->debug("$alias: state = SERVICE_STOPPED");

        # stopped...

        $delay = 0;
        $poe_kernel->post($alias, 'session_shutdown');
        $self->last_state(SERVICE_STOPPED);

    } elsif ($state == SERVICE_CONTROL_SHUTDOWN) {

        $self->log->debug("$alias: state = SERVICE_CONTROL_SHUTDOWN");

        # shutdown...

        unless ($self->last_state == SERVICE_PAUSED) {

            $self->_service_shutdown();
            $delay = $self->shutdown_interval;
            $self->last_state(SERVICE_STOP_PENDING);

        }

    }

    # tell the SCM what is going on

    $self->_current_state($self->last_state, $delay);

    # queue the next polling interval

    unless ($delay == 0) {

        $stat = $poe_kernel->delay('poll', $delay);
        $self->log->error_msg('service_que_delay', $alias, $stat) if ($stat != 0);

    }

    $self->log->debug("$alias: leaving _poll()");

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _current_state {
    my $self = shift;
    my ($state, $delay) = validate_params(\@_, [
        { optional => 1, default => undef },
        { optional => 1, default => 0 },
    ]);

    if (defined($state)) {

        $self->{'state'} = $state;

    }

    return $self->{'state'};

}

1;

__END__

=head1 NAME

XAS::Lib::Service::Unix - A mixin class for Unix Services

=head1 DESCRIPTION

This module is a mixin that provides an interface between a Unix like system 
and a Service. It responds to these additional signals.

 TSTP - pause the session
 CONT - resume the session

It allows POE to manage the scheduling of sessions while handling the 
additional signals to emulate the Windows SCM.

=head1 METHODS

=head2 init_service

Perform initialize for this mixin.

=head2 session_interrupt

Handle Unix signals and translate them into service events.

=head2 poll

Handle the services polling loop.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=item L<XAS::Lib::Service|XAS::Lib::Service>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
