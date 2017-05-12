use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;
use TAP::SimpleOutput 0.009 'counters';

use Moose ();
use Moose::Meta::Attribute;

# Ok, this is weird, but...  Moose::Meta::Attribute fails is_class_ok().
#
# Well, maybe not "weird", but unwelcome certainly.

# TODO: {
#     local $TODO = 'Moose::Meta::Attribute is flagged as non-Moosey';

my $class = 'Moose::Meta::Attribute';

subtest "raw $class" => sub { is_class_ok $class };

    my ($_ok, $_nok, $_skip, $_todo, $_other) = counters();
    test_out $_ok->("$class has a metaclass");
    test_out $_ok->("$class is a Moose class");
    is_class_ok $class;
    test_test $class;

# }

done_testing;
__END__

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
