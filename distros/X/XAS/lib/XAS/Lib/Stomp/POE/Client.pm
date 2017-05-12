package XAS::Lib::Stomp::POE::Client;

our $VERSION = '0.04';

use POE;
use Try::Tiny;
use XAS::Lib::Stomp::Utils;
use XAS::Lib::Stomp::POE::Filter;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Net::POE::Client',
  mixins    => 'XAS::Lib::Mixins::Keepalive',
  utils     => 'trim',
  accessors => 'stomp',
  vars => {
    PARAMS => {
      -host     => { optional => 1, default => undef },
      -port     => { optional => 1, default => undef },
      -alias    => { optional => 1, default => 'stomp-client' },
      -login    => { optional => 1, default => 'guest' },
      -passcode => { optional => 1, default => 'guest' },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: session_initialize()");

    # public events

    $self->log->debug("$alias: doing public events");

    $poe_kernel->state('handle_noop',      $self);
    $poe_kernel->state('handle_error',     $self);
    $poe_kernel->state('handle_message',   $self);
    $poe_kernel->state('handle_receipt',   $self);
    $poe_kernel->state('handle_connected', $self);

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_initialize()");

}

sub session_shutdown {
    my $self = shift;

    my $alias = $self->alias;
    my $frame = $self->stomp->disconnect(
        -receipt => 'disconnecting'
    );

    $self->log->debug("$alias: entering session_shutdown()");

    $poe_kernel->call($alias, 'write_data', $frame);

    # walk the chain

    $self->SUPER::session_shutdown();

    $self->log->debug("$alias: leaving session_shutdown()");

}

# ---------------------------------------------------------------------
# Public Events
# ---------------------------------------------------------------------

sub handle_connection {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;
    my $frame = $self->stomp->connect(
        -login    => $self->login,
        -passcode => $self->passcode
    );

    $self->log->debug("$alias: entering handle_connection()");

    $poe_kernel->post($alias, 'write_data', $frame);

    $self->log->debug("$alias: leaving handle_connection()");

}

sub handle_connected {
    my ($self, $frame) = @_[OBJECT, ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: entering handle_connected()");

    if ($self->tcp_keepalive) {

        $self->log->info_msg('tcp_keepalive_enabled', $alias);

        $self->init_keepalive();
        $self->enable_keepalive($self->socket);

    }

    $self->log->info_msg('net_server_connected', $alias, $self->host, $self->port);

    $poe_kernel->post($alias, 'connection_up');

    $self->log->debug("$alias: leaving handle_connected()");

}

sub handle_message {
    my ($self, $frame) = @_[OBJECT, ARG0];

}

sub handle_receipt {
    my ($self, $frame) = @_[OBJECT, ARG0];

}

sub handle_error {
    my ($self, $frame) = @_[OBJECT, ARG0];

    my $message = '';
    my $message_id = '';
    my $alias = $self->alias;

    if ($frame->header->methods->has('message_id')) {

        $message_id = $frame->header->message_id;

    }

    if ($frame->header->methods->has('message')) {

        $message = $frame->header->message;

    }

    $self->log->error_msg('stomp_errors',
        $alias,
        trim($message_id),
        trim($message),
        trim($frame->body)
    );

}

sub handle_noop {
    my ($self, $frame) = @_[OBJECT, ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: handle_noop()");

}

# ---------------------------------------------------------------------
# Private Events
# ---------------------------------------------------------------------

sub _server_message {
    my ($self, $frame, $wheel_id) = @_[OBJECT, ARG0, ARG1];

    my $alias = $self->alias;

    $self->log->debug("$alias: entering _server_message()");

    if ($frame->command eq 'CONNECTED') {

        $self->log->debug("$alias: received a \"CONNECTED\" message");
        $poe_kernel->post($alias, 'handle_connected', $frame);

    } elsif ($frame->command eq 'MESSAGE') {

        $self->log->debug("$alias: received a \"MESSAGE\" message");
        $poe_kernel->post($alias, 'handle_message', $frame);

    } elsif ($frame->command eq 'RECEIPT') {

        $self->log->debug("$alias: received a \"RECEIPT\" message");
        $poe_kernel->post($alias, 'handle_receipt', $frame);

    } elsif ($frame->command eq 'ERROR') {

        $self->log->debug("$alias: received an \"ERROR\" message");
        $poe_kernel->post($alias, 'handle_error', $frame);

    } elsif ($frame->command eq 'NOOP') {

        $self->log->debug("$alias: received an \"NOOP\" message");
        $poe_kernel->post($alias, 'handle_noop', $frame);

    } else {

        $self->log->warn_msg('stomp_unknown_type', $alias, $frame->command);

    }

    $self->log->debug("$alias: leaving _server_message()");

}

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    unless (defined($self->{'host'})) {

        $self->{'host'} = $self->env->mqserver;

    }

    unless (defined($self->{'port'})) {

        $self->{'port'} = $self->env->mqport;

    }

    $self->{'stomp'}  = XAS::Lib::Stomp::Utils->new();
    $self->{'filter'} = XAS::Lib::Stomp::POE::Filter->new();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Stomp::POE::Client - A STOMP client for the POE Environment

=head1 SYNOPSIS

This module is a class used to create clients that need to access a 
message server that communicates with the STOMP protocol. Your program could 
look as follows:

 package Client;

 use POE;
 use XAS::Class
   version => '1.0',
   base    => 'XAS::Lib::Stomp::POE::Client',
 ;

 package main;

 use POE;
 use strict;

 Client->new(
    -alias => 'testing',
    -queue => '/queue/testing',
 );

 $poe_kernel->run();

 exit 0;

=head1 DESCRIPTION

This module handles the nitty-gritty details of setting up the communications 
channel to a message queue server. You will need to sub-class this module
with your own for it to be useful.

When messages are received, specific events are generated. Those events are 
based on the message type. If you are interested in those events you should 
override the default behavior for those events. The default behavior is to 
do nothing. This module inherits from L<XAS::Lib::Net::POE::Client|XAS::Lib::Net::POE::Client>.

=head1 METHODS

=head2 new

This method initializes the class and starts a session to handle the 
communications channel. It takes the following additional parameters:

=over 4

=item B<-alias>

Sets the alias for this client, defaults to 'stomp-client'.

=item B<-host>

Sets the host to attach too. defaults to 'localhost'.

=item B<-port>

Sets the port to use, defaults to 61613.

=item B<-login>

Sets the login name for this server, defaults to 'guest'.

=item B<-passcode>

Sets the passcode for this server, defaults to 'guest'.

=back

=head2 handle_connection(OBJECT)

This event is signaled and the corresponding method is called upon initial 
connection to the message server. I accepts these parameters:

=over 4

=item B<OBJECT>

The current class object.

=back

=head2 handle_connected(OBJECT, ARG0)

This event and corresponding method is called when a "CONNECT" frame is 
received from the server. It posts the frame to the 'connection_up' event.
It accepts these parameters:

=over 4

=item B<OBJECT>

The current class object.

=item B<ARG0>

The current STOMP frame.

=back

=head2 handle_message(OBJECT, ARG0)

This event and corresponding method is used to process "MESSAGE" frames. 

It accepts these parameters:

=over 4

=item B<OBJECT>

The current class object.

=item B<ARG0>

The current STOMP frame.

=back

 Example

    sub handle_message {
        my ($self, $frame) = @_[OBJECT,ARG0];
 
        my $nframe = $self->stomp->ack(
            -message_id => $frame->header->message_id
        );

        $poe_kernel->yield('write_data', $nframe);

    }

This example really doesn't do much other then "ack" the messages that are
received. 

=head2 handle_receipt(OBJECT, ARG0)

This event and corresponding method is used to process "RECEIPT" frames. 
It accepts these parameters:

=over 4

=item B<OBJECT>

The current class object.

=item B<ARG0>

The current STOMP frame.

=back

 Example

    sub handle_receipt {
        my ($self, $frame) = @_[OBJECT,ARG0];

        my $receipt = $frame->header->receipt;

    }

This example really doesn't do much, and you really don't need to worry about
receipts unless you ask for one when you send a frame to the server. So this 
method could be safely left with the default.

=head2 handle_error(OBJECT, ARG0)

This event and corresponding method is used to process "ERROR" frames. 
It accepts these parameters:

=over 4

=item B<OBJECT>

The current class object.

=item B<ARG0>

The current STOMP frame.

=back

=head2 handle_noop(OBJECT, ARG0)

This event and corresponding method is used to process "NOOP" frames. 
It accepts these parameters:

=over 4

=item B<OBJECT>

The current class object.

=item B<ARG0>

The current STOMP frame.

=back

=head1 ACCESSORS

=head2 stomp

This returns an object to the internal L<XAS::Lib::Stomp::Utils|XAS::Lib::Stomp::Utils>
object. This is very useful for creating STOMP frames.

 Example

    $frame = $self->stomp->connect(
         -login    => 'testing',
         -passcode => 'testing'
    );

    $poe_kernel->yield('write_data', $frame);

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

For details on the protocol see L<http://stomp.github.io/>.

=head1 AUTHOR

Kevin L. Esteb, E<lt>=[@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
