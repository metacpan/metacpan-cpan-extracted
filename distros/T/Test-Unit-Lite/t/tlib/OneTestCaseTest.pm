package OneTestCaseTest;

# Test class used in SuiteTest

use Test::Unit::Lite;
use base qw(Test::Unit::TestCase);

sub new {
    shift()->SUPER::new(@_);
}

sub no_test_case {
}

sub test_case {
}

1;
