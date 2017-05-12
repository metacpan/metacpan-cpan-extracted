# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Test-TestCoverage.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
use FindBin ();
use lib "$FindBin::Bin";
BEGIN { use_ok('Test::TestCoverage') };

my @methods = qw(ok_test_coverage
                 test_coverage
                 all_test_coverage_ok
                 reset_test_coverage
                 reset_all_test_coverage
                 test_coverage_except
                 _get_subroutines
                 _get_sub);
                 
can_ok('Test::TestCoverage',@methods);

test_coverage('TestCoverage::MyTestModule');
TestCoverage::MyTestModule::test();
TestCoverage::MyTestModule::methode();
ok_test_coverage();
ok_test_coverage('TestCoverage::MyTestModule');
ok_test_coverage('Test TestCoverage::MyTestModule');
all_test_coverage_ok();


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

