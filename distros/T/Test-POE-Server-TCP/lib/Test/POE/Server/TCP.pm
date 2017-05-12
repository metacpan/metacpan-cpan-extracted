package Test::POE::Server::TCP;
$Test::POE::Server::TCP::VERSION = '1.20';
# ABSTRACT: A POE Component providing TCP server services for test cases

use strict;
use warnings;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::Line);
use Socket;
use Carp qw(carp croak);

our $GOT_SOCKET6;

BEGIN {
    eval {
        Socket->import(qw(AF_INET6 IN6ADDR_ANY NI_NUMERICHOST NI_NUMERICSERV getnameinfo));
        $GOT_SOCKET6 = 1;
    };
    if (!$GOT_SOCKET6) {
       # provide a dummy subs so code compiles
       *AF_INET6 = sub { ~0 };
       *IN6ADDR_ANY = sub { ~0 };
    }
}

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $options = delete $opts{options};
  my $self = bless \%opts, $package;
  $self->{_prefix} = delete $self->{prefix};
  $self->{_prefix} = 'testd_' unless defined $self->{_prefix};
  $self->{_prefix} .= '_' unless $self->{_prefix} =~ /\_$/;
  $self->{session_id} = POE::Session->create(
	object_states => [
	   $self => { shutdown      => '_shutdown',
		      send_event          => '__send_event',
		      send_to_client      => '_send_to_client',
		      send_to_all_clients => '_send_to_all_clients',
		      disconnect          => '_disconnect',
		      terminate           => '_terminate',
          start_listener      => '_start_listener',
	            },
	   $self => [ qw(_start register unregister _accept_client _conn_input _conn_error _conn_flushed _conn_alarm
                _send_to_client __send_event _disconnect _send_to_all_clients _accept_failed4 _accept_failed6) ],
	],
	heap => $self,
	( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub pause_listening {
  $_[0]->{listener}->pause_accept() if $_[0]->{listener};
  $_[0]->{listener6}->pause_accept() if $_[0]->{listener6};
}

sub resume_listening {
  $_[0]->{listener}->resume_accept() if $_[0]->{listener};
  $_[0]->{listener6}->resume_accept() if $_[0]->{listener6};
}

sub getsockname {
  return unless $_[0]->{listener};
  return $_[0]->{listener}->getsockname();
}

sub port {
  my $self = shift;
  return ( sockaddr_in( $self->getsockname() ) )[0];
}

sub getsockname6 {
  return unless $_[0]->{listener6};
  return $_[0]->{listener6}->getsockname();
}

sub port6 {
  my $self = shift;
  return ( sockaddr_in6( $self->getsockname6() ) )[0];
}

sub _conn_exists {
  my ($self,$wheel_id) = @_;
  return 0 unless $wheel_id and defined $self->{clients}->{ $wheel_id };
  return 1;
}

sub shutdown {
  my $self = shift;
  $poe_kernel->call( $self->{session_id}, 'shutdown' );
}

sub _start {
  my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,SENDER];
  $self->{session_id} = $_[SESSION]->ID();
  if ( $self->{alias} ) {
	$kernel->alias_set( $self->{alias} );
  }
  else {
	$kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
  }
  if ( $kernel != $sender ) {
    my $sender_id = $sender->ID;
    $self->{events}->{$self->{_prefix} . 'all'}->{$sender_id} = $sender_id;
    $self->{sessions}->{$sender_id}->{'ref'} = $sender_id;
    $self->{sessions}->{$sender_id}->{'refcnt'}++;
    $kernel->refcount_increment($sender_id, __PACKAGE__);
    $kernel->post( $sender, $self->{_prefix} . 'registered', $self );
    $kernel->detach_myself();
  }

  $kernel->call( $self->{session_id}, 'start_listener' );
  return;
}

sub start_listener {
  my $self = shift;
  $poe_kernel->call( $self->{session_id}, 'start_listener', @_ );
}

sub _start_listener {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  return if $self->{listener};

  $self->{listener} = POE::Wheel::SocketFactory->new(
      ( defined $self->{address} ? ( BindAddress => $self->{address} ) : () ),
      ( defined $self->{port} ? ( BindPort => $self->{port} ) : ( BindPort => 0 ) ),
      SuccessEvent   => '_accept_client',
      FailureEvent   => '_accept_failed4',
      SocketDomain   => AF_INET,             # Sets the socket() domain
      SocketType     => SOCK_STREAM,         # Sets the socket() type
      SocketProtocol => 'tcp',               # Sets the socket() protocol
      Reuse          => 'on',                # Lets the port be reused
  );

  return unless $GOT_SOCKET6;

  $self->{listener6} = POE::Wheel::SocketFactory->new(
      #BindAddress => IN6ADDR_ANY,
      ( defined $self->{port} ? ( BindPort => $self->{port} ) : ( BindPort => 0 ) ),
      SuccessEvent   => '_accept_client',
      FailureEvent   => '_accept_failed6',
      SocketDomain   => AF_INET6,            # Sets the socket() domain
      SocketType     => SOCK_STREAM,         # Sets the socket() type
      SocketProtocol => 'tcp',               # Sets the socket() protocol
      Reuse          => 'on',                # Lets the port be reused
  );

  return;
}

sub _accept_client {
  my ($kernel,$self,$socket,$listener_id) = @_[KERNEL,OBJECT,ARG0,ARG3];

  my (undef,$peeraddr,$peerport) = getnameinfo( CORE::getpeername( $socket ), NI_NUMERICHOST | NI_NUMERICSERV );
  my (undef,$sockaddr,$sockport) = getnameinfo( CORE::getsockname( $socket ), NI_NUMERICHOST | NI_NUMERICSERV );

  s!^::ffff:!! for ( $sockaddr, $peeraddr );

  my $wheel = POE::Wheel::ReadWrite->new(
	Handle => $socket,
	_get_filters(
                  $self->{filter},
                  $self->{inputfilter},
                  $self->{outputfilter}
        ),
	InputEvent => '_conn_input',
	ErrorEvent => '_conn_error',
	FlushedEvent => '_conn_flushed',
  );

  return unless $wheel;

  my $id = $wheel->ID();
  $self->{clients}->{ $id } =
  {
				wheel    => $wheel,
				peeraddr => $peeraddr,
				peerport => $peerport,
				sockaddr => $sockaddr,
				sockport => $sockport,
  };
  $self->_send_event( $self->{_prefix} . 'connected', $id, $peeraddr, $peerport, $sockaddr, $sockport );

  #$self->{clients}->{ $id }->{alarm} = $kernel->delay_set( '_conn_alarm', $self->{time_out} || 300, $id );
  return;
}

sub client_info {
  my $self = shift;
  my $id = shift || return;
  return unless $self->_conn_exists( $id );
  my %hash = %{ $self->{clients}->{ $id } };
  delete $hash{wheel};
  return map { $hash{$_} } qw(peeraddr peerport sockaddr sockport) if wantarray;
  return \%hash;
}

sub client_wheel {
  my $self = shift;
  my $id = shift || return;
  return unless $self->_conn_exists( $id );
  return $self->{clients}->{ $id }->{wheel};
}

sub _get_filters {
    my ($client_filter, $client_infilter, $client_outfilter) = @_;
    if (defined $client_infilter or defined $client_outfilter) {
      return (
        "InputFilter"  => _load_filter($client_infilter),
        "OutputFilter" => _load_filter($client_outfilter)
      );
      if (defined $client_filter) {
        carp(
          "Filter ignored with InputFilter or OutputFilter"
        );
      }
    }
    elsif (defined $client_filter) {
     return ( "Filter" => _load_filter($client_filter) );
    }
    else {
      return ( Filter => POE::Filter::Line->new(), );
    }

}

# Get something: either arrayref, ref, or string
# Return filter
sub _load_filter {
    my $filter = shift;
    if (ref ($filter) eq 'ARRAY') {
        my @args = @$filter;
        $filter = shift @args;
        if ( _test_filter($filter) ){
            return $filter->new(@args);
        } else {
            return POE::Filter::Line->new(@args);
        }
    }
    elsif (ref $filter) {
        return $filter->clone();
    }
    else {
        if ( _test_filter($filter) ) {
            return $filter->new();
        } else {
            return POE::Filter::Line->new();
        }
    }
}

# Test if a Filter can be loaded, return sucess or failure
sub _test_filter {
    my $filter = shift;
    my $eval = eval {
        (my $mod = $filter) =~ s!::!/!g;
        require "$mod.pm";
        1;
    };
    if (!$eval and $@) {
        carp(
          "Failed to load [$filter]\n" .
          "Reason $@\nUsing defualt POE::Filter::Line "
        );
        return 0;
    }
    return 1;
}

sub _accept_failed4 {
  my ($kernel,$self,$operation,$errnum,$errstr,$wheel_id) = @_[KERNEL,OBJECT,ARG0..ARG3];
  warn "Wheel $wheel_id generated $operation error $errnum: $errstr\n";
  delete $self->{listener} if $operation eq 'listen';
  $self->_send_event( $self->{_prefix} . 'listener_failed', $operation, $errnum, $errstr );
  return;
}

sub _accept_failed6 {
  my ($kernel,$self,$operation,$errnum,$errstr,$wheel_id) = @_[KERNEL,OBJECT,ARG0..ARG3];
  warn "Wheel $wheel_id generated $operation error $errnum: $errstr\n";
  delete $self->{listener6} if $operation eq 'listen';
  $self->_send_event( $self->{_prefix} . 'listener_failed', $operation, $errnum, $errstr );
  return;
}

sub disconnect {
  my $self = shift;
  $poe_kernel->call( $self->{session_id}, 'disconnect', @_ );
}

sub _disconnect {
  my ($kernel,$self,$id) = @_[KERNEL,OBJECT,ARG0];
  return unless $self->_conn_exists( $id );
  $self->{clients}->{ $id }->{quit} = 1;
  return 1;
}

sub terminate {
  my $self = shift;
  $poe_kernel->call( $self->{session_id}, 'terminate', @_ );
}

sub _terminate {
  my ($kernel,$self,$id) = @_[KERNEL,OBJECT,ARG0];
  return unless $self->_conn_exists( $id );
  delete $self->{clients}->{ $id };
  $self->_send_event( $self->{_prefix} . 'disconnected', $id );
  return 1;
}

sub _conn_input {
  my ($kernel,$self,$input,$id) = @_[KERNEL,OBJECT,ARG0,ARG1];
  return unless $self->_conn_exists( $id );
  #$kernel->delay_adjust( $self->{clients}->{ $id }->{alarm}, $self->{time_out} || 300 );
  $self->_send_event( $self->{_prefix} . 'client_input', $id, $input );
  return;
}

sub _conn_error {
  my ($self,$errstr,$id) = @_[OBJECT,ARG2,ARG3];
  return unless $self->_conn_exists( $id );
  my $href = delete $self->{clients}->{ $id };
  delete $href->{wheel};
  $self->_send_event( $self->{_prefix} . 'disconnected', $id,  map { $href->{$_} } qw(peeraddr peerport sockaddr sockport) );
  return;
}

sub _conn_flushed {
  my ($self,$id) = @_[OBJECT,ARG0];
  return unless $self->_conn_exists( $id );
  if ( $self->{clients}->{ $id }->{BUFFER} ) {
    my $item = shift @{ $self->{clients}->{ $id }->{BUFFER} };
    unless ( $item ) {
      delete $self->{clients}->{ $id }->{BUFFER};
      $self->_send_event( $self->{_prefix} . 'client_flushed', $id );
      return;
    }
    $self->{clients}->{ $id }->{wheel}->put($item);
    return;
  }
  unless ( $self->{clients}->{ $id }->{quit} ) {
    $self->_send_event( $self->{_prefix} . 'client_flushed', $id );
    return;
  }
  delete $self->{clients}->{ $id };
  $self->_send_event( $self->{_prefix} . 'disconnected', $id );
  return;
}

sub _conn_alarm {
  my ($kernel,$self,$id) = @_[KERNEL,OBJECT,ARG0];
  return unless $self->_conn_exists( $id );
  delete $self->{clients}->{ $id };
  $self->_send_event( $self->{_prefix} . 'disconnected', $id );
  return;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  delete $self->{listener};
  delete $self->{listener6};
  delete $self->{clients};
  $kernel->alarm_remove_all();
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ ) unless $self->{alias};
#  $self->_pluggable_destroy();
  $self->_unregister_sessions();
  return;
}

