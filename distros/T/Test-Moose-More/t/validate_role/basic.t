use strict;
use warnings;

{ package TestRole::One;      use Moose::Role;                       }
{ package TestRole::Two;      use Moose::Role;                       }
{ package TestRole::Invalid;  use Moose::Role; with 'TestRole::Two'; }
{ package TestClass::NonMoosey;                                      }

{
    package TestRole;
    use Moose::Role;

    with 'TestRole::One';

    has foo => (is => 'ro');

    has baz => (traits => ['TestRole::Two'], is => 'ro');

    sub method1 { }

    requires 'blargh';

    before before_wrapped => sub { };
    around around_wrapped => sub { };
    after  after_wrapped  => sub { };

    has bar => (

        traits  => ['Array'],
        isa     => 'ArrayRef',
        is      => 'ro',
        lazy    => 1,
        builder => '_build_bar',

        handles => {

            has_bar  => 'count',
            num_bars => 'count',
        }
    );
}

use Test::Builder::Tester; # tests => 1;
use Test::More;
use Test::Moose::More;

use TAP::SimpleOutput 'counters';

validate_role TestRole => (
    -subtest => 'simple -subtest demo/validation',
    methods  => [ qw{ method1 } ],
);

note 'validate w/valid role';
{
    my ($_ok, $_nok) = counters();
    test_out $_ok->('TestRole has a metaclass');
    test_out $_ok->('TestRole is a Moose role');
    test_out $_ok->('TestRole requires method blargh');
    test_out $_ok->("TestRole wraps before method before_wrapped");
    test_out $_ok->("TestRole wraps around method around_wrapped");
    test_out $_ok->("TestRole wraps after method after_wrapped");
    test_out $_ok->('TestRole does TestRole');
    test_out $_ok->('TestRole does not do TestRole::Two');
    test_out $_ok->("TestRole has method $_")
        for qw{ method1 };
    test_out $_ok->('TestRole has an attribute named bar');
    validate_role 'TestRole' => (
        attributes => [ 'bar'                     ],
        does       => [ 'TestRole'                ],
        does_not   => [ 'TestRole::Two'           ],
        # XXX cannot check for accessor methods in a role at the moment
        #methods    => [ qw{ foo method1 has_bar } ],
        methods     => [ qw{ method1 } ],
        required_methods => [ qw{ blargh } ],
        before      => [ 'before_wrapped' ],
        around      => [ 'around_wrapped' ],
        after       => [  'after_wrapped' ],
    );
    test_test 'validate_role works correctly for valid roles';
}

note 'validate w/non-moose package';
{
    my ($_ok, $_nok) = counters();
    test_out $_nok->('TestClass::NonMoosey has a metaclass');
    test_fail 1;
    validate_role 'TestClass::NonMoosey' => (
        does    => [ 'TestRole' ],
        methods => [ qw{ foo method1 has_bar } ],
    );
    test_test 'validate_role works correctly for non-moose classes';
}

note 'validate invalid role';
{
    my ($_ok, $_nok) = counters();

    test_out $_ok->('TestRole::Invalid has a metaclass');
    test_out $_ok->('TestRole::Invalid is a Moose role');
    test_out $_nok->('TestRole::Invalid does TestRole');
    test_fail 6;
    test_out $_nok->('TestRole::Invalid does not do TestRole::Two');
    test_fail 4;
    do { test_out $_nok->("TestRole::Invalid has method $_"); test_fail 3 }
        for qw{ foo method1 has_bar };

    validate_role 'TestRole::Invalid' => (
        does     => [ 'TestRole'                ],
        does_not => [ 'TestRole::Two'           ],
        methods  => [ qw{ foo method1 has_bar } ],
    );
    test_test 'validate_role works correctly for invalid roles';
}

note 'validate w/attribute validation';
{
    my ($_ok, $_nok, $_skip) = counters();
    test_out $_ok->('TestRole has a metaclass');
    test_out $_ok->('TestRole is a Moose role');
    test_out $_ok->('TestRole has an attribute named bar');
    test_out $_ok->('TestRole has an attribute named baz');
    test_out $_skip->(q{Cannot examine attribute metaclass in roles});
    test_out $_ok->('TestRole has an attribute named foo');
    validate_role 'TestRole' => (
        attributes => [ 'bar', baz => { does => [ 'TestRole::Two' ] }, 'foo' ],
    );
    test_test 'validate_role works correctly for attribute meta checking';
}
done_testing;
