# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-Stripper.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 29;
use Text::Stripper;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Define two test-strings:
my $str1 = "Eine kleine Mickey-Maus, zog sich mal die Hose aus!";
my $str2 = "Lorem ipsum dolor sit amet, consectetur, adipisci velit";

# Run Stripper with various options on the test-strings:
my @testValues = (
	Text::Stripper::stripof( $str1, 10, 10, 1, 1 ),
	Text::Stripper::stripof( $str1, 10, 15, 1, 1 ),
	Text::Stripper::stripof( $str1, 10, 20, 1, 1 ),
	Text::Stripper::stripof( $str1, 10, 25, 1, 1 ),
	Text::Stripper::stripof( $str1, 10, 30, 1, 1 ),
	Text::Stripper::stripof( $str1, 10, 35, 1, 1 ),
	Text::Stripper::stripof( $str1, 10, 40, 1, 1 ),
	Text::Stripper::stripof( $str1, 10, 45, 1, 1 ),
	Text::Stripper::stripof( $str1, 10, 50, 1, 1 ),
	Text::Stripper::stripof( $str1, 10, 51, 1, 1 ),
	Text::Stripper::stripof( $str1, 10, 52, 1, 1 ),
	Text::Stripper::stripof( $str1, 10, 53, 1, 1 ),
	Text::Stripper::stripof( $str1, 10, 54, 1, 1 ),
	Text::Stripper::stripof( $str1, 10, 55, 1, 1 ),
	Text::Stripper::stripof( $str1, 10, 10, 0, 1 ),
	Text::Stripper::stripof( $str1, 10, 15, 0, 1 ),
	Text::Stripper::stripof( $str1, 10, 20, 0, 1 ),
	Text::Stripper::stripof( $str1, 10, 25, 0, 1 ),
	Text::Stripper::stripof( $str1, 10, 30, 0, 1 ),
	Text::Stripper::stripof( $str1, 10, 35, 0, 1 ),
	Text::Stripper::stripof( $str1, 10, 40, 0, 1 ),
	Text::Stripper::stripof( $str1, 10, 45, 0, 1 ),
	Text::Stripper::stripof( $str1, 10, 50, 0, 1 ),
	Text::Stripper::stripof( $str1, 10, 51, 0, 1 ),
	Text::Stripper::stripof( $str1, 10, 52, 0, 1 ),
	Text::Stripper::stripof( $str1, 10, 53, 0, 1 ),
	Text::Stripper::stripof( $str1, 10, 54, 0, 1 ),
	Text::Stripper::stripof( $str1, 10, 55, 0, 1 ),
	Text::Stripper::stripof( $str2, 30, 10, 1, 1 )
	
	);

# define what we expect to be returned:
my @expectedValues = (
	"Eine kleine Mickey...",
	"Eine kleine Mickey-Maus,...",
	"Eine kleine Mickey-Maus, zog...",
	"Eine kleine Mickey-Maus, zog sich...",
	"Eine kleine Mickey-Maus, zog sich mal...",
	"Eine kleine Mickey-Maus, zog sich mal die...",
	"Eine kleine Mickey-Maus, zog sich mal die Hose...",
	"Eine kleine Mickey-Maus, zog sich mal die Hose aus!",
	"Eine kleine Mickey-Maus, zog sich mal die Hose aus!",
	"Eine kleine Mickey-Maus, zog sich mal die Hose aus!",
	"Eine kleine Mickey-Maus, zog sich mal die Hose aus!",
	"Eine kleine Mickey-Maus, zog sich mal die Hose aus!",
	"Eine kleine Mickey-Maus, zog sich mal die Hose aus!",
	"Eine kleine Mickey-Maus, zog sich mal die Hose aus!",
	"Eine kleine...",
	"Eine kleine...",
	"Eine kleine...",
	"Eine kleine...",
	"Eine kleine...",
	"Eine kleine...",
	"Eine kleine...",
	"Eine kleine...",
	"Eine kleine...",
	"Eine kleine...",
	"Eine kleine...",
	"Eine kleine...",
	"Eine kleine...",
	"Eine kleine...",
	"Lorem ipsum dolor sit amet, consectetur..."
	);


# for every stripped string we have:
foreach( @testValues ){
	
	# get the expected stripped string...
	my $expected = shift( @expectedValues );
	
	# ...and compare the result with the expected value:
	ok( $_ eq $expected ) or print "expected '$expected', got '$_'";
	
}


