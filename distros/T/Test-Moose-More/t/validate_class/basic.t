use strict;
use warnings;

use Moose::Util 'with_traits';

{ package TestRole;           use Moose::Role;                       }
{ package TestRole::Two;      use Moose::Role;                       }
{ package TestClass::Invalid; use Moose;       with 'TestRole::Two'; }
{ package TestClass::NonMoosey;                                      }

{
    package TestClass;
    use Moose;

    with 'TestRole';

    has foo => (is => 'ro');

    has baz => (traits => ['TestRole::Two'], is => 'ro');

    sub method1 { }

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

use TAP::SimpleOutput 0.009 ':subtest';

note 'validate w/valid class';
{
    my ($_ok, $_nok) = counters();
    test_out $_ok->('TestClass has a metaclass');
    test_out $_ok->('TestClass is a Moose class');
    test_out $_ok->('TestClass isa Moose::Object');
    test_out $_ok->('TestClass is not immutable');
    test_out $_ok->('TestClass is not anonymous');
    test_out $_ok->('TestClass does TestRole');
    test_out $_ok->('TestClass does not do TestRole::Two');
    test_out $_ok->("TestClass has method $_")
        for qw{ foo method1 has_bar };
    test_out $_ok->('TestClass has an attribute named bar');
    validate_class 'TestClass' => (
        anonymous  => 0,
        immutable  => 0,
        isa        => [ 'Moose::Object'           ],
        attributes => [ 'bar'                     ],
        does       => [ 'TestRole'                ],
        does_not   => [ 'TestRole::Two'           ],
        methods    => [ qw{ foo method1 has_bar } ],
    );
    test_test 'validate_class works correctly for valid classes';
}

validate_class 'TestClass' => (
    -subtest   => 'demo/validation of -subtest for validate_class()',
    attributes => [ 'bar' ],
);

subtest 'validate w/valid class -- standalone run' => sub {

    validate_class 'TestClass' => (
        anonymous  => 0,
        immutable  => 0,
        isa        => [ 'Moose::Object'           ],
        attributes => [ 'bar'                     ],
        does       => [ 'TestRole'                ],
        does_not   => [ 'TestRole::Two'           ],
        methods    => [ qw{ foo method1 has_bar } ],
    );
};

note 'simple validation w/anonymous_class';
{

    my $anon = with_traits 'TestClass' => 'TestRole::Two';

    my ($_ok, $_nok) = counters();
    test_out $_ok->("$anon has a metaclass");
    test_out $_ok->("$anon is a Moose class");
    test_out $_ok->("$anon is anonymous");
    test_out $_ok->("$anon does TestRole::Two");
    validate_class $anon => (
        anonymous => 1,
        does => [ qw{ TestRole::Two } ],
    );
    test_test 'simple validation w/anonymous_class';
}

note 'simple is-anonymous validation w/anonymous_class';
{

    my $anon = with_traits 'TestClass' => 'TestRole::Two';

    my ($_ok, $_nok) = counters();
    test_out $_ok->("$anon has a metaclass");
    test_out $_ok->("$anon is a Moose class");
    test_out $_nok->("$anon is not anonymous");
    test_fail 2;
    test_out $_ok->("$anon does TestRole::Two");
    validate_class $anon => (
        anonymous => 0,
        does => [ qw{ TestRole::Two } ],
    );
    test_test 'simple not-anonymous validation w/anonymous_class';
}

note 'validate w/non-moose package';
{
    my ($_ok, $_nok) = counters();
    test_out $_nok->('TestClass::NonMoosey has a metaclass');
    test_fail 1;
    validate_class 'TestClass::NonMoosey' => (
        does    => [ 'TestRole' ],
        methods => [ qw{ foo method1 has_bar } ],
    );
    test_test 'validate_class works correctly for non-moose classes';
}

note 'validate invalid class';
{
    my ($_ok, $_nok) = counters();

    test_out $_ok->('TestClass::Invalid has a metaclass');
    test_out $_ok->('TestClass::Invalid is a Moose class');
    test_out $_nok->('TestClass::Invalid does TestRole');
    test_fail 6;
    test_out $_nok->('TestClass::Invalid does not do TestRole::Two');
    test_fail 4;
    do { test_out $_nok->("TestClass::Invalid has method $_"); test_fail 3 }
        for qw{ foo method1 has_bar };

    validate_class 'TestClass::Invalid' => (
        does     => [ 'TestRole' ],
        does_not => [ 'TestRole::Two'           ],
        methods  => [ qw{ foo method1 has_bar } ],
    );
    test_test 'validate_class works correctly for invalid classes';
}

note 'validate w/attribute validation';
{
    my ($_ok, $_nok, undef, undef, undef, $_any) = counters();
    test_out $_ok->('TestClass has a metaclass');
    test_out $_ok->('TestClass is a Moose class');
    test_out $_ok->('TestClass has an attribute named bar');
    test_out $_ok->('TestClass has an attribute named baz');
    my $name = q{checking TestClass's attribute baz};
    test_out subtest_header $_any => $name
        if subtest_header_needed;
    do {
        my ($_ok, $_nok, $_skip, $_plan, undef, $_any) = counters(1);
        test_out $_ok->(q{TestClass's attribute baz's metaclass has a metaclass});
        test_out $_ok->(q{TestClass's attribute baz's metaclass is a Moose class});
        test_out $_ok->(q{TestClass's attribute baz's metaclass does TestRole::Two});
        test_out $_ok->(q{TestClass's attribute baz has a reader});
        test_out $_ok->(q{TestClass's attribute baz option reader correct});
        test_out $_plan->();
    };
    test_out $_ok->($name);
    test_out $_ok->('TestClass has an attribute named foo');
    validate_class 'TestClass' => (
        attributes => [
            'bar',
            baz => {
                -does => [ 'TestRole::Two' ],
                reader => 'baz',
            },
            'foo',
        ],
    );
    test_test 'validate_class works correctly for attribute meta checking';
}

done_testing;