sub register {
  my ($kernel, $self, $session, $sender, @events) =
    @_[KERNEL, OBJECT, SESSION, SENDER, ARG0 .. $#_];

  unless (@events) {
    warn "register: Not enough arguments";
    return;
  }

  my $sender_id = $sender->ID();

  foreach (@events) {
    $_ = $self->{_prefix} . $_ unless /^_/;
    $self->{events}->{$_}->{$sender_id} = $sender_id;
    $self->{sessions}->{$sender_id}->{'ref'} = $sender_id;
    unless ($self->{sessions}->{$sender_id}->{refcnt}++ or $session == $sender) {
      $kernel->refcount_increment($sender_id, __PACKAGE__);
    }
  }

  $kernel->post( $sender, $self->{_prefix} . 'registered', $self );
  return;
}

sub unregister {
  my ($kernel, $self, $session, $sender, @events) =
    @_[KERNEL,  OBJECT, SESSION,  SENDER,  ARG0 .. $#_];

  unless (@events) {
    warn "unregister: Not enough arguments";
    return;
  }

  $self->_unregister($session,$sender,@events);
  undef;
}

sub _unregister {
  my ($self,$session,$sender) = splice @_,0,3;
  my $sender_id = $sender->ID();

  foreach (@_) {
    $_ = $self->{_prefix} . $_ unless /^_/;
    my $blah = delete $self->{events}->{$_}->{$sender_id};
    unless ( $blah ) {
	warn "$sender_id hasn't registered for '$_' events\n";
	next;
    }
    if (--$self->{sessions}->{$sender_id}->{refcnt} <= 0) {
      delete $self->{sessions}->{$sender_id};
      unless ($session == $sender) {
        $poe_kernel->refcount_decrement($sender_id, __PACKAGE__);
      }
    }
  }
  undef;
}

sub _unregister_sessions {
  my $self = shift;
  my $testd_id = $self->session_id();
  foreach my $session_id ( keys %{ $self->{sessions} } ) {
     if (--$self->{sessions}->{$session_id}->{refcnt} <= 0) {
        delete $self->{sessions}->{$session_id};
	$poe_kernel->refcount_decrement($session_id, __PACKAGE__) 
		unless ( $session_id eq $testd_id );
     }
  }
}

sub __send_event {
  my( $self, $event, @args ) = @_[ OBJECT, ARG0, ARG1 .. $#_ ];
  $self->_send_event( $event, @args );
  return;
}

sub _send_event  {
  my $self = shift;
  my ($event, @args) = @_;
  my $kernel = $POE::Kernel::poe_kernel;
  my %sessions;

  $sessions{$_} = $_ for (values %{$self->{events}->{$self->{_prefix} . 'all'}}, values %{$self->{events}->{$event}});

  $kernel->post( $_ => $event => @args ) for values %sessions;
  undef;
}

sub send_to_client {
  my $self = shift;
  $poe_kernel->call( $self->{session_id}, '_send_to_client', @_ );
}

sub _send_to_client {
  my ($kernel,$self,$id,$output) = @_[KERNEL,OBJECT,ARG0..ARG1];
  return unless $self->_conn_exists( $id );
  return unless defined $output;

  if ( ref $output eq 'ARRAY' ) {
    my $temp = [ @{ $output } ];
    my $first = shift @{ $temp };
    $self->{clients}->{ $id }->{BUFFER} = $temp if scalar @{ $temp };
    $self->{clients}->{ $id }->{wheel}->put($first) if defined $first;
    return 1;
  }

  $self->{clients}->{ $id }->{wheel}->put($output);
  return 1;
}

sub send_to_all_clients {
  my $self = shift;
  $poe_kernel->call( $self->{session_id}, '_send_to_all_clients', @_ );
}

sub _send_to_all_clients {
  my ($kernel,$self,$output) = @_[KERNEL,OBJECT,ARG0];
  return unless defined $output;
  $self->send_to_client( $_, $output ) for
    keys %{ $self->{clients} };
  return 1;
}

q{Putting the test into POE};

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::POE::Server::TCP - A POE Component providing TCP server services for test cases

=head1 VERSION

version 1.20

=head1 SYNOPSIS

A very simple echo server with logging of requests by each client:

   use strict;
   use POE;
   use Test::POE::Server::TCP;

   POE::Session->create(
     package_states => [
   	'main' => [qw(
   			_start
   			testd_connected
   			testd_disconnected
   			testd_client_input
   	)],
     ],
   );

   $poe_kernel->run();
   exit 0;

   sub _start {
     # Spawn the Test::POE::Server::TCP server.
     $_[HEAP]->{testd} = Test::POE::Server::TCP->spawn(
   	address => '127.0.0.1',
   	port => 0,
     );
     return;
   }

   sub testd_connected {
     my ($heap,$id) = @_[HEAP,ARG0];

     # A client connected the unique ID is in ARG0
     # Create a blank arrayref for this client on *our* heap

     $heap->{clients}->{ $id } = [ ];

     return;
   }

   sub testd_client_input {
     my ($kernel,$heap,$sender,$id,$input) = @_[KERNEL,HEAP,SENDER,ARG0,ARG1];

     # The client sent us a line of input
     # lets store it

     push @{ $heap->{clients}->{ $id } }, $input;

     # Okay, we are an echo server so lets send it back to the client
     # We know the SENDER so can always obtain the server object.

     my $testd = $sender->get_heap();
     $testd->send_to_client( $id, $input );

     # Or even

     # $sender->get_heap()->send_to_client( $id, $input );

     # Alternatively we could just post back to the SENDER

     # $kernel->post( $sender, 'send_to_client', $id, $input );

     return;
   }

   sub testd_disconnected {
     my ($heap,$id) = @_[HEAP,ARG0];

     # Client disconnected for whatever reason
     # We need to free up our storage

     delete $heap->{clients}->{ $id };

     return;
   }

Using the module in a testcase:

   use strict;
   use Test::More;
   use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::Line);
   use Test::POE::Server::TCP;

   plan tests => 5;

   my @data = (
     'This is a test',
     'This is another test',
     'This is the last test',
   );

   POE::Session->create(
     package_states => [
   	'main' => [qw(
   			_start
   			_sock_up
   			_sock_fail
   			_sock_in
   			_sock_err
   			testd_connected
   			testd_disconnected
   			testd_client_input
   	)],
     ],
     heap => { data => \@data, },
   );

   $poe_kernel->run();
   exit 0;

   sub _start {
     $_[HEAP]->{testd} = Test::POE::Server::TCP->spawn(
   	address => '127.0.0.1',
   	port => 0,
     );
     return;
   }

   sub testd_registered {
     my ($heap,$object) = @_[HEAP,ARG0];
     $heap->{port} = $object->port();
     $heap->{factory} = POE::Wheel::SocketFactory->new(
   	RemoteAddress  => '127.0.0.1',
   	RemotePort     => $heap->{port},
   	SuccessEvent   => '_sock_up',
   	FailureEvent   => '_sock_fail',
     );
     return;
   }

   sub _sock_up {
     my ($heap,$socket) = @_[HEAP,ARG0];
     delete $heap->{factory};
     $heap->{socket} = POE::Wheel::ReadWrite->new(
   	Handle => $socket,
   	InputEvent => '_sock_in',
   	ErrorEvent => '_sock_err',
     );
     $heap->{socket}->put( $heap->{data}->[0] );
     return;
   }

   sub _sock_fail {
     my $heap = $_[HEAP];
     delete $heap->{factory};
     $heap->{testd}->shutdown();
     return;
   }

   sub _sock_in {
     my ($heap,$input) = @_[HEAP,ARG0];
     my $data = shift @{ $heap->{data} };
     ok( $input eq $data, 'Data matched' );
     unless ( scalar @{ $heap->{data} } ) {
       delete $heap->{socket};
       return;
     }
     $heap->{socket}->put( $heap->{data}->[0] );
     return;
   }

   sub _sock_err {
     delete $_[HEAP]->{socket};
     return;
   }

   sub testd_connected {
     my ($heap,$state,$id) = @_[HEAP,STATE,ARG0];
     pass($state);
     return;
   }

   sub testd_disconnected {
     pass($_[STATE]);
     $poe_kernel->post( $_[SENDER], 'shutdown' );
     return;
   }

   sub testd_client_input {
     my ($sender,$id,$input) = @_[SENDER,ARG0,ARG1];
     my $testd = $_[SENDER]->get_heap();
     $testd->send_to_client( $id, $input );
     return;
   }

=head1 DESCRIPTION

Test::POE::Server::TCP is a L<POE> component that provides a TCP server framework for inclusion in
client component test cases, instead of having to roll your own.

Once registered with the component, a session will receive events related to client connects, disconnects,
input and flushed output. Each of these events will refer to a unique client ID which may be used in
communication with the component when sending data to the client or disconnecting a client connection.

If AF_INET6 sockets are supported the component with create an AF_INET and an AF_INET6 socket.

=head1 CONSTRUCTOR

=over

=item C<spawn>

Takes a number of optional arguments:

  'alias', set an alias on the component;
  'address', bind the listening socket to a particular address;
  'port', listen on a particular port, default is 0, assign a random port;
  'options', a hashref of POE::Session options;
  'filter', specify a POE::Filter to use for client connections, default is POE::Filter::Line;
  'inputfilter', specify a POE::Filter for client input;
  'outputfilter', specify a POE::Filter for output to clients;
  'prefix', specify a different prefix than 'testd' for events;

The semantics for C<filter>, C<inputfilter> and C<outputfilter> are the same as for L<POE::Component::Server::TCP> in that one
may provide either a C<SCALAR>, C<ARRAYREF> or an C<OBJECT>.

If the component is C<spawn>ed within another session it will automatically C<register> the parent session
to receive C<all> events.

=back

=head1 METHODS

=over

=item C<session_id>

Returns the POE::Session ID of the component.

=item C<shutdown>

Terminates the component. Shuts down the listener and disconnects connected clients.

=item C<send_to_client>

Send some output to a connected client. First parameter must be a valid client id. Second parameter is a string of text to send.
The second parameter may also be an arrayref of items to send to the client. If the filter you have used requires an arrayref as
input, nest that arrayref within another arrayref.

=item C<send_to_all_clients>

Send some output to all connected clients. The parameter is a string of text to send.
The parameter may also be an arrayref of items to send to the clients. If the filter you have used requires an arrayref as
input, nest that arrayref within another arrayref.

=item C<client_info>

Retrieve socket information of a given client. Requires a valid client ID as a parameter. If called in a list context it returns a list
consisting of, in order, the client address, the client TCP port, our address and our TCP port. In a scalar context it returns a HASHREF
with the following keys:

  'peeraddr', the client address;
  'peerport', the client TCP port;
  'sockaddr', our address;
  'sockport', our TCP port;

=item C<client_wheel>

Retrieve the L<POE::Wheel::ReadWrite> object of a given client. Requires a valid client ID as a parameter. This enables one to
manipulate the given L<POE::Wheel::ReadWrite> object, say to switch L<POE::Filter>.

=item C<disconnect>

Places a client connection in pending disconnect state. Requires a valid client ID as a parameter.
Set this, then send an applicable message to the client using send_to_client() and the client connection will be terminated.

=item C<terminate>

Immediately disconnects a client conenction. Requires a valid client ID as a parameter.

=item C<pause_listening>

Stops the underlying listening socket from accepting new connections. This lets you test whether you handle the connection timing out gracefully.

=item C<resume_listening>

The companion of C<pause_listening>

=item C<getsockname>

Access to the L<POE::Wheel::SocketFactory> method of the underlying listening AF_INET socket.

=item C<port>

Returns the port that the component is listening on.

=item C<getsockname6>

Access to the L<POE::Wheel::SocketFactory> method of the underlying listening AF_INET6 socket.

=item C<port6>

Returns the port that the component is listening on for AF_INET6.

=item C<start_listener>

If the listener fails on C<listen> you can attempt to restart it with this.

=back

=head1 INPUT EVENTS

These are events that the component will accept:

=over

=item C<register>

Takes N arguments: a list of event names that your session wants to listen for, minus the 'testd_' prefix.

Registering for 'all' will cause it to send all TESTD-related events to you; this is the easiest way to handle it.

=item C<unregister>

Takes N arguments: a list of event names which you don't want to receive. If you've previously done a 'register' for a particular event which you no longer care about, this event will tell the POP3D to stop sending them to you. (If you haven't, it just ignores you. No big deal).

=item C<shutdown>

Terminates the component. Shuts down the listener and disconnects connected clients.

=item C<send_to_client>

Send some output to a connected client. First parameter must be a valid client id. Second parameter is a string of text to send.
The second parameter may also be an arrayref of items to send to the client. If the filter you have used requires an arrayref as
input, nest that arrayref within another arrayref.

=item C<send_to_all_clients>

Send some output to all connected clients. The parameter is a string of text to send.
The parameter may also be an arrayref of items to send to the clients. If the filter you have used requires an arrayref as
input, nest that arrayref within another arrayref.

=item C<disconnect>

Places a client connection in pending disconnect state. Requires a valid client ID as a parameter. Set this, then send an applicable message to the client using send_to_client() and the client connection will be terminated.

=item C<terminate>

Immediately disconnects a client conenction. Requires a valid client ID as a parameter.

=item C<start_listener>

If the listener fails on C<listen> you can attempt to restart it with this.

=back

=head1 OUTPUT EVENTS

The component sends the following events to registered sessions. If you have changed the C<prefix> option in C<spawn> then
substitute C<testd> with the event prefix that you specified.

=over

=item C<testd_registered>

This event is sent to a registering session. ARG0 is the Test::POE::Server::TCP object.

=item C<testd_listener_failed>

Generated if the component cannot either start a listener or there is a problem
accepting client connections. ARG0 contains the name of the operation that failed.
ARG1 and ARG2 hold numeric and string values for $!, respectively.

If the operation was C<listen>, the component will remove the listener.
You may attempt to start it again using C<start_listener>.

=item C<testd_connected>

Generated whenever a client connects to the component. ARG0 is the client ID, ARG1
is the client's IP address, ARG2 is the client's TCP port. ARG3 is our IP address and
ARG4 is our socket port.

=item C<testd_disconnected>

Generated whenever a client disconnects. ARG0 was the client ID, ARG1
was the client's IP address, ARG2 was the client's TCP port. ARG3 was our IP address and
ARG4 was our socket port.

=item C<testd_client_input>

Generated whenever a client sends us some traffic. ARG0 is the client ID, ARG1 is the data sent
( tokenised by whatever POE::Filter you specified ).

=item C<testd_client_flushed>

Generated whenever anything we send to the client is actually flushed down the 'line'. ARG0 is the client ID.

=back

=head1 CREDITS

This module uses code borrowed from L<POE::Component::Server::TCP> by Rocco Caputo, Ann Barcomb and Jos Boumans.

=head1 SEE ALSO

L<POE>

L<POE::Component::Server::TCP>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Chris Williams, Rocco Caputo, Ann Barcomb and Jos Boumans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
