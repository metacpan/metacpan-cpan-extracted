# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-Stripper.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
use Text::Stripper;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


# Redefine Breakpoints:
@Text::Stripper::breakpoints = ('<','>');


# Define a test-string:
my $str = "Eine kleine <Mickey-Maus>, zog sich mal die Hose aus!";


# Run Stripper with various options on the test-string:
my @testValues = (
	Text::Stripper::stripof( $str, 10, 10, 1, 1 ),
	Text::Stripper::stripof( $str, 10, 14, 1, 1 ),
	Text::Stripper::stripof( $str, 10, 15, 1, 1 ),
	Text::Stripper::stripof( $str, 10, 20, 1, 1 ),
	Text::Stripper::stripof( $str, 2,  30, 1, 1 ),
	Text::Stripper::stripof( $str, 2,  30, 0, 1 )
	);

# define what we expect to be returned:
my @expectedValues = (
	"Eine kleine ...",
	"Eine kleine ...",
	"Eine kleine <Mickey-Maus...",
	"Eine kleine <Mickey-Maus...",
	"Eine kleine <Mickey-Maus...",
	"Eine kleine ..."
	);

# for every stripped string we have:
foreach( @testValues ){
	
	# get the expected stripped string...
	my $expected = shift( @expectedValues );
	
	# ...and compare the result with the expected value:
	ok( $_ eq $expected ) or print "expected '$expected', got '$_'";
	
}




