# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Test-TestCoverage.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
use FindBin ();
use lib "$FindBin::Bin";
use Test::TestCoverage;

test_coverage( 'TestCoverage::MyTestModule' );
test_coverage_except( 'TestCoverage::MyTestModule', 'test' );
use_ok( 'TestCoverage::MyTestModule' );
TestCoverage::MyTestModule::methode();
ok_test_coverage('TestCoverage::MyTestModule');


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

