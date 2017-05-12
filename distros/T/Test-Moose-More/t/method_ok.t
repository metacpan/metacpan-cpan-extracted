use strict;
use warnings;

{ package TestRole;  use Moose::Role; sub role  {}; has role_att  => (is => 'ro') }
{ package TestRole2; use Moose::Role; with 'TestRole';                            }
{ package TestClass; use Moose; sub foo {}; sub baz {}; has beep => (is => 'ro')  }
{ package TC2;       use Moose; extends 'TestClass'; with 'TestRole'; sub bar {}  }

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;
use TAP::SimpleOutput;

subtest strict => sub {

    # This seems somewhat arbitrary, but it's what Class::MOP::Class considers
    # to be a method of a class or not, rather than what a consumer of such a
    # class would.
    #
    # CMC considers methods or attribute accessor methods defined directly in
    # the class or roles consumed directly to be methods of the class, and
    # methods (including attribute accessors) defined in superclasses
    # (directly, consumed role, attribute, etc) to not be methods defined by
    # the class.
    #
    # More simply put: If and only if a method defined in or consumed by a
    # class is it a method of the class.

    has_method_ok    TestClass => 'foo';
    has_method_ok    TestClass => 'beep';
    has_no_method_ok TestClass => 'bar';

    subtest multiple  => sub {
        has_method_ok    TestClass => 'beep', 'foo';
        has_no_method_ok TestClass => 'boop', 'bar';
    };

    subtest from_role => sub { has_method_ok TC2 => 'role', 'role_att' };

    subtest superclass => sub {
        has_method_ok    TC2 => 'bar';
        has_no_method_ok TC2 => qw{ foo beep };
        has_method_ok TC2    => qw{ role role_att };
    };

};

subtest anywhere => sub {

    # This is more along the lines of what a consumer would consider a class
    # providing: they care about what can be called, not so much where the
    # method came from.

    has_method_from_anywhere_ok    TestClass => qw{ foo beep                   };
    has_no_method_from_anywhere_ok TestClass => qw{ nope                       };
    has_method_from_anywhere_ok    TC2       => qw{ foo beep bar role role_att };
    has_method_from_anywhere_ok    TestRole  => qw{ role                       };
    has_no_method_from_anywhere_ok TestRole  => qw{ role_att                   };
    has_method_from_anywhere_ok    TestRole2 => qw{ role                       };
    has_no_method_from_anywhere_ok TestRole2 => qw{ role_att                   };

    subtest validate_class => sub {
        validate_class TC2 => (anywhere_methods => ['foo']);
    };
};

# FIXME TODO implement the above, below.

## has_method_ok()

test_out 'ok 1 - TestClass has method foo';
has_method_ok 'TestClass', 'foo';
test_test 'has_method_ok works correctly with methods';

test_out 'not ok 1 - TestClass has method bar';
test_fail(1);
has_method_ok 'TestClass', 'bar';
test_test 'has_method_ok works correctly with DNE methods';

# attribute accessor
test_out 'ok 1 - TestClass has method beep';
has_method_ok 'TestClass', 'beep';
test_test 'has_method_ok works correctly with attribute accessor methods';

# role
test_out 'ok 1 - TC2 has method role';
has_method_ok 'TC2', 'role';
test_test 'has_method_ok works correctly with methods from roles';

# superclass
test_out 'not ok 1 - TC2 has method foo';
test_fail(1);
has_method_ok 'TC2', 'foo';
test_test 'has_method_ok works correctly with superclass methods';


## has_no_method_ok()

test_out 'ok 1 - TestClass does not have method bar';
has_no_method_ok 'TestClass', 'bar';
test_test 'has_no_method_ok works correctly with methods';

test_out 'not ok 1 - TestClass does not have method foo';
test_fail(1);
has_no_method_ok 'TestClass', 'foo';
test_test 'has_no_method_ok works correctly with DNE methods';

# attribute accessor
test_out 'not ok 1 - TestClass does not have method beep';
test_fail(1);
has_no_method_ok 'TestClass', 'beep';
test_test 'has_no_method_ok works correctly with attribute accessor methods';

# role
test_out 'not ok 1 - TC2 does not have method role';
test_fail(1);
has_no_method_ok 'TC2', 'role';
test_test 'has_no_method_ok works correctly with methods from roles';

# superclass
test_out 'ok 1 - TC2 does not have method foo';
has_no_method_ok 'TC2', 'foo';
test_test 'has_no_method_ok works correctly with superclass methods';


# multiples
{
    my ($_ok) = counters;
    test_out $_ok->('TestClass has method foo');
    test_out $_ok->('TestClass has method baz');
    has_method_ok TestClass => qw{ foo baz };
    test_test 'has_method_ok multiples OK';
}
{
    my ($_ok) = counters;
    test_out $_ok->('TestClass does not have method foo2');
    test_out $_ok->('TestClass does not have method baz2');
    has_no_method_ok TestClass => qw{ foo2 baz2 };
    test_test 'has_no_method_ok multiples OK';
}

done_testing;
