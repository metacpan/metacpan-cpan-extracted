use strict;
use Test::More;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::Line);
use Test::POE::Server::TCP;

plan tests => 7;

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
			testd_registered
			testd_connected
			testd_disconnected
			testd_client_flushed
	)],
  ],
  heap => { data => \@data, },
);

$poe_kernel->run();
exit 0;

sub _start {
  my $heap = $_[HEAP];
  $heap->{testd} = Test::POE::Server::TCP->spawn(
	address => '127.0.0.1',
	port => 0,
  );
  $heap->{count} = @{ $heap->{data} };
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
  return;
}

sub _sock_fail {
  my $heap = $_[HEAP];
  pass($_[STATE]);
  delete $heap->{factory};
  $heap->{testd}->shutdown();
  return;
}

sub _sock_in {
  my ($heap,$input) = @_[HEAP,ARG0];
  pass($input);
  return;
}

sub _sock_err {
  delete $_[HEAP]->{socket};
  pass($_[STATE]);
  $_[HEAP]->{testd}->shutdown();
  return;
}

sub testd_connected {
  my ($heap,$state,$id) = @_[HEAP,STATE,ARG0];
  pass($state);
  $heap->{testd}->send_to_client( $id, [ @{ $heap->{data} } ] );
  return;
}

sub testd_disconnected {
  pass($_[STATE]);
  $poe_kernel->post( $_[SENDER], 'shutdown' );
  return;
}

sub testd_client_flushed {
  my ($heap,$state,$id) = @_[HEAP,STATE,ARG0];
  pass($state);
  $heap->{testd}->terminate($id);
  return;
}
