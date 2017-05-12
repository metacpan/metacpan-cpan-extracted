use strict;
use Socket;
use Test::More tests => 15;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::Line);
use Test::POE::Client::TCP;

my @data = (
  'This is a test',
  'This is another test',
  'This is the last test',
);

POE::Session->create(
  package_states => [
	'main' => [qw(
			_start
			_accept
			_failed
			_sock_in
			_sock_err
			testc_registered
			testc_connected
			testc_disconnected
			testc_input
			testc_flushed
	)],
  ],
  heap => { data => \@data, },
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{listener} = POE::Wheel::SocketFactory->new(
      BindAddress    => '127.0.0.1',
      SuccessEvent   => '_accept',
      FailureEvent   => '_failed',
      SocketDomain   => AF_INET,             # Sets the socket() domain
      SocketType     => SOCK_STREAM,         # Sets the socket() type
      SocketProtocol => 'tcp',               # Sets the socket() protocol
      Reuse          => 'on',                # Lets the port be reused
  );
  $heap->{testc} = Test::POE::Client::TCP->spawn();
  return;
}

sub _accept {
  my ($kernel,$heap,$socket) = @_[KERNEL,HEAP,ARG0];
  my $wheel = POE::Wheel::ReadWrite->new(
      Handle       => $socket,
      InputEvent   => '_sock_in',
      ErrorEvent   => '_sock_err',
  );
  $heap->{wheels}->{ $wheel->ID } = $wheel;
  return;
}

sub _failed {
  my ($kernel,$heap,$operation,$errnum,$errstr,$wheel_id) = @_[KERNEL,HEAP,ARG0..ARG3];
  die "Wheel $wheel_id generated $operation error $errnum: $errstr\n";
  return;
}

sub _sock_in {
  my ($heap,$input,$wheel_id) = @_[HEAP,ARG0,ARG1];
  pass('Got input from client');
  $heap->{wheels}->{ $wheel_id }->put( $input ) if $heap->{wheels}->{ $wheel_id };
  return;
}

sub _sock_err {
  my ($heap,$wheel_id) = @_[HEAP,ARG3];
  pass('Client disconnected');
  delete $heap->{wheels}->{ $wheel_id };
  return;
}

sub testc_registered {
  my ($kernel,$sender,$object) = @_[KERNEL,SENDER,ARG0];
  pass($_[STATE]);
  my $port = ( sockaddr_in( $_[HEAP]->{listener}->getsockname() ) )[0];
  $kernel->post( $sender, 'connect', { address => '127.0.0.1', port => $port } );
  return;
}

sub testc_connected {
  my ($kernel,$heap,$sender) = @_[KERNEL,HEAP,SENDER];
  pass($_[STATE]);
  $kernel->post( $sender, 'send_to_server', $heap->{data}->[0] );
  return;
}

sub testc_flushed {
  pass($_[STATE]);
  return;
}

sub testc_input {
  my ($heap,$input) = @_[HEAP,ARG0];
  pass('Got something back from the server');
  my $data = shift @{ $heap->{data} };
  ok( $input eq $data, "Data matched: '$input'" );
  unless ( scalar @{ $heap->{data} } ) {
    $heap->{testc}->terminate();
    return;
  }
  $poe_kernel->post( $_[SENDER], 'send_to_server', $heap->{data}->[0] );
  return;
}

sub testc_disconnected {
  my ($heap,$state) = @_[HEAP,STATE];
  pass($state);
  delete $heap->{wheels};
  delete $heap->{listener};
  $heap->{testc}->shutdown();
  return;
}
