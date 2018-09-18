use strict;
use Socket;
use Test::More;

BEGIN {
    eval('Socket::AF_INET6') or plan skip_all => 'AF_INET6 not available';
};

plan tests => 12;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::Line);
use_ok('Test::POE::Client::TCP');

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
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{listener} = POE::Wheel::SocketFactory->new(
      BindAddress    => '::1',
      SuccessEvent   => '_accept',
      FailureEvent   => '_failed',
      SocketDomain   => AF_INET6,            # Sets the socket() domain
      SocketType     => SOCK_STREAM,         # Sets the socket() type
      SocketProtocol => 'tcp',               # Sets the socket() protocol
      Reuse          => 'on',                # Lets the port be reused
  );
  $heap->{testc} = Test::POE::Client::TCP->spawn();
  isa_ok( $heap->{testc}, 'Test::POE::Client::TCP' );
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
  isa_ok( $object, 'Test::POE::Client::TCP' );
  my $port = ( sockaddr_in6( $_[HEAP]->{listener}->getsockname() ) )[0];
  $kernel->post( $sender, 'connect', { address => '::1', port => $port } );
  return;
}

sub testc_connected {
  my ($kernel,$sender) = @_[KERNEL,SENDER];
  pass($_[STATE]);
  isa_ok( $_[HEAP]->{testc}->wheel, 'POE::Wheel::ReadWrite' );
  $kernel->post( $sender, 'send_to_server', 'Hello, is it me you are looking for?' );
  return;
}

sub testc_flushed {
  pass($_[STATE]);
  return;
}

sub testc_input {
  my ($heap,$input) = @_[HEAP,ARG0];
  pass('Got something back from the server');
  ok( $input eq 'Hello, is it me you are looking for?', $input );
  $heap->{testc}->terminate();
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
