use strict;
use Test::More tests => 6;
use POE;
use_ok('Test::POE::Client::TCP');

my $testc = Test::POE::Client::TCP->spawn();
isa_ok( $testc, 'Test::POE::Client::TCP' );

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
  pass($_[STATE]);
  $poe_kernel->post( $testc->session_id(), 'register', 'all' );
  return;
}

sub _stop {
  $testc->shutdown;
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
