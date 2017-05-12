use strict;
use warnings;


{
    package TestRole;
    use Moose::Role;
}
{
    package TestClass;
    use Moose;
}
{
    package TestClass::NotMoosey;
}

use Test::Builder::Tester; # tests => 1;
use Test::More;
use Test::Moose::More;

# is_class_ok vs role
test_out 'ok 1 - TestRole has a metaclass';
test_out 'not ok 2 - TestRole is a Moose class';
test_fail(1);
is_class_ok 'TestRole';
test_test 'is_class_ok works correctly';

# is_class_ok vs class
test_out 'ok 1 - TestClass has a metaclass';
test_out 'ok 2 - TestClass is a Moose class';
is_class_ok 'TestClass';
test_test 'is_class_ok works correctly with classes';

# is_class_ok vs plain-old-package
test_out 'not ok 1 - TestClass::NotMoosey has a metaclass';
test_fail(1);
is_class_ok 'TestClass::NotMoosey';
test_test 'is_class_ok works correctly with plain-old-packages';

done_testing;
