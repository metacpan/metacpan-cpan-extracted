package XAS::Lib::Pipe;

our $VERSION = '0.01';

my $mixin;

BEGIN {
    $mixin = 'XAS::Lib::Pipe::Unix';
};

use POE;
use XAS::Lib::POE::PubSub;
  
use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::POE::Session',
  mixin     => $mixin,
  accessors => 'pipe event',
  utils     => ':validation trim dotid',
  vars => {
    PARAMS => {
      -fifo   => { isa => 'Badger::Filesystem::File' },
      -filter => { optional => 1, default => undef },
      -eol    => { optional => 1, default => "\n" },
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

    $poe_kernel->state('pipe_error',    $self, '_pipe_error');
    $poe_kernel->state('pipe_input',    $self, '_pipe_input');
    $poe_kernel->state('pipe_output',   $self, '_pipe_output');
    $poe_kernel->state('pipe_connect',  $self, '_pipe_connect');
    $poe_kernel->state('process_error', $self, '_process_error');
    $poe_kernel->state('process_input', $self, '_process_input');

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_initialize()");

}

sub process_input {
    my $self = shift;
    my ($input) = validate_params(\@_, [1]);

    my $alias = $self->alias;

    $self->log->debug("$alias: process_input()");

    $self->process_output($input);

}

sub process_error {
    my $self = shift;
    my ($syscall, $errnum, $errstr) = validate_params(\@_, [1,1,1]);

    my $alias = $self->alias;

    $self->log->debug("$alias: process_error()");

    $self->log->error_msg('net_client_error', $alias, $errnum, $errstr);

}

sub process_output {
    my $self = shift;
    my ($output) = validate_params(\@_, [1]);

    my $alias = $self->alias;

    $self->log->debug("$alias: process_output()");
    $poe_kernel->post($alias, 'pipe_output', $output);

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _process_input {
    my ($self, $input) = @_[OBJECT,ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: _process_input()");

    $self->process_input($input);

}

sub _process_error {
    my ($self, $syscall, $errnum, $errstr) = @_[OBJECT,ARG0..ARG2];

    my $alias = $self->alias;

    $self->log->debug("$alias: _process_error()");

    $self->process_error($syscall, $errnum, $errstr);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self  = $class->SUPER::init(@_);
    my $alias = $self->alias;

    $self->{'event'} = XAS::Lib::POE::PubSub->new();
    $self->event->subscribe($alias);

    $self->init_pipe();

    return $self;

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

 $client->run();

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

=head2 process_input($input)

This method will process the input from the pipe. It takes the
following parameters:

=over 4

=item B<$input>

The input received from the pipe.

=back

=head2 process_output($output)

This method will process the output for the pipe. It takes the
following parameters:

=over 4

=item B<$output>

The output to be sent to the pipe.

=back

=head2 process_error($syscall, $errnum, $errstr)

This method will process any errors from the pipe. It takes the
following parameters:

=over 4

=item B<$syscall>

The function that caused the error.

=item B<$errnum>

The OS error number.

=item B<$errstr>

The OS error string.

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
