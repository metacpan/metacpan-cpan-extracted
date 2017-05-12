package OverrideTestCaseTest;
use strict;
use warnings;

# Test class used in SuiteTest

use OneTestCaseTest;
use base qw(OneTestCaseTest);

sub new {
    shift()->SUPER::new(@_);
}

sub test_case {
}

1;
