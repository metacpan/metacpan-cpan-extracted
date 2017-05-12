package XAS::Lib::Pipe::Unix;

our $VERSION = '0.01';

use POE;
use POE::Filter::Line;
use POE::Wheel::ReadWrite;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  utils   => 'trim dotid',
  mixins  => 'init_pipe _pipe_connect _pipe_input _pipe_output _pipe_error'
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _pipe_connect {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _pipe_connect()");

    # Start listening on the pipe.

    $self->{'pipe'} = POE::Wheel::ReadWrite->new(
        Handle     => $self->fifo->open('r+'),
        Filter     => $self->filter,
        InputEvent => 'pipe_input',
        ErrorEvent => 'pipe_error'
    );

}

sub _pipe_input {
    my ($self, $input) = @_[OBJECT,ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: _pipe_input()");

    $poe_kernel->post($alias, 'process_input', $input);

}

sub _pipe_output {
    my ($self, $output) = @_[OBJECT,ARG0];

    my @buffer;
    my $alias = $self->alias;

    $self->log->debug("$alias: _pipe_output()");

    if (my $wheel = $self->pipe) {

        push(@buffer, $output);
        $wheel->put(@buffer);

    } else {

        $self->log->error_msg('net_client_nowheel', $alias);

    }

}

sub _pipe_error {
    my ($self, $syscall, $errnum, $errstr) = @_[OBJECT,ARG0 .. ARG2];

    my $alias = $self->alias;

    $self->log->debug("$alias: _pipe_error()");
    $self->log->debug(sprintf("%s: syscall: %s, errnum: %s, errstr: %s", $alias, $syscall, $errnum, $errstr));

    if ($errnum == 0) {

        # EOF detected.

        $self->log->info_msg('net_client_disconnect', $alias, 'localhost', $self->fifo);

        $poe_kernel->post($alias, 'session_shutdown');

    } else {

        $poe_kernel->post($alias, 'process_error', $syscall, $errnum, $errstr);

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init_pipe {
    my $self = shift;

    my $alias  = $self->alias;
    my $mkfifo = '/usr/bin/mkfifo -m 666 ';

    unless (-p $self->fifo->path) {

        system($mkfifo . $self->fifo) && $self->throw_msg(
            dotid($self->class) . '.nofifo',
            'net_client_nocreate_fifo',
            $self->fifo, $!
        );

        $self->log->info_msg('net_client_create_fifo', $alias, $self->fifo);
      
    }

    unless (defined($self->filter)) {

        $self->{'filter'} = POE::Filter::Line->new(
            InputLiteral  => $self->eol,
            OutputLiteral => $self->eol
        );

    }

}

1;

__END__

=head1 NAME

XAS::Lib::Pipe - Interact with named pipes

=head1 SYNOPSIS

 use XAS::Lib::Pipe;

 my $client = XAS::Lib::Pipe->new(
     -fifo   => File('/var/lib/xas/pipe'),
     -filter => POE::Filter::Line->new(),
     -eol    => "\n",
 );

 $server->run();

=head1 DESCRIPTION

The module provides a POE based framework for reading and writing to named 
pipes. 

=head1 METHODS

=head2 new

This initializes the module and starts listening on the pipe. The following
parametrs are used:

=over 4

=item B<-alias>

The name of the POE session.

=item B<-fifo>

The name of the pipe to interact with.

=item B<-filter>

An optional filter to use, defaults to POE::Filter::Line

=item B<-eol>

An optional EOL, defaults to "\n";

=back

=head2 process_request($input)

This method will process the input from the client. It takes the
following parameters:

=over 4

=item B<$input>

The input received from the socket.

=back

=head2 process_response($output)

This method will process the output from the client. It takes the
following parameters:

=over 4

=item B<$output>

The output to be sent to the socket.

=back

=head2 process_errors($error)

This method will process the error output from the client. It takes the
following parameters:

=over 4

=item B<$error>

The output to be sent to the socket.

=back

=head1 SEE ALSO

=over 4

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
