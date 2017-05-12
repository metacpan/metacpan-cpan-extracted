#!/usr/bin/perl

# Compile testing for Test::POE::Stopping

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::Builder::Tester tests => 2;
use Test::More;
use Test::POE::Stopping;

use POE qw{Session};

my $session = POE::Session->create(
	inline_states => {
		_start        => \&_start,
		intermediate  => \&intermediate,
		is_stopping   => \&is_stopping,
		pending_event => \&pending_event,
	},
);

my $id1 = ($POE::VERSION >= 1.310) ? 1 : 2;
test_out("not ok 1 - POE appears to be stopping cleanly");
test_fail(37);
POE::Kernel->run;
test_err( '# ---'           );
test_err( '# alias: 0'      );
test_err( '# children: 0'   );
test_err( '# current: 1'    );
test_err( '# extra: 0'      );
test_err( '# handles: 0'    );
test_err( "# id: $id1"      );
test_err( '# queue:'        );
test_err( '#   distinct: 0' );
test_err( '#   from: 0'     );
test_err( '#   to: 0'       );
test_err( '# refs: 0'       );
test_err( '# signals: 0'    );
test_err( '# Tried to stop within nested events 2 deep (probably due to using ->call)' );
test_test("Fails correctly for pending event");
pass( 'POE Stopped' );





#####################################################################
# Events

sub _start {
	$poe_kernel->delay_set( intermediate => 0.5 );
	return;
}

sub intermediate {
	$poe_kernel->call( $session, 'is_stopping'   );	
	$poe_kernel->post( $session, 'pending_event' );
}

sub is_stopping {
	poe_stopping();
}

sub pending_event {
	die "This should never run";
}
