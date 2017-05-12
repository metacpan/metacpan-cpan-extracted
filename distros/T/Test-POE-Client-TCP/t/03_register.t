use strict;
use Test::More tests => 6;
use POE;
use_ok( 'Test::POE::Client::TCP' );

POE::Session->create(
  package_states => [
	'main' => [qw(
			_start
			_stop
			testc_registered
	)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  $_[HEAP]->{testc} = Test::POE::Client::TCP->spawn();
  isa_ok( $_[HEAP]->{testc}, 'Test::POE::Client::TCP' );
  pass($_[STATE]);
  return;
}

sub _stop {
  $_[HEAP]->{testc}->shutdown;
  pass($_[STATE]);
  return;
}

sub testc_registered {
  my ($sender,$object) = @_[SENDER,ARG0];
  pass($_[STATE]);
  isa_ok( $object, 'Test::POE::Client::TCP' );
  $poe_kernel->post( $sender, 'unregister', 'all' );
  return;
}
