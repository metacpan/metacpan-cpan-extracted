use strict;
use warnings;

use Test::More tests => 2;
use FindBin ();
use lib "$FindBin::Bin";
BEGIN { use_ok('Test::TestCoverage') };

test_coverage('TestCoverage::MyTestModule');
my @subs = (
    'methode',
);
test_coverage_except('TestCoverage::MyTestModule', @subs);
TestCoverage::MyTestModule::test();
ok_test_coverage('TestCoverage::MyTestModule', 'test coverage ok');
