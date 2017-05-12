#!/usr/bin/perl

# Test that we can correctly prevent an alarm from firing

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::Builder::Tester tests => 2;
use Test::More;
use Test::POE::Stopping;

use POE qw{Session};

POE::Session->create(
	inline_states => {
		_start        => \&_start,
		is_stopping   => \&is_stopping,
		pending_alarm => \&pending_alarm,
	},
);

my $id1  = ($POE::VERSION >= 1.310) ? 1 : 2;
my $refs = ($POE::VERSION >= 1.291) ? 1 : 2;
test_out("not ok 1 - POE appears to be stopping cleanly");
test_fail(32);
POE::Kernel->run;
test_err( '# ---'           );
test_err( '# alias: 0'      );
test_err( '# children: 0'   );
test_err( '# current: 1'    );
test_err( '# extra: 0'      );
test_err( '# handles: 0'    );
test_err( "# id: $id1"      );
test_err( '# queue:'        );
test_err( '#   distinct: 1' );
test_err( '#   from: 1'     );
test_err( '#   to: 1'       );
test_err( "# refs: $refs"   );
test_err( '# signals: 0'    );
test_test("Fails correctly for pending alarm");
pass( 'POE Stopped' );





#####################################################################
# Events

sub _start {
	$poe_kernel->delay_set( is_stopping   => 0.5 );
	$poe_kernel->delay_set( pending_alarm => 5 );
	return;
}

sub is_stopping {
	poe_stopping();
}

sub pending_alarm {
	die "This should never run";
}
