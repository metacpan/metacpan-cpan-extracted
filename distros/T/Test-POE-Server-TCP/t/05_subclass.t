use strict;

{
  package TPSTSubclass;
  use base qw(Test::POE::Server::TCP);
  my $VERSION = '0.01';
}

use Socket;
use Test::More;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::Line);

my %data = (
	tests => [ 
		[ '+OK' => 'cock' ], 
		[ '-ERR' => 'quit' ],
	],
);

plan tests => 12;

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
			testd_client_input
	)],
  ],
  heap => \%data,
);

$poe_kernel->run();
exit 0;

sub _start {
  $_[HEAP]->{testd} = TPSTSubclass->spawn(
	address => '127.0.0.1',
	port => 0,
	options => { trace => 0 },
  );
  isa_ok( $_[HEAP]->{testd}, 'Test::POE::Server::TCP' );
  isa_ok( $_[HEAP]->{testd}, 'TPSTSubclass' );
  return;
}

sub testd_registered {
  my ($heap,$object) = @_[HEAP,ARG0];
  isa_ok( $object, 'Test::POE::Server::TCP' );
  isa_ok( $object, 'TPSTSubclass' );
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
  delete $heap->{factory};
  $heap->{testd}->shutdown();
  return;
}

sub _sock_in {
  my ($heap,$input) = @_[HEAP,ARG0];
  my @parms = split /\s+/, $input;
  my $test = shift @{ $heap->{tests} };
  if ( $test and $test->[0] eq $parms[0] ) {
	pass($input);
	$heap->{socket}->put( $test->[1] );
	return;
  }
  pass($input);
  return;
}

sub _sock_err {
  delete $_[HEAP]->{socket};
  pass("Disconnected");
  $_[HEAP]->{testd}->shutdown();
  return;
}

sub testd_connected {
  my ($heap,$state,$id) = @_[HEAP,STATE,ARG0];
  $heap->{testd}->send_to_client( $id, '+OK POP3 Fakepop 6.9 server ready' );
  pass($state);
  return;
}

sub testd_disconnected {
  pass($_[STATE]);
  return;
}

sub testd_client_input {
  my ($sender,$id,$input) = @_[SENDER,ARG0,ARG1];
  my $testd = $_[SENDER]->get_heap();
  pass($_[STATE]);
  if ( $input eq 'quit' ) {
    $testd->disconnect( $id );
    $testd->send_to_client( $id, '+OK POP3 server signing off' );
    return;
  }
  $testd->send_to_client( $id, '-ERR' );
  return;
}
