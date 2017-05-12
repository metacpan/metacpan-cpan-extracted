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
			bingosd_registered
			bingosd_connected
			bingosd_disconnected
			bingosd_client_input
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
	prefix => 'bingosd',
  );
  return;
}

sub bingosd_registered {
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
    if ( $^O =~ /(cygwin|MSWin)/ ) {
	$heap->{socket}->shutdown_input();
	$heap->{socket}->shutdown_output();
    }
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

sub bingosd_connected {
  my ($heap,$state,$id) = @_[HEAP,STATE,ARG0];
  pass($state);
  return;
}

sub bingosd_disconnected {
  pass($_[STATE]);
  $poe_kernel->post( $_[SENDER], 'shutdown' );
  return;
}

sub bingosd_client_input {
  my ($sender,$id,$input) = @_[SENDER,ARG0,ARG1];
  my $testd = $_[SENDER]->get_heap();
  $testd->send_to_client( $id, $input );
  return;
}
