# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use Tk;
use Tk::Stderr;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $mw = MainWindow->new->InitStderr;

sub testsub;

my $index = 0;

sub testsub {
	if (++$index > 25) {
		print STDERR "Done!\n";
		$mw->destroy;
	} else {
		if ($index == 10) {
			$mw->RedirectStderr(0);
			print STDERR "\nThere should be two lines following this one:\n";
		} elsif ($index == 12) {
			$mw->RedirectStderr(1);
		}
		if ($index & 1) {
			printf STDERR "Printed to STDERR, line %03d\n", $index;
		} else {
			warn "this is warning number $index";
		}
		$mw->after(100, \&testsub);
	}
}

$mw->afterIdle(\&testsub);

MainLoop;

ok(1);
