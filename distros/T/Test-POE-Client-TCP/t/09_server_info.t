use strict;
use Socket;
use Test::More tests => 22;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::Line);
use_ok('Test::POE::Client::TCP');

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
  $heap->{count} = @{ $heap->{data} };
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
  my $port = ( sockaddr_in( $_[HEAP]->{listener}->getsockname() ) )[0];
  diag("Connecting to port: $port\n");
  $kernel->post( $sender, 'connect', { address => '127.0.0.1', port => $port } );
  return;
}

sub testc_connected {
  my ($kernel,$heap,$sender) = @_[KERNEL,HEAP,SENDER];
  pass($_[STATE]);
  my @orig = @_[ARG0..$#_];
  my @test = $heap->{testc}->server_info();
  my $test = $heap->{testc}->server_info();
  ok( $test[$_] eq $orig[$_], "Server Info: " . $orig[$_] ) for 0 .. 3;
  my @test2 = map { $test->{$_} } qw(peeraddr peerport sockaddr sockport);
  ok( $test2[$_] eq $orig[$_], "Server Info: " . $orig[$_] ) for 0 .. 3;
  $kernel->post( $sender, 'send_to_server', [ @{ $_[HEAP]->{data} } ] );
  return;
}

sub testc_flushed {
  pass($_[STATE]);
  return;
}

sub testc_input {
  my ($heap,$input) = @_[HEAP,ARG0];
  pass('Got something back from the server');
  $heap->{count}--;
  $heap->{testc}->terminate() if $heap->{count} <= 0;
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
