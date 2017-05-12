use strict;
use warnings;

{
    package TestRole;
    use Moose::Role;

    requires 'foo';
}

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;

my $THING = 'TestRole';

subtest 'plain-old tests' => sub {
    requires_method_ok $THING, 'foo';
    does_not_require_method_ok $THING, 'bar';
};

test_out "ok 1 - $THING requires method foo";
requires_method_ok $THING, 'foo';
test_test 'requires_method_ok works correctly with methods';

# is_role_ok vs plain-old-package
test_out "not ok 1 - $THING requires method bar";
test_fail(1);
requires_method_ok $THING, 'bar';
test_test 'requires_method_ok works correctly with methods not required';

# does not require...
test_out "ok 1 - $THING does not require method bar";
does_not_require_method_ok $THING, 'bar';
test_test 'does_not_require_method_ok works correctly with methods';

test_out "not ok 1 - $THING does not require method foo";
test_fail(1);
does_not_require_method_ok $THING, 'foo';
test_test 'does_not_require_method_ok works correctly with methods required';

done_testing;
