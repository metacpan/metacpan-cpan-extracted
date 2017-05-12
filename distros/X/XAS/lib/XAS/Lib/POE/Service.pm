package XAS::Lib::POE::Service;

our $VERSION = '0.03';

use POE;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Lib::POE::Session',
  vars => {
    PARAMS => {
      -alias => { optional => 1, default => 'service' }
    }
  }
;

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: session_initialize()");

    $poe_kernel->state('session_idle',   $self, '_session_idle');
    $poe_kernel->state('session_pause',  $self, '_session_pause');
    $poe_kernel->state('session_resume', $self, '_session_resume');
    $poe_kernel->state('session_status', $self, '_session_status');

    $poe_kernel->sig('HUP', 'session_interrupt');

}

sub session_idle {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: session_idle()");

}

sub session_pause {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: session_pause()");

}

sub session_resume {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: session_resume()");

}

sub session_status {
    my $self   = shift;
    my $status = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: session_status()");

    $self->{'__status'} = $status if (defined($status));

    return $self->{'__status'};

}

# ----------------------------------------------------------------------
# Public Accessors
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _session_init {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _session_init()");

    $self->session_initialize();

}

sub _session_idle {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: session_idle()");

    $self->session_idle();

}

sub _session_pause {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: session_pause()");

    $self->session_pause();

}

sub _session_resume {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _session_resume()");

    $self->session_resume();

}

sub _session_status {
    my ($self, $status) = @_[OBJECT, ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: _session_status()");

    $self->session_status($status);

}

1;

__END__

=head1 NAME

XAS::Lib::POE::Service - The base class for service sessions.

=head1 SYNOPSIS

 my $session = XAS::Lib::POE::Service->new(
     -alias => 'name',
 );

=head1 DESCRIPTION

This module inherits and extends L<XAS::Lib::POE::Session|XAS::Lib::POE::Session>.
It adds several more event types that can be signaled from registered 
sessions with L<XAS::Lib::Service|XAS::Lib::Service>.

The method session_initialize() is used to define this event types:

    session_idle
    session_pause
    session_resume
    session_status

While signal processing for HUP is not changed.

=head1 METHODS

=head2 session_idle

This mehod is called during the sessions idle time. The idle time is defined
in L<XAS::Lib::Service|XAS::Lib::Service>.

=head2 session_pause

This method is called when the service has been requested to pause processing.

=head2 session_resume

This method is called when the service has been requested to resume processing.

=head2 session_status

This method returns the status of the session.

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
