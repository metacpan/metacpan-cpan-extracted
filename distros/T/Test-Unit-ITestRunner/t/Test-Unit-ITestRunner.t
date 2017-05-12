# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Test-Unit-ITestRunner.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 2;
BEGIN { use_ok('Test::Unit::ITestRunner') };

#########################

ok(Test::Unit::TestRunner->new());
