use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Test::Mockify
    Test::Mockify::MethodCallCounter
    Test::Mockify::Tools
    Test::Mockify::TypeTests
    Test::Mockify::Matcher
    Test::Mockify::Method
    Test::Mockify::MethodSpy
    Test::Mockify::Parameter
    Test::Mockify::Verify
);

done_testing;

