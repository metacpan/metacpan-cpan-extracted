package XAS::Lib::Net::POE::Client;

our $VERSION = '0.02';

use POE;
use Try::Tiny;
use Socket ':all';
use Errno ':POSIX';
use POE::Filter::Line;
use POE::Wheel::ReadWrite;
use POE::Wheel::SocketFactory;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::POE::Service',
  mixin     => 'XAS::Lib::Mixins::Keepalive',
  accessors => 'wheel host port listener socket',
  mutators  => 'input_paused',
  utils     => 'dotid',
  vars => {
    PARAMS => {
      -port            => 1,
      -retry_reconnect => { optional => 1, default => 1 },
      -tcp_keepalive   => { optional => 1, default => 0 },
      -filter          => { optional => 1, default => undef },
      -alias           => { optional => 1, default => 'client' },
      -eol             => { optional => 1, default => "\015\012" },
      -host            => { optional => 1, default => 'localhost'},
    }
  }
;

our @ERRORS = (0, EPIPE, ETIMEDOUT, ECONNRESET, ECONNREFUSED, ENETUNREACH, ENETDOWN, ENETRESET);
our @RECONNECTIONS = (60, 120, 240, 480, 960, 1920, 3840);

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

    $self->log->debug("$alias: entering session_initialize()");

    # private events

    $self->log->debug("$alias: doing private events");

    # private events

    $poe_kernel->state('server_error',     $self, '_server_error');
    $poe_kernel->state('server_pause',     $self, '_server_pause');
    $poe_kernel->state('server_resume',    $self, '_server_resume');
    $poe_kernel->state('server_message',   $self, '_server_message');
    $poe_kernel->state('server_connect',   $self, '_server_connect');
    $poe_kernel->state('server_connected', $self, '_server_connected');
    $poe_kernel->state('server_reconnect', $self, '_server_reconnect');
    $poe_kernel->state('server_connection_failed', $self, '_server_connection_failed');

    # public events

    $self->log->debug("$alias: doing public events");

    $poe_kernel->state('read_data',         $self);
    $poe_kernel->state('write_data',        $self);
    $poe_kernel->state('connection_up',     $self);
    $poe_kernel->state('connection_down',   $self);
    $poe_kernel->state('handle_connection', $self);

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_initialize()");

}

sub session_startup {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_startup");

    $poe_kernel->post($alias, 'server_connect');

    # walk the chain

    $self->SUPER::session_startup();

    $self->log->debug("$alias: leaving session_startup");

}

sub session_shutdown {
    my $self = shift;
    
    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_shutdown");

    $self->{'socket'}   = undef;
    $self->{'wheel'}    = undef;
    $self->{'listener'} = undef;

    # walk the chain

    $self->SUPER::session_shutdown();

    $self->log->debug("$alias: leaving session_shutdown");
    
}

sub session_pause {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_pause");

    $poe_kernel->call($alias, 'connection_down');

    # walk the chain

    $self->SUPER::session_pause();

    $self->log->debug("$alias: leaving session_pause");

}

sub session_resume {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_resume");

    $poe_kernel->call($alias, 'connection_up');

    # walk the chain

    $self->SUPER::session_resume();

    $self->log->debug("$alias: leaving session_resume");

}

# ---------------------------------------------------------------------
# Public Events
# ---------------------------------------------------------------------

sub handle_connection {
    my ($self) = $_[OBJECT];

}

sub connection_down {
    my ($self) = $_[OBJECT];

}

sub connection_up {
    my ($self) = $_[OBJECT];

}

sub read_data {
    my ($self, $data) = @_[OBJECT, ARG0];

    my $alias = $self->alias;

    $poe_kernel->post($alias, 'write_data', $data);

}

sub write_data {
    my ($self, $data) = @_[OBJECT, ARG0];

    my @packet;
    my $alias = $self->alias;

    if (my $wheel = $self->wheel) {

        push(@packet, $data);
        $wheel->put(@packet);

    } else {

        $self->throw_msg(
            dotid($self->class) . '.write_data.nowheel',
            'net_server_nowheel',
            $alias
        );

    }

}

# ---------------------------------------------------------------------
# Private Events
# ---------------------------------------------------------------------

sub _server_message {
    my ($self, $data, $wheel_id) = @_[OBJECT, ARG0, ARG1];

    my $alias = $self->alias;

    $self->log->debug("$alias: _server_message()");

    $poe_kernel->post($alias, 'read_data', $data);

}

sub _server_connected {
    my ($self, $socket, $peeraddr, $peerport, $wheel_id) = @_[OBJECT,ARG0..ARG3];

    my $alias = $self->alias;

    $self->log->debug("$alias: _server_connected()");

    my $wheel = POE::Wheel::ReadWrite->new(
        Handle     => $socket,
        Filter     => $self->filter,
        InputEvent => 'server_message',
        ErrorEvent => 'server_error',
    );

    my $host = gethostbyaddr($peeraddr, AF_INET);

    $self->{'host'}     = $host;
    $self->{'port'}     = $peerport;
    $self->{'wheel'}    = $wheel;
    $self->{'socket'}   = $socket;
    $self->{'attempts'} = 0;

    $poe_kernel->post($alias, 'handle_connection');

}

sub _server_connect {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _server_connect()");

    $self->{'listner'} = POE::Wheel::SocketFactory->new(
        RemoteAddress  => $self->host,
        RemotePort     => $self->port,
        SocketType     => SOCK_STREAM,
        SocketDomain   => AF_INET,
        Reuse          => 'no',
        SocketProtocol => 'tcp',
        SuccessEvent   => 'server_connected',
        FailureEvent   => 'server_connection_failed',
    );

}

