use strict;
use Socket;
use Test::More;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::Line);
use Test::POE::Server::TCP;

my %data = (
	tests => [ 
		[ '+OK' => 'cock' ], 
		[ '-ERR' => 'quit' ],
	],
	clients => 2,
);

plan tests => 22;

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
			testd_client_flushed
	)],
  ],
  heap => \%data,
);

$poe_kernel->run();
exit 0;

sub _start {
  $_[HEAP]->{testd} = Test::POE::Server::TCP->spawn(
	address => '127.0.0.1',
	port => 0,
	options => { trace => 0 },
  );
  isa_ok( $_[HEAP]->{testd}, 'Test::POE::Server::TCP' );
  return;
}

sub testd_registered {
  my ($heap,$object) = @_[HEAP,ARG0];
  isa_ok( $object, 'Test::POE::Server::TCP' );
  $heap->{port} = $object->port();
  for ( 1 .. $heap->{clients} ) {
    my $factory = POE::Wheel::SocketFactory->new(
	RemoteAddress  => '127.0.0.1',
	RemotePort     => $heap->{port},
	SuccessEvent   => '_sock_up',
	FailureEvent   => '_sock_fail',
    );
    $heap->{factories}->{ $factory->ID } = $factory;
  }
  return;
}

sub _sock_up {
  my ($heap,$socket,$fact_id) = @_[HEAP,ARG0,ARG3];
  delete $heap->{factories}->{ $fact_id };
  my $wheel = POE::Wheel::ReadWrite->new(
	Handle => $socket,
	InputEvent => '_sock_in',
	ErrorEvent => '_sock_err',
  );
  $heap->{wheels}->{ $wheel->ID } = $wheel;
  $heap->{numbers}->{ $wheel->ID } = 0;
  return;
}

sub _sock_fail {
  my ($heap,$fact_id) = @_[HEAP,ARG3];
  delete $heap->{factory}->{ $fact_id };
  $heap->{clients}--;
  $heap->{testd}->shutdown() if $heap->{clients} <= 0;
  return;
}

sub _sock_in {
  my ($heap,$input,$wheel_id) = @_[HEAP,ARG0,ARG1];
  my @parms = split /\s+/, $input;
  my $test = $heap->{tests}->[ $heap->{numbers}->{ $wheel_id } ];
  $heap->{numbers}->{ $wheel_id }++;
  if ( $test and $test->[0] eq $parms[0] ) {
	pass($input);
	$heap->{wheels}->{ $wheel_id }->put( $test->[1] );
	return;
  }
  pass($input);
  return;
}

sub _sock_err {
  my ($heap,$wheel_id) = @_[HEAP,ARG3];
  delete $heap->{wheels}->{ $wheel_id };
  pass("Disconnected");
  $heap->{clients}--;
  $heap->{testd}->shutdown() if $heap->{clients} <= 0;
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

sub testd_client_flushed {
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
