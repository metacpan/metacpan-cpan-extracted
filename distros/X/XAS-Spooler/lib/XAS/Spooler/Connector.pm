package XAS::Spooler::Connector;

our $VERSION = '0.02';

use POE;
use Try::Tiny;
use XAS::Lib::POE::PubSub;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Lib::Stomp::POE::Client',
  accessors  => 'events',
  constants  => 'TRUE FALSE ARRAY',
  codec      => 'JSON',
  filesystem => 'File',
  vars => {
    PARAMS => {
      -hostname  => { optional => 1, default => undef },
    }
  }
;

#use Data::Dumper;

# ---------------------------------------------------------------------
# Public Events
# ---------------------------------------------------------------------

sub handle_receipt {
    my ($self, $frame) = @_[OBJECT, ARG0];

    my $alias = $self->alias;
    my ($palias, $filename) = split(';', $frame->header->receipt_id);

    $self->log->debug("$alias: alias = $palias, file = $filename");

    $poe_kernel->post($palias, 'unlink_file', $filename);

}

sub connection_down {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: entering connection_down()");

    $self->events->publish(
        -event => 'pause_processing'
    );

    $self->log->debug("$alias: leaving connection_down()");

}

sub connection_up {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: entering connection_up()");

    $self->events->publish(
        -event => 'resume_processing'
    );

    $self->log->debug("$alias: leaving connection_up()");

}

sub send_packet {
    my ($self, $palias, $type, $queue, $data, $file) = @_[OBJECT,ARG0..ARG4];

    my $alias = $self->alias;

    try {

        my $message = {
            hostname  => $self->hostname,
            timestamp => time(),
            type      => $type,
            data      => decode($data),
        };

        my $packet = encode($message);

        my $frame = $self->stomp->send(
            -destination => $queue, 
            -message     => $packet, 
            -receipt     => sprintf("%s;%s", $palias, $file->name),
            -persistent  => 'true'
        );

        $self->log->info("$alias: sending $file to $queue");

        $poe_kernel->call($alias, 'write_data', $frame);

    } catch {

        my $ex = $_;

        $self->log->error("$alias: unable to encode/decode packet, reason: $ex");
        $self->log->debug("$alias: alias = $palias, file = $file");

        $poe_kernel->post($palias, 'unlink_file', $file);

    };

}

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    $poe_kernel->state('send_packet', $self);

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_initialize()");

}

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    unless (defined($self->{'hostname'})) {

        $self->{'hostname'} = $self->env->host;

    }

    $self->{'events'} = XAS::Lib::POE::PubSub->new();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Spooler::Connector - Perl extension for the XAS environment

=head1 SYNOPSIS

  use XAS::Spooler::Connector;

  my $connection = XAS::Spooler::Connector->new(
      -alias           => 'connector',
      -host            => $hostname,
      -port            => $port,
      -retry_reconnect => TRUE,
      -tcp_keepalive   => TRUE,
      -hostname        => $env->host,
  );

=head1 DESCRIPTION

This module connects to a message queue server for spoolers. All of the spool
processors funnel messages thru this module. If the connection is lost to
the server, it signals the processor to stop processing until it is able to
reconnect to the server.

=head1 METHODS

=head2 new

This method inherits from L<XAS::Lib::Stomp::POE::Client|XAS::Lib::Stomp::POE::Client>
and takes these additional parameters:

=over

=item B<-hostname>

An optional name for the host that is processing these spool files.

=back

=head1 PUBLIC EVENTS

=head2 connection_down(OBJECT)

This event broadcasts that the connection had been dropped.

=over 4

=item B<OBJECT>

The handle for the current self.

=back

=head2 connection_up(OBJECT)

This event broadcasts when the connection is established.

=over 4

=item B<OBJECT>

The handle for the current self.

=back

=head2 send_packet(OBJECT,ARG0, ARG1, ARG2, ARG3, ARG4)

Process the data received from the processors. This processing includes
creating the standard message header, decoding the data and creating a
serialized message using JSON. This message is then sent to message queue
server.

=over 4

=item B<OBJECT>

The handle for the current self.

=item B<ARG0>

The alias of the processor.

=item B<ARG1>

The type of data.

=item B<ARG2>

The queue to send the message too.

=item B<ARG3>

The actual data to process. This is usually a JSON formated string.

=item B<ARG4>

The full qualified name of the file that was processed. This, along with
the processor alias, is used for the STOMP receipt.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Spooler::Processor|XAS::Spooler::Processor>

=item L<XAS::Spooler|XAS::Spooler>

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
