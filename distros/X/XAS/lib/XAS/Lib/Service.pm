package XAS::Lib::Service;

our $VERSION = '0.04';

use POE;

my ($mixin, $shutdown);

BEGIN {

    if ($^O eq 'MSWin32') {

        $mixin = 'XAS::Lib::Service::Win32';
        $shutdown = 25;

    } else {
   
        $mixin = 'XAS::Lib::Service::Unix';
        $shutdown = 2;

    }

}

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::POE::Session',
  utils     => ':validation',
  mixin     => $mixin,
  accessors => 'sessions',
  mutators  => 'last_state',
  constants => 'DELIMITER',
  vars => {
    PARAMS => {
      -poll_interval     => { optional => 1, default => 2 },
      -shutdown_interval => { optional => 1, default => $shutdown },
      -alias             => { optional => 1, default => 'services' },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub register {
    my $self = shift;
    my ($sessions) = validate_params(\@_, [
        (0) x (@_)
    ]);

    if (ref($sessions) eq 'ARRAYREF') {

        foreach my $session (@$sessions) {

            next if ($session eq '');
            push(@{$self->{'sessions'}}, $session);

        }

    } else {

        my @parts = split(DELIMITER, $sessions);

        foreach my $session (@parts) {

            next if ($session eq '');
            push(@{$self->{'sessions'}}, $session);

        }

    }

}

sub unregister {
    my $self = shift;
    my $session = shift;

    my @sessions = grep { $_ ne $session } @{$self->{'sessions'}};
    $self->{'sessions'} = \@sessions;

}

sub session_shutdown {
    my $self = shift;

    $poe_kernel->delay('poll');
    $self->SUPER::session_shutdown();

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _session_init {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _session_init()");

    $poe_kernel->state('poll', $self);

    $self->last_state(SERVICE_START_PENDING);
    $self->_current_state(SERVICE_START_PENDING);

    $self->init_service();
    $self->session_initialize();

    $poe_kernel->post($alias, 'poll');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    $poe_kernel->run(); # this only initializes POE

    my $self = $class->SUPER::init(@_);

    $self->{'sessions'} = ();

    return $self;

}

sub _service_startup {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: _service_startup");

    foreach my $session (@{$self->{'sessions'}}) {

        $poe_kernel->post($session, 'session_startup');

    }

}

sub _service_shutdown {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: _service_shutdown");

    foreach my $session (@{$self->{'sessions'}}) {

        $poe_kernel->post($session, 'session_shutdown');

    }

}

sub _service_idle {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: _service_idle");

    foreach my $session (@{$self->{'sessions'}}) {

        $poe_kernel->post($session, 'session_idle');

    }

}

sub _service_paused {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: _service_paused");

    foreach my $session (@{$self->{'sessions'}}) {

        $poe_kernel->post($session, 'session_pause');

    }

}

sub _service_resumed {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: _service_resumed");

    foreach my $session (@{$self->{'sessions'}}) {

        $poe_kernel->post($session, 'session_resume');

    }

}

1;

__END__

=head1 NAME

XAS::Lib::Service - A class to interact with Services

=head1 SYNOPSIS

 use XAS::Lib::Service;

 my $service = XAS::Lib::Service->new(
    -alias             => 'service',
    -poll_interval     => 2,
    -shutdown_interval => 25
 );

 $service->run();

=head1 DESCRIPTION

This module provides a generic interface to "Services". A Service is
a managed background process. It responds to external events. On Windows
this would be responding to commands from the SCM. On Unix this would 
be responding to a special set of signals. This module provides an 
event loop that can interact those external events. The module 
L<XAS::Lib::POE::Service|XAS::Lib::POE::Service> can interact with 
this event loop.

=head1 METHODS

=head2 new()

This method is used to initialize the service. This module inherits from
L<XAS::Lib::POE::Session|XAS::Lib::POE::Session>. It takes the following
parameters:

=over 4

=item B<-alias>

The name of this POE session. Defaults to 'service';

=item B<-poll_interval>

This is the interval were the SCM sends SERVICE_RUNNING message. The
default is every 2 seconds.

=item B<-shutdown_interval>

This is the interval to pause the system shutdown so that the service
can cleanup after itself. The default is 25 seconds.

=back

=head2 register($session)

This allows your process to register whatever modules you want events sent too.

=over 4

=item B<$session>

This can be an array reference or a text string. The text string may be 
delimited with commas. This will be the POE alias for each session.

=back

=head1 EVENTS

When an external event happens this module will trap it and generate a POE 
event. These events follow closely the model defined by the Windows Service 
Control Manager interface. The event is then sent to all interested modules. 
The following POE events have been defined:

=head2 session_startup

This is fired when your process starts up and is used to initialize what ever
processing you are going to do. On a network server, this may be opening a
port to listen on.

=head2 session_shutdown

This is fired when your process is shutting down. 

=head2 session_pause

This is fired when your process needs to "pause".

=head2 session_resume

This is fired when your process needs to "resume".

=head2 session_idle

This is fired at every poll_interval.

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::Service::Unix|XAS::Lib::Service::Unix>

=item L<XAS::Lib::Service::Win32|XAS::Lib::Service::Win32>

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