sub _server_connection_failed {
    my ($self, $operation, $errnum, $errstr, $wheel_id) = @_[OBJECT,ARG0..ARG3];

    my $alias = $self->alias;

    $self->log->debug("$alias: _server_connection_failed()");
    $self->log->error_msg('net_server_connection_failed', $alias, $operation, $errnum, $errstr);

    delete $self->{'socket'};
    delete $self->{'listner'};
    delete $self->{'wheel'};

    foreach my $error (@ERRORS) {

        if ($errnum == $error) {

            $poe_kernel->post($alias, 'server_reconnect');
            last;

        }

    }

}

sub _server_error {
    my ($self, $operation, $errnum, $errstr, $wheel_id) = @_[OBJECT,ARG0..ARG3];

    my $alias = $self->alias;

    $self->log->debug("$alias: _server_error()");
    $self->log->error_msg('net_server_error', $alias, $operation, $errnum, $errstr);

    delete $self->{'socket'};
    delete $self->{'listner'};
    delete $self->{'wheel'};

    $poe_kernel->post($alias, 'connection_down');

    foreach my $error (@ERRORS) {

        if ($errnum == $error) {

            $poe_kernel->post($alias, 'server_reconnect');
            last;

        }

    }

}

sub _server_reconnect {
    my ($self) = $_[OBJECT];

    my $retry;
    my $alias = $self->alias;

    $self->log->warn_msg('net_server_reconnect', $alias, $self->{'attempts'}, $self->{'count'});

    if ($self->{'attempts'} < $self->{'count'}) {

        my $delay = $RECONNECTIONS[$self->{'attempts'}];
        $self->log->warn_msg('net_server_attempts', $alias, $self->{'attempts'}, $delay);
        $self->{'attempts'} += 1;
        $poe_kernel->delay('server_connect', $delay);

    } else {

        $retry = $self->retry_reconnect || 0;

        if ($retry) {

            $self->log->warn_msg('net_server_recycle', $alias);
            $self->{'attempts'} = 0;
            $poe_kernel->post($alias, 'server_connect');

        } else {

            $self->log->warn_msg('net_server_shutdown', $alias);
            $poe_kernel->post($alias, 'session_shutdown');

        }

    }

}

sub _server_pause {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _server_pause()");

    if (my $wheel = $self->wheel) {

        $wheel->pause_input();
        $self->input_paused(1);

        $self->log->debug("$alias: _server_resume() - input paused");

    }

}

sub _server_resume {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: _server_resume()");

    if ($self->input_paused) {

        if (my $wheel = $self->wheel) {

            $wheel->resume_input();
            $self->input_paused(0);

            $self->log->debug("$alias: _server_resume() - input resumed");
   
        }

    }

}

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'attempts'} = 0;
    $self->{'input_paused'} = 0;
    $self->{'count'} = scalar(@RECONNECTIONS);

    unless (defined($self->{'filter'})) {

        $self->{'filter'} = POE::Filter::Line->new(
            InputLiteral  => $self->eol,
            OutputLiteral => $self->eol,
        );

    }

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Net::POE::Client - An asynchronous network client based on POE

=head1 SYNOPSIS

This module is a class used to create network clients.

 package Client;

 use POE;
 use XAS::Class
   version => '1.0',
   base    => 'XAS::Lib::Net::POE::Client'
 ;

 sub handle_connection {
    my ($self) = $_[OBJECT];

    my $packet = "hello!";

    $poe_kernel->yield('write_data', $packet);

 }

=head1 DESCRIPTION

This module handles the nitty-gritty details of setting up the communications
channel to a server. You will need to sub-class this module with your own for
it to be useful.

An attempt to maintain that channel will be made when/if that server should
happen to disappear off the network. There is nothing more unpleasant then
having to go around to dozens of servers and restarting processes.

The following methods are responding to POE events and use the POE argument
passing conventions.

=head1 METHODS

=head2 new

This method initializes the class and starts a session to handle the
communications channel. It takes the following parameters:

=over 4

=item B<-alias>

The session alias, defaults to 'client'.

=item B<-host>

The servers host name, defaults to 'localhost'.

=item B<-port>

The servers port number.

=item B<-retry_count>

Wither to attempt reconnections after they run out. Defaults to true.

=item B<-tcp_keepalive>

For those pesky firewalls, defaults to false.

=back

=head2 read_data(OBJECT, ARG0)

This event is triggered when data is received for the server. It accepts
these parameters:

=over 4

=item B<OBJECT>

The current class object.

=item B<ARG0>

The data that has been read.

=back

=head2 write_data(OBJECT, ARG0)

You use this event to send data to the server. It accepts
these parameters:

=over 4

=item B<OBJECT>

The current class object.

=item B<ARGO>

The data to write out.

=back

=head2 handle_connection(OBJECT)

This event is triggered upon initial connection to the server. It accepts
these parameters:

=over 4

=item B<OBJECT>

The current class object.

=back

=head2 connection_down(OBJECT)

This event is triggered to allow you to be notified if the connection to 
the server is currently down. It accepts
these parameters:

=over 4

=item B<OBJECT>

The current class object.

=back

=head2 connection_up(OBJECT)

This event is triggered to allow you to be notified when the connection
to the server is restored. It accepts
these parameters:

=over 4

=item B<OBJECT>

The current class object.

=back

=head1 VARIABLES

The following class variables are available if you want to adjust them.

=over 4

=item B<ERRORS>

An array of POSIX error codes. 

=item B<RECONNECTIONS>

An array of seconds to wait for the next reconnect attempt.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::Net::Client|XAS::Lib::Net::Client>

=item L<XAS::Lib::Net::Server|XAS::Lib::Net::Server>

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
