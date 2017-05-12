package XAS::Lib::SSH::Server;

our $VERSION = '0.01';

use POE;
use POE::Filter::Line;
use POE::Wheel::ReadWrite;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::POE::Session',
  accessors => 'client peerhost peerport',
  utils     => ':validation trim',
  vars => {
    PARAMS => {
      -filter => { optional => 1, default => undef },
      -eol    => { optional => 1, default => "\015\012" },
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

    # public events

    # private events

    $poe_kernel->state('client_error',      $self, '_client_error');
    $poe_kernel->state('client_input',      $self, '_client_input');
    $poe_kernel->state('client_output',     $self, '_client_output');
    $poe_kernel->state('client_connection', $self, '_client_connection');

    $poe_kernel->state('process_errors',    $self, '_process_errors');
    $poe_kernel->state('process_request',   $self, '_process_request');
    $poe_kernel->state('process_response',  $self, '_process_response');
    $poe_kernel->state('handle_connection', $self, '_handle_connection');

    # Find the remote host and port.

    my ($rhost, $rport, $lhost, $lport) = split(' ', $ENV{'SSH_CONNECTION'});

    $self->{'peerhost'} = $rhost;
    $self->{'peerport'} = $rport;

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_initialize()");

}

sub session_startup {
    my $self = shift;

    my $alias = $self->alias;

    # start listening for connections

    $self->log->debug("$alias: entering session_startup()");

    $poe_kernel->post($alias, 'client_connection');

    # walk the chain

    $self->SUPER::session_startup();

    $self->log->debug("$alias: leaving session_startup()");

}

sub process_request {
    my $self = shift;
    my ($input, $ctx) = validate_params(\@_, [1,1]);

    return $input;

}

sub process_response {
    my $self = shift;
    my ($output, $ctx) = validate_params(\@_, [1,1]);

    return $output;

}

sub process_errors {
    my $self = shift;
    my ($output, $ctx) = validate_params(\@_, [1,1]);

    return $output;

}

sub handle_connection {
    my $self = shift;
    my ($wheel) = validate_params(\@_, [1]);

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _process_request {
    my ($self, $input, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my $data  = $self->process_request($input, $ctx);

    $self->log->debug("$alias: process_request()");
    $poe_kernel->post($alias, 'process_response', $data, $ctx);

}

sub _process_response {
    my ($self, $output, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my $data  = $self->process_response($output, $ctx);

    $self->log->debug("$alias: process_response()");
    $poe_kernel->post($alias, 'client_output', $data, $ctx);

}

sub _process_errors {
    my ($self, $output, $ctx) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my $data  = $self->process_errors($output, $ctx);

    $self->log->debug("$alias: process_errors()");
    $poe_kernel->post($alias, 'client_output', $data, $ctx);

}

sub _handle_connection {
    my ($self, $wheel) = @_[OBJECT,ARG0];
    
    my $alias = $self->alias;

    $self->log->debug("$alias: handle_connection()");
    $self->handle_connection($wheel);

}

sub _client_connection {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _client_connection()");

    # Start listening on stdin.

    $self->{'client'} = POE::Wheel::ReadWrite->new(
        InputHandle  => \*STDIN,
        OutputHandle => \*STDOUT,
        Filter       => $self->filter,
        InputEvent   => 'client_input',
        ErrorEvent   => 'client_error'
    );

    $poe_kernel->post($alias, 'handle_connection', $self->client->ID);

}

sub _client_input {
    my ($self, $input, $wheel) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my $ctx = {
        wheel => $wheel
    };

    $self->log->debug("$alias: _client_input()");

    $poe_kernel->post($alias, 'process_request', $input, $ctx);

}

sub _client_output {
    my ($self, $output, $ctx) = @_[OBJECT,ARG0,ARG1];

    my @buffer;
    my $alias = $self->alias;

    $self->log->debug("$alias: _client_output()");

    if (my $wheel = $self->client) {

        push(@buffer, $output);
        $wheel->put(@buffer);

    } else {

        $self->log->error_msg('net_server_nowheel', $alias);

    }

}

sub _client_error {
    my ($self, $syscall, $errnum, $errstr, $wheel) = @_[OBJECT,ARG0 .. ARG3];

    my $alias = $self->alias;

    $self->log->debug("$alias: _client_error()");
    $self->log->debug(sprintf("%s: syscall: %s, errnum: %s, errstr: %s", $alias, $syscall, $errnum, $errstr));

    if ($errnum == 0) {

        # EOF detected.

        $self->log->info_msg('net_server_disconnect', $alias, $self->peerhost, $self->peerport);

        delete $self->{'client'};
        $poe_kernel->post($alias, 'session_shutdown');

    } else {

        $self->log->error_msg('net_server_error', $alias, $errnum, $errstr);

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    unless (defined($self->filter)) {

        $self->{'filter'} = POE::Filter::Line->new(
            InputLiteral  => $self->eol,
            OutputLiteral => $self->eol
        );

    }

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::SSH::Server - A SSH Subsystem based server

=head1 SYNOPSIS

 use XAS::Lib::SSH::Server;

 my $server = XAS::Lib::SSH::Server->new(
     -filter => POE::Filter::Line->new(),
     -eol    => "\015\012",
 );

 $server->run();

=head1 DESCRIPTION

The module provides a POE based framework for a SSH subsystem. A SSH subsystem
reads from stdin, writes to stdout or stderr. This modules emulates 
L<XAS::Lib::Net::Server|XAS::Lib::Net::Server> to provide a consistent 
interface.

=head1 METHODS

=head2 new

This initializes the module and starts listening for requests. The following
parametrs are used:

=over 4

=item B<-alias>

The name of the POE session.

=item B<-filter>

An optional filter to use, defaults to POE::Filter::Line

=item B<-eol>

An optional EOL, defaults to "\015\012";

=back

=head2 process_request($input, $ctx)

This method will process the input from the client. It takes the
following parameters:

=over 4

=item B<$input>

The input received from the socket.

=item B<$ctx>

A hash variable to maintain context. This will be initialized with a "wheel"
field. Others fields may be added as needed.

=back

=head2 process_response($output, $ctx)

This method will process the output from the client. It takes the
following parameters:

=over 4

=item B<$output>

The output to be sent to the socket.

=item B<$ctx>

A hash variable to maintain context. This uses the "wheel" field to direct output
to the correct socket. Others fields may have been added as needed.

=back

=head2 process_errors($error, $ctx)

This method will process the error output from the client. It takes the
following parameters:

=over 4

=item B<$error>

The output to be sent to the socket.

=item B<$ctx>

A hash variable to maintain context. This uses the "wheel" field to direct output
to the correct socket. Others fields may have been added as needed.

=back

=head2 handle_connection($wheel)

This method is called after the client has connected. This is for additional
post connection processing as needed. It takes the following parameters:

=over 4

=item B<$wheel>

The id of the clients wheel.

=back

=head1 ACCESSORS

=head2 peerport

This returns the peers port number.

=head2 peerhost

This returns the peers host name.

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::SSH::Client|XAS::Lib::SSH::Client>

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
