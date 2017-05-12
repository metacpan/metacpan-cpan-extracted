use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;
use TAP::SimpleOutput 0.009 'counters';

{
    package TestRole;
    use Moose::Role;
    use namespace::autoclean;

    has thinger => (is => 'ro', predicate => 'has_thinger');
}
{
    package TestClass;

    use Moose;
    use namespace::autoclean;

    has foo => (
        traits   => [ 'TestRole' ],
        required => 1,
        is       => 'ro',
        isa      => 'Int',
        builder  => '_build_foo',
        lazy     => 1,
        thinger  => 'foo',
    );
}

subtest 'a standalone run of attribute_options_ok' => sub {
    note 'of necessity, these exclude the "failing" tests';
    attribute_options_ok TestClass => foo => (
        traits   => [ 'TestRole' ],
        isa      => 'Int',
        does     => 'Bar',
        handles  => { },
        reader   => 'foo',
        builder  => '_build_foo',
        default  => undef,
        init_arg => 'foo',
        lazy     => 1,
    );
};

note 'attribute_options_ok validation';
{
    my ($_ok, $_nok, $_skip) = counters();
    test_out $_ok->('TestClass has an attribute named foo');
    test_out $_ok->('foo has a builder');
    test_out $_ok->('foo option builder correct');
    test_out $_ok->('foo does not have a default');
    test_out $_ok->('foo option default correct');
    test_out $_ok->('foo has a reader');
    test_out $_ok->('foo option reader correct');
    test_out $_skip->("cannot test 'isa' options yet");
    test_out $_skip->("cannot test 'does' options yet");
    test_out $_skip->("cannot test 'handles' options yet");
    test_out $_skip->("cannot test 'traits' options yet");
    test_out $_ok->('foo has a init_arg');
    test_out $_ok->('foo option init_arg correct');
    test_out $_ok->('foo is lazy');
    test_out $_nok->('unknown attribute option: binger');
    test_fail 3;
    test_out $_ok->('foo has a thinger');
    test_out $_ok->('foo option thinger correct');
    attribute_options_ok TestClass => foo => (
        traits   => [ 'TestRole' ],
        isa      => 'Int',
        does     => 'Bar',
        handles  => { },
        reader   => 'foo',
        builder  => '_build_foo',
        default  => undef,
        init_arg => 'foo',
        lazy     => 1,
        thinger  => 'foo',
        binger   => 'bar',
    );
    test_test 'attribute_options_ok works as expected';
}

done_testing;
