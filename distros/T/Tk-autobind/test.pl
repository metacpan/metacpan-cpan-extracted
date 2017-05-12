# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tk;
use Tk::autobind;
use Tk::Checkbutton;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $mw = MainWindow->new;
$mw->title('Tk::autobind Test');
my $cb = $mw->Checkbutton(
	-text => 'Check this button',
	-underline => 0,
)->autobind->pack;

my $binding = $mw->bind('<Alt-Key-c>');

if (defined $binding) {
	print "ok 2\n";
} else {
	print "not ok 2\n";
}
