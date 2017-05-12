use strict;
use Socket;
use Test::More;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite);
use Test::POE::Server::TCP;

plan tests => 4;

POE::Session->create(
  package_states => [
	'main' => [qw(
			_start
			_sock_up
			_sock_fail
			testd_registered
                        _sock_in
                        _sock_err
                        testd_connected
                        timeout
	)],
  ],
#  heap => \%data,
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
  my ($kernel,$heap,$object) = @_[KERNEL,HEAP,ARG0];
  isa_ok( $object, 'Test::POE::Server::TCP' );
  $heap->{port} = $object->port();
  $object->pause_listening();
  $heap->{want_timeout} = 1;
  $kernel->delay(timeout => 1);
  $_[HEAP]->{factory} = POE::Wheel::SocketFactory->new(
	RemoteAddress  => '127.0.0.1',
	RemotePort     => $object->port(),
	SuccessEvent   => '_sock_up',
	FailureEvent   => '_sock_fail',
  );
  return;
}

sub timeout {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  if (delete $heap->{want_timeout}) {
    pass('got timeout');
    $heap->{testd}->resume_listening();
  } else {
    BAIL_OUT('unexpected timeout');
    delete $heap->{factory};
    $heap->{testd}->shutdown;
  }
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
  BAIL_OUT('connection failed');
  return;
}

sub _sock_in {
  my ($heap,$input) = @_[HEAP,ARG0];
  BAIL_OUT('unexpected input');
  delete $_[HEAP]->{socket};
  $_[HEAP]->{testd}->shutdown();
  return;
}

sub _sock_err {
  BAIL_OUT('unexpected error');
  delete $_[HEAP]->{socket};
  $_[HEAP]->{testd}->shutdown();
  return;
}

sub testd_connected {
  my ($heap,$state,$id) = @_[HEAP,STATE,ARG0];
  if ($heap->{want_timeout}) {
    BAIL_OUT('unexpected connection');
  } else {
    pass($state);
  }
  delete $heap->{socket};
  $heap->{testd}->shutdown;
}
