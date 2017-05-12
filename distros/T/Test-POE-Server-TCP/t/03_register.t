use strict;
use Test::More;
use POE;
use Test::POE::Server::TCP;

plan tests => 4;

POE::Session->create(
  package_states => [
	'main' => [qw(
			_start
			_stop
			testd_registered
	)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  $_[HEAP]->{testd} = Test::POE::Server::TCP->spawn();
  pass($_[STATE]);
  return;
}

sub _stop {
  $_[HEAP]->{testd}->shutdown;
  pass($_[STATE]);
  return;
}

sub testd_registered {
  my ($sender,$object) = @_[SENDER,ARG0];
  pass($_[STATE]);
  isa_ok( $object, 'Test::POE::Server::TCP' );
  $poe_kernel->post( $sender, 'unregister', 'all' );
  return;
}
