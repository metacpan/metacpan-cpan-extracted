#!perl -T

#use Test::More tests => 3;
use Test::More 'no_plan';

use lib 't';

use TestConfig;
login_myspace or die "Login Failed - can't run tests";

# Re-run the tests without logging in.
SKIP: {
	skip "Not logged in", 1 unless $CONFIG->{login};

	diag "Running end-user tests without login";
	$ENV{PATH}="/bin:/usr/bin:/usr/local/bin:/usr/ucb/bin";
	system( "touch eu ; make test && rm eu" );
	
	# If the eu file's still there, the tests failed.
	if ( -f "eu" ) {
		fail "End User Tests";
		diag "Run \"perl -Tw -I./lib t/99-enduser.t\" for details";

		# Clean up
		unlink "eu";
	} else {
		pass "End User Tests";
	}
}